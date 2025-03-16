#define _GNU_SOURCE
#include <sys/mman.h>

#include "include.h"

static void *m;
static ufixnum sz,mps;

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
    void *v,*v1;

    v=gcl_alloc_initialized ? core_end : (void *)ROUNDUP((void *)&_end,getpagesize());
    v1=(void *)ROUNDUP((ufixnum)v,PAGESIZE);
    massert(!gcl_alloc_initialized || v==v1);

#ifdef UNMAP_OLD_HEAP /*386-gnu*/
    UNMAP_OLD_HEAP
#endif

    if (v!=v1)
      massert((m=mmap(v,
		      v1-v,
		      PROT_READ|PROT_WRITE|PROT_EXEC,
		      MAP_PRIVATE|MAP_ANON|MAP_FIXED,
		      -1,
		      0))!=(void *)-1);

    massert((m=mmap(v1,
		    PAGESIZE,
		    PROT_READ|PROT_WRITE|PROT_EXEC,
		    MAP_PRIVATE|MAP_ANON|MAP_FIXED,
		    -1,
		    0))!=(void *)-1);
    sz=0;
    mps=ROUNDUP(sz+1,PAGESIZE);

  }
  
  return 0;

}
  
void *
msbrk(intptr_t inc) {

  size_t p2=ROUNDUP(sz+1+inc,PAGESIZE);

  if (mps>=p2 || m==mremap(m,mps,p2,0)) {
    if (mps<p2) {
#ifdef HAVE_MADVISE_HUGEPAGE
      massert(!madvise(m,p2,MADV_HUGEPAGE));
#endif
      mps=p2;
    }
    sz+=inc;
    return m+sz-inc;
  } else {
    errno=ENOMEM;
    return (void *)-1;
  }

}
