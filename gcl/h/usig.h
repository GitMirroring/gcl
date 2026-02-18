typedef void (*handler_function_type)(int,long,void *,char *);

EXTER handler_function_type our_signal_handler[32];

   
#define signal_mask(n)  (1 << (n))
   
   
     
   
   
