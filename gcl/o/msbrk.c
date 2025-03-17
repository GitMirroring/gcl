#define _GNU_SOURCE
#include <sys/mman.h>

#include "include.h"

static void *m,*m1;
static ufixnum sz,mps;

int
msbrk_end(void) {

  sz+=(ufixnum)m;
  mps=sz;
  m=m1=NULL;

  return 0;

}

#if !defined(DARWIN) && !defined(__CYGWIN__) && !defined(__MINGW32__) && !defined(__MINGW64__)/*FIXME*/

int
msbrk_init(void) {

  if (!m) {

    extern int gcl_alloc_initialized;
    extern fixnum _end;
    void *v,*v1;

    v=gcl_alloc_initialized ? core_end : (void *)ROUNDUP((void *)&_end,getpagesize());
    v1=(void *)ROUNDUP((ufixnum)v,PAGESIZE);
    massert(!gcl_alloc_initialized || v==v1);

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
    mps=PAGESIZE;

  }
  
  return 0;

}
#if defined(__gnu_hurd___) && defined(__i386__)

void *
mmremap(void *v,ufixnum s1,ufixnum s2,ufixnum flags) {

  static void *h1=(void *)0x20000000,*he=(void *)0x28000000;

  if (m+s2<h1)
    return mremap(v,s1,s2,flags);
  if (m+s1<h1)
    if (mremap(v,s1,(h1-m),flags)!=v)
      return (void *)-1;
  if (mprotect(h1,he-h1,PROT_READ|PROT_WRITE|PROT_EXEC))
    return (void *)-1;
  if (m+s2<he)
    return v;
  if (!m1) {
    m1=mmap(he,s2-(he-m),PROT_READ|PROT_WRITE|PROT_EXEC,MAP_PRIVATE|MAP_ANON|MAP_FIXED,-1,0);
    return m1==(void *)-1 ? m1 : v;
  } else
    return mremap(he,mps-(he-m),s2-(he-m),flags)==he ? v : (void *)-1;
}

#undef mremap
#define mremap mmremap

#endif

void *
msbrk(intptr_t inc) {

  size_t p2=ROUNDUP(sz+inc,PAGESIZE);

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
#endif
