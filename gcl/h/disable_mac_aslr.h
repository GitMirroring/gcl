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
    gcl_abort();
  }
  posix_spawnattr_destroy(&attr);

}
