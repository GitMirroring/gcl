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
		    1,
		    PROT_READ|PROT_WRITE|PROT_EXEC,
		    MAP_PRIVATE|MAP_ANON|MAP_FIXED,
		    -1,
		    0))!=(void *)-1);
    sz=1;

  }
  
  return 0;

}
  
void *
msbrk(intptr_t inc) {

  if (!inc || m==mremap(m,sz,sz+inc,0)) {
    sz+=inc;
    return m+sz-inc;
  } else {
    errno=ENOMEM;
    return (void *)-1;
  }

}
  
