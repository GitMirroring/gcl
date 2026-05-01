#include <stdio.h>
#include <stdlib.h>
#include <spawn.h>
#include <sys/wait.h>
#include <mach-o/dyld.h>

/* These constants might not be in older headers */
#ifndef POSIX_SPAWN_DISABLE_ASLR
#define POSIX_SPAWN_DISABLE_ASLR 0x0100
#endif

/* void maybe_disable_aslr(int argc, char **argv, char **envp)  */{
    // 1. Check if the image has already been loaded with a zero slide
    if (_dyld_get_image_vmaddr_slide(0) != 0) {
    /*     return; // Already running with fixed addresses */
    /* } */

    // 2. We have a non-zero slide, so we must relaunch via posix_spawn
    pid_t pid;
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    
    // Set the flag that mimics LLDB's "disable-aslr" setting
    short flags = POSIX_SPAWN_SETEXEC | POSIX_SPAWN_DISABLE_ASLR;
    posix_spawnattr_setflags(&attr, flags);

    

// 3. Relaunch this same binary (argv[0]) with the same arguments
    // POSIX_SPAWN_SETEXEC makes this act like execve (replaces current process)
    int status = posix_spawn(&pid, argv[0], NULL, &attr, argv, envp);

    if (status != 0) {
        perror("posix_spawn to disable ASLR failed");
        // If this fails, the process continues with ASLR enabled. 
        // This will likely lead to the mmap ENOMEM error later.
    }
    
    posix_spawnattr_destroy(&attr);
    }
}

/* int main(int argc, char **argv, char **envp) { */
/*     maybe_disable_aslr(argc, argv, envp); */
    
/*     // ... rest of your GCL initialization ... */
/* } */
