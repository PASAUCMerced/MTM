CC = gcc
CFLAGS = -g -w -O2 -fPIC
INCLUDES = -I/usr/local/include
LIBS = -lm -lpthread -ldl -lpfm

OBJ = ./obj
SRC = ./src

all:  
	$(CC) $(CFLAGS) $(INCLUDES) -o gups $(SRC)/gups.c $(SRC)/zipf.c $(SRC)/timer.c ../example.c $(LIBS) 

.PHONY: clean_parts clean

test: zipf.c gups.h
	$(CC) $(CFLAGS) test.c -o $@ $< $(LIBS)


clean:
	rm  gups
 