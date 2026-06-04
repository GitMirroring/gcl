/* Copyright (C) 2024 Camm Maguire */
#define NO_PRELINK_UNEXEC_DIVERSION

#ifndef FIRSTWORD
#include "include.h"
#endif

static void
memory_save(char *original_file, char *save_file)
{
#ifdef DO_BEFORE_SAVE
  DO_BEFORE_SAVE ;
#endif    
  
  unexec(save_file,original_file,0,0,0);
}

#ifdef USE_CLEANUP
extern void _cleanup();
#endif

LFD(siLsave)(void) {

  extern char *kcl_self;
  extern void *shared_lib_start;
  extern jmp_buf gmp_jmp;

  check_arg(1);

  memset(FN1,0,sizeof(FN1));
  coerce_to_filename(vs_base[0], FN1);

  close_dlopen_list();
  gcl_cleanup(1);

  /*FIXME clean this up when done*/

  shared_lib_start=NULL;
  memset(gmp_jmp,0,sizeof(gmp_jmp));
  memset(frs_org,0,(frs_limit-frs_org)*sizeof(*frs_org));
  memset(bds_org,0,(bds_limit-bds_org)*sizeof(*bds_org));
  memset(ihs_org,0,(ihs_limit-ihs_org)*sizeof(*ihs_org));
  memset(vs_org,0,(vs_limit-vs_org)*sizeof(*vs_org));
  {
    extern char **__environ;
    extern FILE *rl_instream;
    extern char *rl_line_buffer;
    extern void clear_eval_vec(void);

    __environ=NULL;
    rl_instream=NULL;
    rl_readline_name=NULL;
    rl_line_buffer=NULL;
    rl_completion_entry_function=NULL;
    stdin=NULL;
    stdout=NULL;
    stderr=NULL;
    clear_eval_vec();
    cs_limit=NULL;
    cs_base=NULL;
    cs_org=NULL;
    /* memset(FN1,0,sizeof(FN1)); */
    memset(FN2,0,sizeof(FN2));
    memset(FN3,0,sizeof(FN3));
    memset(FN4,0,sizeof(FN4));
    memset(FN5,0,sizeof(FN5));
    ENVP=NULL;
    ARGV=NULL;
    ARGC=0;
    my_stdin=NULL;
    my_stdout=NULL;
    my_stderr=NULL;
    my_rl_readline_name_ptr=NULL;
    my_rl_completion_entry_function_ptr=NULL;

  }


#ifdef MEMORY_SAVE
  MEMORY_SAVE(kcl_self,FN1);
#else	  
  memory_save(kcl_self, FN1);
#endif	

  /*  no return  */
  exit(0);

}
