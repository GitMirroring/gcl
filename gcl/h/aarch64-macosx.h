/*
    GCL config file for Mac OS X.

    To be used with the following configure switches :
        --enable-debug (optional)
        --enable-machine=powerpc-macosx
        --disable-statsysbfd
        --enable-custreloc

    Aurelien Chanudet <aurelien.chanudet(at)m4x.org>
*/

/* For those who are using ACL2, please remember to enlarge your shell stack (ulimit -s 8192).  */

#include "bsd.h"

#define DARWIN

/* Mac OS X has its own executable file format (Mach-O).  */
#undef HAVE_AOUT
#undef HAVE_ELF

#include <unistd.h> /* to get sbrk defined */


/** (si::save-system "...") a.k.a. unexec implementation  */

/* The implementation of unexec for GCL is based on Andrew Choi's work for Emacs.
   Previous pioneering implementation of unexec for Mac OS X by Steve Nygard.  */
#define UNIXSAVE "unexmacosx.c"

#undef malloc
#define malloc my_malloc

#undef free
#define free my_free

#undef realloc
#define realloc my_realloc

#undef valloc
#define valloc my_valloc

#undef calloc
#define calloc my_calloc


/** Dynamic loading implementation  */

/* The sfasl{bfd,macosx,macho}.c files are included from sfasl.c.  */
#ifdef HAVE_LIBBFD
#define SEPARATE_SFASL_FILE "sfaslbfd.c"
#else
#define SPECIAL_RSYM "rsym_macosx.c"
#define SEPARATE_SFASL_FILE "sfaslmacho.c"
#endif

/* The file has non Mach-O stuff appended.  We need to know where the Mach-O stuff ends.  */
#include <stdio.h>
extern int seek_to_end_ofile (FILE *);
#define SEEK_TO_END_OFILE(fp) seek_to_end_ofile(fp)

/** Stratified garbage collection implementation [ (si::sgc-on t) ]  */

/* Mac OS X has sigaction (this is needed in o/usig.c)  */
#define HAVE_SIGACTION

/* Copied from {Net,Free,Open}BSD.h  */
/* Modified according to Camm's instructions on April 15, 2004.  */
#define HAVE_SIGPROCMASK

/* until the sgc/save problem can be fixed.  20050114 CM*/
/* #define SGC */

#define MPROTECT_ACTION_FLAGS (SA_SIGINFO | SA_RESTART)

#define INSTALL_MPROTECT_HANDLER                        \
do {                                                    \
  static struct sigaction sact;                         \
  sigfillset (&(sact.sa_mask));                         \
  sact.sa_flags = MPROTECT_ACTION_FLAGS;                \
  sact.sa_sigaction = (void (*) ()) memprotect_handler; \
  sigaction (SIGBUS, &sact, 0);                         \
  sigaction (SIGSEGV, &sact, 0);                        \
} while (0);

#define GET_FAULT_ADDR(sig,code,sv,a) ((siginfo_t *)code)->si_addr


/** Misc stuff  */

#define IEEEFLOAT

/* Mac OS X does not have _fileno as in linux.h. Nor does it have _cnt as in bsd.h.
   Let's see what we can do with this declaration found in {Net,Free,Open}BSD.h.  */
#undef LISTEN_FOR_INPUT
#define LISTEN_FOR_INPUT(fp)                                            \
do {int c=0;                                                            \
  if (((FILE *)fp)->_r <=0 && (c=0, ioctl(((FILE *)fp)->_file, FIONREAD, &c), c<=0)) \
        return(FALSE);                                                  \
} while (0)

#define GET_FULL_PATH_SELF(a_)                              \
do {                                                        \
  uint32_t bufsize = 1024;				    \
  static char buf [1024];				    \
  static char fub [1024];				    \
  if (_NSGetExecutablePath (buf, &bufsize) != 0) {	    \
    error ("_NSGetExecutablePath failed");                  \
  }							    \
  if (realpath (buf, fub) == 0) {			    \
    error ("realpath failed");                              \
  }							    \
  (a_) = fub;						    \
 } while (0)

#define C_GC_OFFSET 4
#include <mach-o/arm64/reloc.h>
#define RELOC_H "mach64_aarch64_reloc.h"

#define FPE_TCODE(x_) \
  ({ufixnum _x=(x_),_y=0;			\
   switch(_x) {					\
   case FPE_FLTINV: _y=FE_INVALID;break;	\
   case FPE_FLTDIV: _y=FE_DIVBYZERO;break;	\
   case FPE_FLTOVF: _y=FE_OVERFLOW;break;	\
   case FPE_FLTUND: _y=FE_UNDERFLOW;break;	\
   case FPE_FLTRES: _y=FE_INEXACT;break;	\
   }						\
   _y;						\
  })
#define SF(a_) ((siginfo_t *)a_)
#define FPE_CODE(i_,v_) make_fixnum(FPE_TCODE((fixnum)SF(i_)->si_code))
#define FPE_ADDR(i_,v_) make_fixnum((fixnum)SF(i_)->si_addr)
#define FPE_CTXT(v_) Cnil

#define FPE_INIT Cnil

#include <sys/param.h>
#undef MIN
#undef MAX

#undef sbrk
#define sbrk msbrk
#define INITIALIZE_BRK msbrk_init();

#include <libkern/OSCacheControl.h>
#define CLEAR_CACHE sys_icache_invalidate(memory->cfd.cfd_start,memory->cfd.cfd_size)

#define W_X

#define ADDITIONAL_FEATURES ADD_FEATURE("NO-SIGFPE")
