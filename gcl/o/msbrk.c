#define _GNU_SOURCE
#include <sys/mman.h>

#include "include.h"

static void *m;
static ufixnum sz,mps;

int
msbrk_end(void) {

  sz+=(ufixnum)m;
  mps=sz;
  m=NULL;

  return 0;

}

#if !defined(DARWIN) && !defined(__CYGWIN__) && !defined(__MINGW32__) && !defined(__MINGW64__)/*FIXME*/

static void *
new_amap(void *v,ufixnum s) {
  return mmap(v,s,PROT_READ|PROT_WRITE|PROT_EXEC,MAP_PRIVATE|MAP_ANON|MAP_FIXED,-1,0);
}

#if defined(__gnu_hurd___) && defined(__i386__)
#define H1 (void *)0x20000000
#define HE (void *)0x28000000
#else
#define H1 NULL
#define HE NULL
#endif

static int
old_mprotect(void *v,ufixnum s) {
  void *ve=v+s;
  v=v<H1 ? H1 : v;
  ve=ve>HE ? HE : ve;
  return  v<ve ? mprotect(v,ve-v,PROT_READ|PROT_WRITE|PROT_EXEC) : 0;
}

static void *
new_map(void *v,ufixnum s) {

  if (old_mprotect(v,s))
    return (void *)-1;
  if (v+s<H1)
    return new_amap(v,s);
  if (v<H1 && new_amap(v,H1-v)!=v)
    return (void *)-1;
  if (v+s<HE)
    return v;
  if (v<HE && new_amap(HE,v+s-HE)!=HE)
    return (void *)-1;
  return v<HE ? v : new_amap(v,s);

}

int
msbrk_init(void) {

  if (!m) {

    extern int gcl_alloc_initialized;
    extern fixnum _end;
    void *v;

    v=gcl_alloc_initialized ? core_end : (void *)ROUNDUP((void *)&_end,getpagesize());
    m=(void *)ROUNDUP((ufixnum)v,PAGESIZE);
    massert(!gcl_alloc_initialized || v==m);

    if (v!=m)
      massert(new_map(v,m-v)!=(void *)-1);
    mps=sz=0;

  }
  
  return 0;

}

void *
msbrk(intptr_t inc) {

  size_t p2=ROUNDUP(sz+inc,PAGESIZE);

  if (mps<p2) {
    if (m+mps!=new_map(m+mps,p2-mps))
      return (void *)-1;
#ifdef HAVE_MADVISE_HUGEPAGE
    massert(!madvise(m,p2,MADV_HUGEPAGE));
#endif
    mps=p2;
  }

  sz+=inc;
  return m+sz-inc;

}

#endif
