#include <mach-o/arm64/reloc.h>

#define GOT_RELOC(ri)							\
  ri->r_type==ARM64_RELOC_GOT_LOAD_PAGE21||				\
    ri->r_type==ARM64_RELOC_GOT_LOAD_PAGEOFF12||			\
    ri->r_type==ARM64_RELOC_BRANCH26
#define GOT_RELOC_EXTRA(ri) ri->r_type==ARM64_RELOC_BRANCH26 ? 2*sizeof(int)/sizeof(ul) : 0

  case ARM64_RELOC_ADDEND:
    addend=a;
    break;
  case ARM64_RELOC_BRANCH26:
    addend=0;
    if (labs(((long)(ri->r_pcrel ? a-(ul)q : a))/4)&(~MASK(25))) {
      int tramp[]={0x58ffffd0, /*ldr 19bit pc relative x16*/
		   0xd61f0200};/*br x16*/
      got+=n1[ri->r_symbolnum].n_desc-1;
      *got++=a;
      memcpy(got,tramp,sizeof(tramp));
      a=(ul)got;
    }
    add_vals(q,MASK(26),((long)(ri->r_pcrel ? a-(ul)q : a))/4);
    break;
  case ARM64_RELOC_GOT_LOAD_PAGE21:
    got+=n1[ri->r_symbolnum].n_desc-1;
    *got=a;
    a=(ul)got;
  case ARM64_RELOC_PAGE21:
    a+=addend;
    addend=0;
#define PG(x) ((x) & ~0xfff)
    a=((long)(PG(a)-PG((ul)q))) / 0x1000;
#undef PG
    store_val(q,MASK(2) << 29, (a & 0x3) << 29);
    store_val(q,MASK(19) << 5, (a & 0x1ffffc) << 3);
    break;
  case ARM64_RELOC_GOT_LOAD_PAGEOFF12:
    got+=n1[ri->r_symbolnum].n_desc-1;
    *got=a;
    a=(ul)got;
  case ARM64_RELOC_PAGEOFF12:
    a+=addend;
    addend=0;
    a&=0xfff;
    a>>=(((*q)>>29)&0x1)*                              /*not add/sub*/
          ((((*q)>>26)&0x1) ?                          /*simd*/
	   ((((*q)>>22)&0x3) ?
	    (((*q)>>22)&0x3)+1 : (((*q)>>30)&0x1)) :
	   (((*q)>>30)&0x3));                          /*gp*/
    store_val(q,MASK(12) << 10, a << 10);
    break;
  case ARM64_RELOC_UNSIGNED:
    addend=0;
    if (ri->r_extern || !ri->r_pcrel) {
      add_valu(q,~0UL,ri->r_pcrel ? a-rel : a);
    }
    break;
