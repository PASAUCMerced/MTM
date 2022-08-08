#include "gups.h"


int main() 
{

    long updates = 100000;
    long nelems = 100;
    long* indices = (long* )malloc(updates *sizeof(long));

    calc_indices(indices, updates, nelems);
}