
.SUFFIXES:
.SUFFIXES: .fn .o .c .lsp

-include ../makedefs


PORTDIR	= ../unixport
CAT=cat
APPEND=../xbin/append

OBJS	= gcl_destructuring_bind.o gcl_defpackage.o gcl_make_defpackage.o gcl_loop.o gcl_ansi_io.o $(EXTRA_LOBJS)
SRCS	= gcl_destructuring_bind.lsp gcl_defpackage.lsp gcl_make_defpackage.lsp gcl_loop.lsp gcl_ansi_io.lsp

LISP=$(PORTDIR)/saved_gcl

COMPILE_FILE=$(LISP) $(PORTDIR) $(LISPFLAGS) -system-p -c-file -data-file \
	-h-file -compile

all:	$(OBJS)

$(OBJS): $(SRCS) $(LISP)
	echo "(progn (compiler::cdebug) (mapc (quote compile-file) (mapcar (quote string-downcase) (quote ($(SRCS))))) (compiler::dump-inl-hash \"../cmpnew/gcl_cmpnopt.lsp\"))" | $(LISP)

gprof_objs: $(addprefix ../gprof/,$(OBJS))

../gprof/%.o: %.c #$(DECL)
	$(CC) -I../h -c $(filter-out -fomit-frame-pointer,$(CFLAGS)) $(DEFS) -pg $*.c $(AUX_INFO) -o $@
	${APPEND} ${NULLFILE} $*.data  $@

%.o: %.lsp $(LISP)
	$(COMPILE_FILE) $<

.lsp.fn: ../cmpnew/gcl_collectfn.o
	../xbin/make-fn $*.lsp

all:	$(OBJS)

fns1:	$(FNS)

fns:	../cmpnew/gcl_collectfn.o
	$(MAKE) fns1 -e "FNS=`echo ${OBJS} | sed -e 's:\.o:\.fn:g'`"

clean:
	rm -f *.o core a.out *.fn *.c *.h *.data
allclean:
	rm -f *.h *.data *.c

dummy3 $(NEWCFILES): sys-proclaim.lisp

sys-proclaim.lisp: fns
	echo '(in-package "SYSTEM")' \
	'(load "../cmpnew/gcl_collectfn")'\
	'(compiler::make-all-proclaims "*.fn")' | ../unixport/saved_mod_gcl $(LISPFLAGS)


newc:	
	$(MAKE) $(OBJS) -e "NEWCFILES=`echo $(OBJS) | sed -e 's:\.o:.c:g'`"


