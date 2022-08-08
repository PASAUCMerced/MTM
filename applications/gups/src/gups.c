#define _GNU_SOURCE

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <unistd.h>
#include <sys/time.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <math.h>
#include <string.h>
#include <pthread.h>
#include <sys/mman.h>
#include <errno.h>
#include <inttypes.h>
#include "../../example.h"
#include "timer.h"
#include "gups.h"

#define MAX_THREADS 64

uint64_t hot_start = 0;

#define SEQUENTIAL_ACCESS 0 // 0 = Random, 1 = Sequential
#define WRITE_UPDATE 1      // 0 = Read, 1 = Write

struct gups_args
{
  int tid; // thread id
  // uint64_t *indices; // array of indices to access
  void *field;       // pointer to start of thread's region
  uint64_t iters;    // iterations to perform
  uint64_t size;     // size of region
  uint64_t elt_size; // size of elements
  uint64_t hotsize;  //size of hotset
  uint64_t hotstart; // start of hotset
  float prob;        //probability of sampling hotset
};

static unsigned long updates, nelems;

static uint64_t lfsr_fast(uint64_t lfsr)
{
  lfsr ^= lfsr >> 7;
  lfsr ^= lfsr << 9;
  lfsr ^= lfsr >> 13;
  return lfsr;
}


void __parsec_roi_begin(){}



static void *do_gups(void *arguments)
{

  __parsec_roi_begin();
  struct gups_args *args = (struct gups_args *)arguments;
  char *field = (char *)(args->field);
  uint64_t i, j;
  uint64_t index1, index2;
  uint64_t elt_size = args->elt_size;
  char data[elt_size];
  uint64_t lfsr;
  uint64_t hot_num;
  float p;

  //srand(0);
  srand(args->tid);
  lfsr = rand();

  index1 = 0;
  index2 = 0;
  printf("Thread %d region: %p - %p\thot set: %p - %p\n", args->tid, field, field + (args->size * elt_size), field + args->hotstart, field + args->hotstart + (args->hotsize * elt_size)); 
  for (i = 0; i < args->iters; i++)
  {

    p = ((float) rand())/ RAND_MAX;
    //printf("\nprob p %f %f\n", p, args->prob);
    if (p < args->prob)
    {
#if !SEQUENTIAL_ACCESS
      lfsr = lfsr_fast(lfsr);
      index1 = args->hotstart + (lfsr % args->hotsize);

      // printf("\nhot %d", index1);
      memcpy(data, &field[index1 * elt_size], elt_size);
#if WRITE_UPDATE
      memset(data, data[0] + i, elt_size);
      memcpy(&field[index1 * elt_size], data, elt_size);
#endif
#endif
    }
    else
    {

#if SEQUENTIAL_ACCESS
      index2 = i % args->size;
#else
      lfsr = lfsr_fast(lfsr);
      index2 = lfsr % (args->size);
#endif

      // printf("\nreg %d", index2);
      memcpy(data, &field[index2 * elt_size], elt_size);

#if WRITE_UPDATE
      memset(data, data[0] + i, elt_size);
      memcpy(&field[index2 * elt_size], data, elt_size);
#endif
    }
  }

  __parsec_roi_end();
  return 0;
}

void __parsec_roi_end(){}

int main(int argc, char **argv)
{
  int threads;
  unsigned long expt, hotset_percentage, hotstart_frac;
  float hotset_prob;
  unsigned long size, elt_size;
  uint64_t hotsize, hotstart;
  struct timeval starttime, stoptime;
  double secs, gups;
  int i;
  void *p;
  struct gups_args **ga;
  pthread_t t[MAX_THREADS];

  // pid_t pid = getpid();
  // printf("\npid: %d\n", pid);

  if (argc != 8)
  {
    printf("Usage: %s [threads] [updates per thread] [exponent] [data size (bytes)] [hotset start (\%)] [hotset size (\%)] [hotset ratio (\%)]\n", argv[0]);
    printf("  threads\t\t\tnumber of threads to launch\n");
    printf("  updates per thread\t\tnumber of updates per thread\n");
    printf("  exponent\t\t\tlog size of region\n");
    printf("  data size\t\t\tsize of data in array (in bytes)\n");
    printf("  hotset start\t\t\tstarting from (in percentage)\n");
    printf("  hotset size\t\t\tnumber of elements (in percentage)\n");
    printf("  hotset ratio\t\t\tnumber of elements (in percentage)\n");

    return 0;
  }
  
  gettimeofday(&starttime, NULL);

  threads = atoi(argv[1]);
  assert(threads <= MAX_THREADS);
  
  ga = (struct gups_args **)malloc(threads * sizeof(struct gups_args *));

  updates = atol(argv[2]);
  updates -= updates % 256;
  expt = atoi(argv[3]);
  assert(expt > 8);
  assert(updates > 0 && (updates % 256 == 0));
  size = (unsigned long)(1) << expt;
  size -= (size % 256);
  assert(size > 0 && (size % 256 == 0));  
  elt_size = atoi(argv[4]);
  nelems = (size / threads) / elt_size; // number of elements per thread
  hotstart_frac = atoi(argv[5]);
  hotset_percentage = atoi(argv[6]);
  hotset_prob = atoi(argv[7]);
  hotset_prob /= 100;
  assert(hotstart_frac >= 0 && hotstart_frac <= 100);
  assert(hotset_percentage + hotstart_frac >= 0 && hotset_percentage + hotstart_frac <= 100);
  assert(hotset_percentage >= 0 && hotset_percentage <= 100);
  hotstart = (uint64_t)nelems * hotstart_frac / 100 - 1;
  hotsize = (uint64_t)nelems * hotset_percentage / 100;

  printf("field of 2^%lu (%lu) bytes\n", expt, size);
  printf("%lu updates per thread (%d threads)\n", updates, threads);
  printf("%ld byte element size (%ld elements total)\n", elt_size, size / elt_size);
  printf("Elements per thread: %lu\n", nelems);
  printf("Hotset starts at %x of size %lu\n", hotstart, hotsize);

  p = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);

  gettimeofday(&stoptime, NULL);
  printf("Init took %.4f seconds\n", elapsed(&starttime, &stoptime));
  printf("Region address: %p\t size: %ld\n", p, size);
  printf("Field addr: 0x%x\n\n\n", p);

  printf("Initializing thread data\n");
  for (i = 0; i < threads; ++i)
  {
    ga[i] = (struct gups_args *)malloc(sizeof(struct gups_args));
    ga[i]->field = p + (i * nelems * elt_size);
  }

  //

  gettimeofday(&stoptime, NULL);
  secs = elapsed(&starttime, &stoptime);
  printf("Initialization time: %.4f seconds.\n\n\n", secs);

  gettimeofday(&starttime, NULL);

  //pebs_init();
  // spawn gups worker threads
  for (i = 0; i < threads; i++)
  {
    printf("starting thread [%d]\n", i);
    ga[i]->tid = i;
    ga[i]->iters = updates;
    ga[i]->size = nelems;
    ga[i]->elt_size = elt_size;
    ga[i]->hotstart = hotstart;
    ga[i]->hotsize = hotsize;
    ga[i]->prob = hotset_prob;
    int r = pthread_create(&t[i], NULL, do_gups, (void *)ga[i]);
    assert(r == 0);
  }

  // wait for worker threads
  for (i = 0; i < threads; i++)
  {
    int r = pthread_join(t[i], NULL);
    assert(r == 0);
  }
  gettimeofday(&stoptime, NULL);
  printf("Finished running GUPS\n");
  //pebs_shutdown();

  secs = elapsed(&starttime, &stoptime);
  printf("Elapsed time: %.4f seconds.\n", secs);
  gups = threads * ((double)updates) / (secs * 1.0e9);
  printf("GUPS = %.10f\n", gups);


  for (i = 0; i < threads; i++)
  {
    free(ga[i]);
  }
  free(ga);

  munmap(p, size);
  
  return 0;
}
