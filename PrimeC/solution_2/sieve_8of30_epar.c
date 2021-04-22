// Embarrassingly parallel code prime sieve by Daniel Spangberg
// Run multiple threads independend of each other
// Only count 8 of 30 (2*3*5), there are only 8 numbers not divisible by 2,3,5 within this range
// Discussions and code sharing with @mckoss & @Kinematics
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#include <math.h>
#ifdef _OPENMP
#include <omp.h>
#endif

#ifdef COMPILE_64_BIT
#define TYPE uint64_t
#define MASK 0x3FU
#define SHIFT 6U
#else
#define TYPE uint32_t
#define MASK 0x1FU
#define SHIFT 5U
#endif

// Steps array for finding the next number not divisible by 2,3,5
static unsigned int steps[8]={
6,4,2,4,2,4,6,2
};

struct sieve_state {
  TYPE *a;
  unsigned int maxints;
};

struct sieve_state *create_sieve(int maxints) {
  struct sieve_state *sieve_state=malloc(sizeof *sieve_state);
  // We need to store only odd integers, so only half the number of integers
  sieve_state->a=calloc(maxints/2/sizeof(TYPE)+1,sizeof(TYPE));
  sieve_state->maxints=maxints;
  return sieve_state;
}

void delete_sieve(struct sieve_state *sieve_state) {
  free(sieve_state->a);
  free(sieve_state);
}

void run_sieve(struct sieve_state *sieve_state) {
  unsigned int maxints=sieve_state->maxints;
  TYPE *a=sieve_state->a;
  unsigned int factor, q=(unsigned int)sqrt(maxints)+1U;
  unsigned int step=1U; // From 7 to 11
  unsigned int inc=steps[step]; // Next increment in steps array
  // Only check integers not divisible by 2, 3, or 5
  factor=7U; // We already have 2, 3, and 5
  while (factor<=q) {
    // Search for next prime
    if (a[factor>>(SHIFT+1U)]&((TYPE)1<<((factor>>1U)&MASK))) {
      factor+=inc;
      if (++step==8U) step=0U; // End of steps array, start from the beginning
      inc=steps[step];
      continue;
    }
    // Mask all integer multiples of this prime, but only the bits we will ever read again
    unsigned int istep=step;
    unsigned int ninc=steps[istep];
    for (unsigned int i=factor*factor; i<=maxints; ) {
      a[i>>(SHIFT+1U)]|=(TYPE)1<<((i>>1U)&MASK);
      i+=factor*ninc;
      if (++istep==8U) istep=0U;
      ninc=steps[istep];
    }
    factor+=inc;
    if (++step==8U) step=0U; // End of steps array, start from the beginning
    inc=steps[step];
  }
}

unsigned int count_primes(struct sieve_state *sieve_state) {
  unsigned int maxints=sieve_state->maxints;
  TYPE *a=sieve_state->a;
  unsigned int ncount=3; // We already have 2, 3, and 5 ...
  unsigned int factor=7; // ...
  unsigned int step=1; // From 7 to 11
  unsigned int inc=steps[step]; // Next increment in steps array
  while (factor<=maxints) {
    if (!(a[factor>>(SHIFT+1U)]&((TYPE)1<<((factor>>1U)&MASK))))
      ncount++;
    factor+=inc;
    if (++step==8U) step=0U; // End of steps array, start from the beginning
    inc=steps[step];
  }
  return ncount;
}

int main(int argc, char **argv) {
  int maxints=1000000;
  struct timespec t,t2;
  int passes=0;
  if (argc>1)
    sscanf(argv[1],"%d",&maxints);
  int valid_primes;
  switch(maxints) {
  case 10:
    valid_primes=4;
    break;
  case 100:
    valid_primes=25;
    break;
  case 1000:
    valid_primes=168;
    break;
  case 10000:
    valid_primes=1229;
    break;
  case 100000:
    valid_primes=9592;
    break;
  case 1000000:
    valid_primes=78498;
    break;
  case 10000000:
    valid_primes=664579;
    break;
  case 100000000:
    valid_primes=5761455;
    break;
  case 1000000000:
    valid_primes=50847534;
    break;
  default:
    valid_primes=-1;
  }
  int valid_result=1; // Will be changed by any thread that computes the result
  struct timespec st,et;
  clock_gettime(CLOCK_MONOTONIC,&st);
#ifdef _OPENMP
#pragma omp parallel reduction(+:passes)
#endif
  {
    // The initial time
    clock_gettime(CLOCK_MONOTONIC,&t);
    struct sieve_state *sieve_state;
    while (1) {
      sieve_state=create_sieve(maxints);
      run_sieve(sieve_state);
      passes++;
      clock_gettime(CLOCK_MONOTONIC,&t2);
      if ((t2.tv_sec+t2.tv_nsec*1e-9-t.tv_sec-t.tv_nsec*1e-9)>=5.) {
	// Count the number of primes and validate the result
	int nprimes=count_primes(sieve_state);
	if (nprimes!=valid_primes)
	  valid_result=0;
	break;
      }
      delete_sieve(sieve_state);
    }
  }
  clock_gettime(CLOCK_MONOTONIC,&et);
  double elapsed_time=et.tv_sec+et.tv_nsec*1e-9-st.tv_sec-st.tv_nsec*1e-9;
  //printf("valid=%d ",valid_result);
  printf("danielspaangberg_8of30_epar;%d;%f;%d\n", passes,elapsed_time,omp_get_max_threads());
  return 0;
}
