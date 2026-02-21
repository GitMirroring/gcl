#include "linux.h"

#define ADDITIONAL_FEATURES ADD_FEATURE("SPARC")

#define	SPARC
#define SGC

#define PTR_ALIGN 8

#if SIZEOF_LONG==4
#define RELOC_H "elf32_sparc_reloc.h"
#else
#define RELOC_H "elf64_sparc_reloc.h"
#define SPECIAL_RELOC_H "elf64_sparc_reloc_special.h"
#endif

/* #if SIZEOF_LONG == 8 */
/* #define C_GC_OFFSET 4 */
/* #endif */

#define OUTPUT_MACH bfd_mach_sparc_v9
