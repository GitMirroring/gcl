#if defined(__PPC__)
#define SET_STACK_POINTER "addi %%r1,%0,0\n\t"
#elif defined(__m68k__)
#define SET_STACK_POINTER "movel %0,%%sp\n\t"
#elif defined(__i386__) && !defined(__gnu_hurd__)
#define SET_STACK_POINTER "mov %0,%%esp\n\t"
#elif defined(__arm__)
#define SET_STACK_POINTER "mov %%sp,%0\n\t"
#elif defined(__hppa__)
#define SET_STACK_POINTER "copy %0,%%sp\n\t"
#elif defined(__SH4__)
#define SET_STACK_POINTER "mov %0,%%r15\n\t"
#endif

#ifdef SET_STACK_POINTER
{
  void *p,*p1,*b,*s,*m=(void *)-1-(1UL<<30)+1;/*FIXME configure?*/
  int a,f=MAP_FIXED|MAP_PRIVATE|MAP_ANON|MAP_STACK;

  p=alloca(1);
  p1=alloca(1);
  b=m-(p1<p ? getpagesize() : (1UL<<23));/*FIXME configure?*/
  a=p1<p ? p-p1 : p1-p;
  a<<=2;
  s=p1<p ? m-a : b+a;
  if (p1<p) f|=MAP_GROWSDOWN;

  if (p > m || p < b) {
    if (mmap(b,getpagesize(),PROT_READ|PROT_WRITE|PROT_EXEC,f,-1,0)!=(void *)-1) {
      asm volatile (SET_STACK_POINTER::"r" (s):"memory");
      if (p1>p)
	mmap(m,getpagesize(),PROT_NONE,f,-1,0);/*guard page*/
    }
  }
}
#endif
