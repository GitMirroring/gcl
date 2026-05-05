#include <mach-o/arm64/reloc.h>

#define GOT_RELOC(ri) ri->r_type==ARM64_RELOC_GOT_LOAD_PAGE21||ri->r_type==ARM64_RELOC_GOT_LOAD_PAGEOFF12

  case ARM64_RELOC_BRANCH26:
    add_vals(q,MASK(26),((long)(ri->r_pcrel ? a-(ul)q : a))/4);
    break;
  case ARM64_RELOC_GOT_LOAD_PAGE21:
    got+=n1[ri->r_symbolnum].n_desc-1;
    *got=a;
    a=(ul)got;
  case ARM64_RELOC_PAGE21:
#define PG(x) ((x) & ~0xfff)
    a=((long)(PG(a)-PG((ul)q))) / 0x1000;
#undef PG
    massert(!(((*q)>>29)&0x3));
    massert(!(((*q)>>5)&0x8ffff));
    store_val(q,MASK(2) << 29, (a & 0x3) << 29);
    store_val(q,MASK(19) << 5, (a & 0x1ffffc) << 3);
    break;
  case ARM64_RELOC_GOT_LOAD_PAGEOFF12:
    got+=n1[ri->r_symbolnum].n_desc-1;
    *got=a;
    a=(ul)got;
  case ARM64_RELOC_PAGEOFF12:
    a&=0xfff;
    if (((*q)>>29)&0x1)
      a>>=(((*q)>>30)&0x3);
    massert(!(((*q)>>10)&0xfff));
    store_val(q,MASK(12) << 10, a << 10);
    break;
  case ARM64_RELOC_UNSIGNED:
    if (ri->r_extern || !ri->r_pcrel) {
      massert(!*q);
      store_val(q,~0UL,ri->r_pcrel ? a-rel : a);
    }
    break;
