#include "linux.h"

#define SGC

#define RELOC_H "elf64_loongarch64_reloc.h"
#define SPECIAL_RELOC_H "elf64_loongarch64_reloc_special.h"
/* #define MAX_CODE_ADDRESS (1L<<31)/\*large memory model broken gcc 4.8*\/ */

#define NEED_STACK_CHK_GUARD

#define OUTPUT_MACH bfd_mach_loongarch64
