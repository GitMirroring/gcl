#define _GNU_SOURCE
#include <sys/mman.h>

#include "include.h"

static void *m;
static ufixnum sz;

int
msbrk_end(void) {

  sz+=(ufixnum)m;
  m=NULL;

  return 0;

}

int
msbrk_init(void) {

  if (!m) {

    extern int gcl_alloc_initialized;
    extern fixnum _end;

    massert((m=mmap(gcl_alloc_initialized ? core_end : (void *)ROUNDUP((void *)&_end,PAGESIZE),
		    PAGESIZE,
		    PROT_READ|PROT_WRITE|PROT_EXEC,
		    MAP_PRIVATE|MAP_ANON|MAP_FIXED,
		    -1,
		    0))!=(void *)-1);
    sz=0;
  }
  
  return 0;

}
  
void *
msbrk(intptr_t inc) {

  size_t p1=ROUNDUP(sz+1,PAGESIZE),p2=ROUNDUP(sz+1+inc,PAGESIZE);

  if (p1==p2 || m==mremap(m,p1,p2,0)) {
    sz+=inc;
    return m+sz-inc;
  } else {
    errno=ENOMEM;
    return (void *)-1;
  }

}
  
