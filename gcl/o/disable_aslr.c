#include "include.h"

#ifdef DISABLE_ASLR

#if defined(__APPLE__)

#include <stdio.h>
#include <stdlib.h>
#include <spawn.h>
#include <sys/wait.h>
#include <mach-o/dyld.h>

#ifndef POSIX_SPAWN_DISABLE_ASLR
#define POSIX_SPAWN_DISABLE_ASLR 0x0100
#endif

void
disable_aslr(int argc, char **argv, char **envp) {

  pid_t pid;
  posix_spawnattr_t attr;

  if (!_dyld_get_image_vmaddr_slide(0)) {
    return;
  }

  posix_spawnattr_init(&attr);
  posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETEXEC | POSIX_SPAWN_DISABLE_ASLR);
  if (posix_spawn(&pid, argv[0], NULL, &attr, argv, envp)) {
    perror("posix_spawn to disable ASLR failed");
    do_gcl_abort();
  }
  posix_spawnattr_destroy(&attr);

}

#else

#include <unistd.h>
#include <string.h>
#include <errno.h>


static inline void
reexec(int argc, char **argv, char **envp) {

  int i,j,k;
  char **n,**a;
  void *v;

  for (i=j=0;argv[i];i++)
    j+=strlen(argv[i])+1;
  for (k=0;envp[k];k++)
    j+=strlen(envp[k])+1;
  j+=(i+k+3)*sizeof(char *);

  msbrk_init();
  massert((v=sbrk(j))!=(void *)-1);

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

  gcl_cleanup(0);
  massert(execve(*a,a,n)!=-1);

}

#if defined(__linux__)

#include <sys/personality.h>
#include <unistd.h>

void
disable_aslr(int argc, char **argv, char **envp) {

  long pers;
  long flag = ADDR_NO_RANDOMIZE|(sizeof(flag)==4 ? ADDR_LIMIT_3GB : 0);

  massert((pers=personality(-1))!=-1);

  /*READ_IMPLIES_EXEC is for selinux, but selinux will reset it in the child*/
  massert((pers=personality(READ_IMPLIES_EXEC|pers))!=-1);

  if ((pers & flag)!=flag && !getenv("GCL_UNRANDOMIZE")) {

    massert(personality(pers | flag)!=-1);
    massert((personality(-1)&flag)==flag);

    reexec(argc,argv,envp);

  }

}

#elif defined(__FreeBSD_kernel__)

#include <sys/procctl.h>

void
disable_aslr(int argc, char **argv, char **envp) {

  const int cctl=PROC_ASLR_FORCE_DISABLE;
  int stat,ctl=cctl;

  massert(procctl(P_PID, 0, PROC_ASLR_STATUS, &stat) != -1);

  if ((stat&cctl)!=cctl && !getenv("GCL_UNRANDOMIZE")) {

    massert(procctl(P_PID, 0, PROC_ASLR_CTL, &ctl) != -1);
    massert(procctl(P_PID, 0, PROC_ASLR_STATUS, &stat) != -1);
    massert((stat&cctl)==cctl);

    reexec(argc,argv,envp);

  }

}

#else  /*Unneeded on Hurd, cygwin/mingw via coff header flag*/

void
disable_aslr(int argc, char **argv, char **envp) {
  return;
}

#endif

#endif

#endif
