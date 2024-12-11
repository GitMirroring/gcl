#include <sys/personality.h>
#include <sys/mman.h>
#include <syscall.h>
#include <unistd.h>
#include <string.h>
#include <alloca.h>
#include <errno.h>

{
  errno=0;

  {

    /*READ_IMPLIES_EXEC is for selinux, but selinux will reset it in the child*/
    long pers = personality(READ_IMPLIES_EXEC|personality(0xffffffffUL));
    long flag = ADDR_NO_RANDOMIZE;

    if (sizeof(long)==4) flag|=ADDR_LIMIT_3GB/* |ADDR_COMPAT_LAYOUT */;

    if (pers==-1) {printf("personality failure %d\n",errno);exit(-1);}
    if ((pers & flag)!=flag && !getenv("GCL_UNRANDOMIZE")) {
      errno=0;
      if (personality(pers | flag) != -1 && (personality(0xffffffffUL) & flag)==flag) {
	int i,j,k;
	char **n,**a;
	void *v;
	for (i=j=0;argv[i];i++)
	  j+=strlen(argv[i])+1;
	for (k=0;envp[k];k++)
	  j+=strlen(envp[k])+1;
	j+=(i+k+3)*sizeof(char *);
	if ((v=sbrk(j))==(void *)-1) {
	  printf("Cannot brk environment space\n");
	  exit(-1);
	}
	a=v;
	v=a+i+1;
	n=v;
	v=n+k+2;
	for (i=0;argv[i];i++) {
	  a[i]=v;
	  strcpy(v,argv[i]);
	  v+=strlen(v)+1;
	}
	a[i]=0;
	for (k=0;envp[k];k++) {
	  n[k]=v;
	  strcpy(v,envp[k]);
	  v+=strlen(v)+1;
	}
	n[k]="GCL_UNRANDOMIZE=t";
	n[k+1]=0;
	errno=0;
#ifdef HAVE_GCL_CLEANUP
	gcl_cleanup(0);
#endif
	execve(*a,a,n);
	printf("execve failure %d\n",errno);
	exit(-1);
      } else {
	printf("personality change failure %d\n",errno);
	exit(-1);
      }
    }
#if defined(CSTACKMAX)
#if CSTACK_DIRECTION < 0
#define CSTACK_OFFSET (1L<<PAGEWIDTH)
#define MAP_GROWSDOWN_FLAG MAP_GROWSDOWN
#define CSTACK_SET CSTACKMAX-4*CSTACK_ALIGNMENT
#else
#define CSTACK_OFFSET (1L<<23)/*FIXME configurable*/
#define MAP_GROWSDOWN_FLAG 0
#define CSTACK_SET CSTACKMAX-CSTACK_OFFSET+4*CSTACK_ALIGNMENT
#endif
    if ((void *)&argc > (void *)CSTACKMAX) {
      if (mmap((void *)CSTACKMAX-CSTACK_OFFSET,(1L << PAGEWIDTH),
	       PROT_READ|PROT_WRITE|PROT_EXEC,MAP_FIXED|MAP_PRIVATE|MAP_ANON|MAP_STACK|MAP_GROWSDOWN_FLAG,-1,0)==(void *)-1) {
	  printf("cannot mmap new stack %d\n",errno);
	  exit(-1);
	}
#ifdef SET_STACK_POINTER
      {void *p=(void *)CSTACK_SET;asm volatile (SET_STACK_POINTER::"r" (p):"memory");}
#else
#error SET_STACK_POINTER undefined
#endif
    }
#endif
  }
}
