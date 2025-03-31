AM_CPPFLAGS=$(BASE_CPPFLAGS) -I $(srcdir)/h -I$(srcdir)/gcl-tk 
AM_CFLAGS=$(BASE_CFLAGS)
AM_LDFLAGS=$(BASE_LDFLAGS)
AUTOMAKE_OPTIONS=subdir-objects info-in-builddir


noinst_PROGRAMS=bin/dpp o/grab_defs
#bin_SCRIPTS=gcl27

my_libdir=$(libdir)/$(PACKAGE)-$(PACKAGE_VERSION)
my_unixportdir=$(my_libdir)/unixport

my_unixport_PROGRAMS=unixport/saved_gcl unixport/saved_ansi_gcl
unixport_saved_gcl_SOURCES= 
unixport/saved_gcl$(EXEEXT):
unixport_saved_ansi_gcl_SOURCES= 
unixport/saved_ansi_gcl$(EXEEXT):

my_unixport_LIBRARIES=lib/libbase_gcl.a lib/libgclp.a lib/libgprof.a
my_unixport_LIBRARIES+=unixport/libgcl.a unixport/libansi_gcl.a
lib_libgclp_a_SOURCES=o/bcmp.c o/bcopy.c o/bzero.c o/user_init.c o/user_match.c
lib_libbase_gcl_a_SOURCES=$(C_SRC)

if AMM_GPROF
lib_libgprof_a_SOURCES=o/gprof.c
lib_libgprof_a_CFLAGS=$(AM_CFLAGS) -fno-omit-frame-pointer -pg
my_unixport_PROGRAMS+=unixport/saved_gcl_gprof unixport/saved_ansi_gcl_gprof
unixport_saved_gcl_gprof_SOURCES= 
unixport/saved_gcl_gprof$(EXEEXT):
unixport_saved_ansi_gcl_gprof_SOURCES= 
unixport/saved_ansi_gcl_gprof$(EXEEXT):
my_unixport_LIBRARIES += lib/libbase_gcl_gprof.a unixport/libgcl_gprof.a unixport/libansi_gcl_gprof.a
lib_libbase_gcl_gprof_a_SOURCES=$(C_SRC) o/gprof.c
lib_libbase_gcl_gprof_a_CFLAGS=$(AM_CFLAGS) -fno-omit-frame-pointer -pg
lib_libbase_gcl_gprof_a_CPPFLAGS=$(AM_CPPFLAGS) -DGCL_GPROF
else
lib_libgprof_a_SOURCES=o/foo.c
endif


##include makefile
C_SRC=   o/typespec.c o/alloc.c o/gbc.c o/bitop.c o/main.c o/eval.c o/macros.c o/lex.c o/bds.c o/frame.c\
	 o/predicate.c o/reference.c o/assignment.c o/bind.c o/let.c o/conditional.c o/block.c o/iteration.c\
	 o/mapfun.c\
	 o/prog.c o/multival.c o/catch.c o/cfun.c o/cmpaux.c o/big.c o/number.c o/num_pred.c o/num_comp.c\
	 o/num_arith.c o/num_sfun.c o/num_co.c o/num_log.c o/num_rand.c o/earith.c\
	 o/array.c o/regexpr.c o/structure.c o/toplevel.c o/backq.c o/format.c\
	 o/unixfsys.c o/unixfasl.c o/error.c o/unixtime.c o/unixsys.c o/unixsave.c o/funlink.c  o/fat_string.c\
	 o/run_process.c o/nfunlink.c o/usig.c o/usig2.c o/utils.c o/makefun.c o/sockets.c o/gmp_wrappers.c\
	 o/clxsocket.c o/nsocket.c o/new_init.c o/prelink.c o/sfasl.c o/msbrk.c o/character.c \
	 o/hash.c o/pathname.c o/sequence.c o/file.c o/list.c o/print.c o/string.c\
	 o/gcl_readline.c o/package.c o/read.c o/symbol.c

%.c: %.d | bin/dpp
	bin/dpp $< $@



unixport/raw_%_gprof: lib/libbase_gcl_gprof.a unixport/lib%_gprof.a lib/libgclp.a
	$(CC) $(AM_LDFLAGS) -rdynamic -Wl,-z,relro $(LDFLAGS) -o $@ $^ $(LIBS)

unixport/raw_%: lib/libbase_gcl.a lib/libgprof.a unixport/lib%.a lib/libgclp.a
	$(CC) $(AM_LDFLAGS) -rdynamic -Wl,-z,relro $(LDFLAGS) -o $@ $^ $(LIBS)

unixport/saved_%: | unixport/raw_% unixport/gcl_cmpnopt_%.lsp h/cmpinclude.h \
		    unixport/libboot.so unixport/init_raw.lsp
	ar x unixport/lib$*.a $$(ar t unixport/lib$*.a |grep ^gcl_)
	ln -snf gcl_cmpnopt_$*.lsp unixport/gcl_cmpnopt.lsp
	GCL_LSPSYSDIR=$(srcdir)/unixport/ \
		$(word 1,$|) $$(pwd)/$(@D)/ -libdir $$(pwd)/ \
		    < <(cat $(word 5,$|) <(echo "(system:save-system \"$@\")"))

unixport/gcl_cmpnopt_%.lsp: unixport/lib%.a | unixport/%
	echo "(mapc (quote load) (directory \"$*/*.hsh\"))" \
	     "(compiler::dump-inl-hash \"$@\")" | $|

MY_DIRS=pre_gcl gcl0 gcl1 gcl2 gcl3 gcl mod_gcl0 mod_gcl pcl_gcl ansi_gcl gcl_gprof ansi_gcl_gprof
MY_DIRS+=g/demos g a c
$(MY_DIRS): % :
	[ -d $@ ] || mkdir -p $@

unixport/pre_gcl: | pre_gcl
	ln -s /bin/true $@

unixport/gcl0: | unixport/saved_pre_gcl
unixport/gcl1: | unixport/saved_gcl0
unixport/gcl2: | unixport/saved_gcl1
unixport/gcl3: | unixport/saved_gcl2
unixport/gcl:  | unixport/saved_gcl3
$(addprefix unixport/,gcl0 gcl1 gcl2 gcl3 gcl): unixport/% : unixport/cinit.lisp | %
	$(word 2,$|) < <(cat $< <(echo "(system:save-system \"$@\")"))

unixport/sys_%.o: unixport/sys_init.c h/new_decl.h
	i=$$(echo $* | sed 's,[0-9],,g' | sed 's,_gprof,,g'); \
	   $(CC) $(AM_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) -D $$i -D FLAVOR="$$i" -c $< -o $@

L_STUBS=s sf c listlib predlib deftype typeof subtypep bit type typep typecase arraylib \
        seq seqlib bnum fle dl rm nr lr sym hash sharp \
	cmptype cmpeval cmpvar cmpwt cmpif \
	cmplet cmptag cmpinline cmpenv cmplam cmptop cmpbind cmpblock cmpcall cmpcatch \
	cmpflet cmpfun cmplabel cmploc cmpmap cmpmulti cmpspecial cmputil cmpvs cmpmain \
	callhash assert defmacro defstruct \
	describe evalmacros sc logical_pathname_translations make_pathname parse_namestring \
	merge_pathnames pathname_match_p namestring wild_pathname_p translate_pathname \
	truename directory rename_file restart iolib mislib module numlib packlib \
	setf top trace sloop debug info serror mnum fpe 
L_OBJS=$(addprefix gcl_,$(addsuffix .o,$(L_STUBS)))
L_FOBJS=$(addprefix gcl/,$(L_OBJS))

gcl0/%.o: lsp/%.lsp | unixport/gcl0
	$| -eval "(mapc 'load (directory \"$(@D)/*.done\"))" -compile $< -o $@
	[ "$*" = "gcl_c" ] || [ "$*" = "gcl_listlib" ] || \
		ln -snf $(@F) $$(echo $@ |sed 's,\.o,\.done,g')

gcl0/%.o: cmpnew/%.lsp | unixport/gcl0
	$| -eval "(mapc 'load (directory \"$(@D)/*.done\"))" -compile $< -o $@
	ln -snf $(@F) $$(echo $@ |sed 's,\.o,\.done,g')

.POSIX: # parallel job ordering
unixport/libgcl0.a: $(addprefix gcl0/,$(filter-out gcl_c.o gcl_listlib.o,$(L_OBJS)))
unixport/libgcl0.a: $(addprefix gcl0/,$(filter gcl_c.o gcl_listlib.o,$(L_OBJS)))
$(addprefix unixport/lib,$(addsuffix .a,gcl1 gcl2 gcl3)): unixport/lib%.a: $(addprefix %/,$(L_OBJS))

gcl1/%.o: lsp/%.lsp  | unixport/gcl1
	$| -eval "(mapc 'load (directory \"$(@D)/*.done\"))" \
	   -eval "(setq compiler::*dump-inl-hash* t)" \
	   -compile $< -o $@
	ln -snf $(@F) $$(echo $@ |sed 's,\.o,\.done,g')

gcl1/%.o: cmpnew/%.lsp  | unixport/gcl1
	$| -eval "(mapc 'load (directory \"$(@D)/*.done\"))" \
	   -eval "(setq compiler::*dump-inl-hash* t)" \
	   -compile $< -o $@
	ln -snf $(@F) $$(echo $@ |sed 's,\.o,\.done,g')

gcl2/%.o: lsp/%.lsp  | unixport/gcl2
	$| -eval "(setq compiler::*dump-inl-hash* t)" -compile $< -o $@

gcl2/%.o: cmpnew/%.lsp | unixport/gcl2
	$| -eval "(setq compiler::*dump-inl-hash* t)" -compile $< -o $@

gcl3/%.o: lsp/%.lsp  | unixport/gcl3
	$| -eval "(setq compiler::*dump-inl-hash* t)" -compile $< -o $@

gcl3/%.o: cmpnew/%.lsp | unixport/gcl3
	$| -eval "(setq compiler::*dump-inl-hash* t)" -compile $< -o $@


gcl/%.o: gcl3/%.o | gcl
	cp $(patsubst %.o,%.*,$<) $(@D)

unixport/libgcl.a:  $(L_FOBJS) unixport/sys_gcl.o | unixport/gcl xbin/ar_merge
	$(word 1,$|) -batch \
		-eval "(let ((si::*do-recomp-output-dir* \"$(<D)\")) (si::do-recomp t))" \
		-eval "(compiler::dump-inl-hash \"$(<D)/all.hsh\")"
	$(word 2,$!) crus $@ $^

if AMM_XGCL

X_STUBS=Xlib Xutil X XAtom defentry_events Xstruct XStruct_l_3 general keysymdef X10 Xinit dwtrans tohtml index
X_OBJS=$(addprefix gcl_,$(addsuffix .o,$(X_STUBS)))
X_LIB=lib/libxgcl.a

noinst_LIBRARIES=$(X_LIB)
lib_libxgcl_a_SOURCES=xgcl-2/Events.c xgcl-2/general-c.c xgcl-2/XStruct-2.c xgcl-2/XStruct-4.c xgcl-2/Xutil-2.c

if AMM_GPROF

X_GLIB=lib/libxgcl_gprof.a
noinst_LIBRARIES+=$(X_GLIB)
lib_libxgcl_gprof_a_SOURCES=xgcl-2/Events.c xgcl-2/general-c.c xgcl-2/XStruct-2.c xgcl-2/XStruct-4.c xgcl-2/Xutil-2.c
lib_libxgcl_gprof_a_CFLAGS=$(AM_CFLAGS) -fno-omit-frame-pointer -pg

endif

endif

unixport/mod_gcl0: xgcl-2/sysdef.lisp | unixport/saved_gcl mod_gcl0
	rm -f in
	[ "$(X_OBJS)" = "" ] || echo "(load \"$<\")" >in
	echo "(compiler::cdebug)(si::save-system \"$@\")" >>in
	$(word 1,$|) <in

mod_gcl0/%.o: mod/%.lsp | unixport/mod_gcl0
	$| -eval "(setq compiler::*dump-inl-hash* t)" \
	   -compile $< -o $@

mod_gcl0/%.o: xgcl-2/%.lsp  | unixport/mod_gcl0
	$| -eval "(setq compiler::*dump-inl-hash* t)" \
	   -compile $< -o $@

unixport/mod_gcl: unixport/saved_mod_gcl0 | mod_gcl
	ln -snf $(<F) $@

mod_gcl/%.o: mod_gcl0/%.o | unixport/mod_gcl
	cp $(patsubst %.o,%.*,$<) $(@D)


MOD_STUBS=ansi_io defpackage destructuring_bind loop make_defpackage
MOD_OBJS=$(addprefix gcl_,$(addsuffix .o,$(MOD_STUBS))) $(X_OBJS)
MOD_FOBJS=$(addprefix mod_gcl/,$(MOD_OBJS)) $(L_FOBJS)
unixport/libmod_gcl0.a: unixport/lib%.a: $(addprefix %/,$(MOD_OBJS)) $(L_FOBJS) $(X_LIB)
unixport/libmod_gcl.a:  $(MOD_FOBJS) $(X_LIB) unixport/sys_mod_gcl.o | unixport/mod_gcl xbin/ar_merge
	$(word 1,$|) -batch \
	   -eval "(let ((si::*do-recomp-output-dir* \"$(<D)\")) (si::do-recomp t))" \
           -eval "(compiler::dump-inl-hash \"$(<D)/all.hsh\")"
	$(word 2,$|) crus $@ $^

PCL_STUBS=boot braid cache combin compat cpl ctypes defclass defcombin defs dfun dlisp2\
	  dlisp env fast_init fin fixup fngen fsc generic_functions impl_low init iterate\
	  low macros methods pkg precom1 precom2 slots_boot slots std_class vector walk
PCL_OBJS=$(addprefix gcl_pcl_,$(addsuffix .o,$(PCL_STUBS)))
PCL_FOBJS=$(addprefix pcl_gcl/,$(PCL_OBJS)) $(MOD_FOBJS) $(L_FOBJS)

unixport/pcl_gcl: unixport/saved_mod_gcl pcl/defsys.lisp clcs/package.lisp \
		  clcs/myload1.lisp cmpnew/gcl_collectfn.lsp | pcl_gcl
	echo  "(load \"$(word 3,$^)\")" \
	      "(load \"$(word 4,$^)\")" \
	      "(load \"$(word 5,$^)\")" \
	      "(let ((*features* (remove :kcl *features*))) (load \"$(word 2,$^)\"))" \
	      "(compiler::cdebug)" \
	      "(setq compiler::*assert-ftype-proclamations* t)" \
	      "(setq pcl::*pcl-directory* (cons \"$$(dirname $(word 2,$^))/\" \"$(@F)/\"))" \
	      "(print pcl::*pcl-directory*)" \
	      "(setq pcl::*default-pathname-extensions* (cons \"lisp\" \"o\"))" \
	      "(setq pcl::*pathname-extensions* (cons \"lisp\" \"o\"))" \
	      "(si::save-system \"$@\")" | $<

%/c1: | unixport/%
	echo "(pcl::compile-pcl)" | $|
	touch $@

%/sys-package.lisp: %/c1 | unixport/%
	echo "(pcl::load-pcl)" \
	     "(compiler::get-packages-ansi \
	         (quote (:walker :iterate :pcl :slot-accessor-name)) \
	         \"$@\")" | $|

%/sys-proclaim.lisp: %/c1 | unixport/%
	echo "(pcl::load-pcl)" \
	     "(si::do-recomp2 \
		\"$@\" \
		(mapcar (quote namestring) \
		  (directory \
		     (merge-pathnames \
			\"*.*p\" \
			(make-pathname \
			  :directory (pathname-directory \
				        (si::file (quote pcl::renew-sys-files))))))))" | $|
%/p1.lisp: | unixport/%
	echo "(in-package :si)" \
	     "(export (quote %structure-name))" \
	     "(export (quote %compiled-function-name))" \
	     "(export (quote %set-compiled-function-name))" \
	     "(in-package :pcl)" >$@

%/all.hs1 : %/sys-package.lisp %/p1.lisp %/sys-proclaim.lisp | unixport/%
	rm -rf $*/*.o
	echo "(load \"$(word 1,$^)\")" \
	     "(load \"$(word 2,$^)\")" \
	     "(load \"$(word 3,$^)\")" \
	     "(pcl::compile-pcl)" \
	     "(compiler::dump-inl-hash \"$@\")" | $|

%/all.hsh: %/p1.lisp %/all.hs1
	cat $^ > $@

$(addprefix pcl_gcl/,$(PCL_OBJS)): pcl_gcl/all.hsh
	touch $@

unixport/libpcl_gcl.a: $(PCL_FOBJS) $(X_LIB) unixport/sys_pcl_gcl.o | unixport/pcl_gcl xbin/ar_merge
	echo "(pcl::load-pcl)(si::all-conflicts)" | $(word 1,$|)
	$(word 2,$|) crus $@ $^

CLCS_STUBS=condition_definitions conditions precom
CLCS_OBJS=$(addprefix gcl_clcs_,$(addsuffix .o,$(CLCS_STUBS)))
ANSI_FOBJS=$(addprefix ansi_gcl/,$(CLCS_OBJS)) $(PCL_FOBJS)

unixport/ansi_gcl: clcs/package.lisp clcs/gcl_clcs_precom.lisp \
		   clcs/gcl_clcs_conditions.lisp clcs/gcl_clcs_condition_definitions.lisp \
		   | unixport/saved_pcl_gcl ansi_gcl
	echo "(load \"$(word 1,$^)\")" \
             "(load \"$(word 2,$^)\")" \
             "(load \"$(word 3,$^)\")" \
             "(load \"$(word 4,$^)\")" \
             "(compiler::cdebug)" \
             "(si::save-system \"$@\")" | $(word 1,$|)

ansi_gcl/%.o: clcs/%.lisp | unixport/ansi_gcl
	$| -eval "(setq compiler::*dump-inl-hash* t)" -compile $< -o $@

unixport/libansi_gcl.a: $(ANSI_FOBJS) $(X_LIB)





unixport/gcl_gprof: unixport/saved_gcl | gcl_gprof
	ln -snf $(<F) $@

gcl_gprof/all.hsh: unixport/gcl_cmpnopt_gcl.lsp | unixport/gcl_gprof
	cp $< $@
gcl_gprof/%.o: gcl/%.o | gcl_gprof/all.hsh
	$(CC) $(AM_CPPFLAGS) -I $(<D) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) \
	      -fno-omit-frame-pointer -pg -c $(<D)/$*.c -o $@
	cat $(<D)/$*.data >>$@

unixport/libgcl_gprof.a: $(addprefix gcl_gprof/,$(L_OBJS)) $(X_GLIB)


unixport/ansi_gcl_gprof: unixport/saved_ansi_gcl | ansi_gcl_gprof
	ln -snf $(<F) $@

ansi_gcl_gprof/all.hsh: unixport/gcl_cmpnopt_ansi_gcl.lsp  | unixport/ansi_gcl_gprof
	cp $< $@
ansi_gcl_gprof/%.o: mod_gcl/%.o | ansi_gcl_gprof/all.hsh
	$(CC) $(AM_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) \
	      -fno-omit-frame-pointer -pg -c  $(<D)/$*.c -o $@
	cat $(<D)/$*.data >>$@
ansi_gcl_gprof/%.o: pcl_gcl/%.o | ansi_gcl_gprof/all.hsh
	$(CC) $(AM_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) \
	      -fno-omit-frame-pointer -pg -c  $(<D)/$*.c -o $@
	cat $(<D)/$*.data >>$@
ansi_gcl_gprof/%.o: ansi_gcl/%.o | ansi_gcl_gprof/all.hsh
	$(CC) $(AM_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) \
	      -fno-omit-frame-pointer -pg -c  $(<D)/$*.c -o $@
	cat $(<D)/$*.data >>$@

unixport/libansi_gcl_gprof.a: $(addprefix ansi_gcl_gprof/,$(MOD_OBJS) $(PCL_OBJS) $(CLCS_OBJS)) \
			      unixport/libgcl_gprof.a

unixport/lib%.a: unixport/sys_%.o | xbin/ar_merge
	$| crus $@ $^

clean_%:
	rm -rf $* unixport/$* unixport/lib$*.a unixport/saved_$*
#remake_%: clean_% unixport/saved_%

unixport/init_raw.lsp: unixport/init_raw.lsp.in majvers minvers release git.tag

	cat $< | sed \
		-e "s#@LI-VERS@#(`cat $(word 2,$^)`.`cat $(word 3,$^)`) `cat $(word 4,$^)`#1" \
		-e "s#@LI-EXTVERS@#`cat $(word 3,$^) | cut -f2 -d.`#1" \
		-e "s#@LI-MINVERS@#`cat $(word 3,$^) | cut -f1 -d.`#1" \
		-e "s#@LI-MAJVERS@#`cat $(word 2,$^)`#1" \
		-e "s#@LI-GITTAG@#`cat $(word 5,$^)`#1" \
		-e "s#@LI-RELEASE@#`cat $(word 4,$^)`#1" \
		-e "s#@LI-CC@#\"$(GCL_CC) -c $(filter-out -pg,$(FINAL_CFLAGS))\"#1" \
		-e "s#@LI-DFP@#\"$(filter -pg,$(FINAL_CFLAGS))\"#1" \
		-e "s#@LI-LD@#\"$(GCL_CC) $(LD_FLAGS) -o \"#1" \
		-e "s#@LI-LD-LIBS@#\" $(LD_LIBS_POST)\"#1" \
		-e "s#@LI-OPT-THREE@#\"$(O3FLAGS)\"#1" \
		-e "s#@LI-OPT-TWO@#\"$(O2FLAGS)\"#1" \
		-e "s#@LI-INIT-LSP@#\"$@\"#1" >$@

CMPINCLUDE_FILES=h/cmpincl1.h h/gclincl.h h/compbas.h h/type.h h/mgmp.h \
	h/lu.h h/globals.h  h/vs.h \
	h/bds.h h/frame.h \
	h/lex.h \
	h/mstdint.h h/compbas2.h \
	h/compprotos.h  h/immnum.h

h/mstdint.h:
	echo "#include <stdint.h>" | $(CC) -E -I./h/ - | $(AWK) '/fsid/ {next} {print}' >$@

h/mcompdefs.h: h/compdefs.h h/new_decl.h
	$(AWK) 'BEGIN {print "#include \"include.h\"";print "#include \"page.h\"";print "---"} {a=$$1;gsub("\\.\\.\\.","",a);print "\"#define " $$1 "\" " a}' $< |\
	$(CC) $(AM_CPPFLAGS) $(AM_CFLAGS) -E -P -I./h/ - |\
	$(AWK) '/^\-\-\-$$/ {i=1;next} {if (!i) next} {gsub("\"","");print}' >$@

h/cmpincludea.h: $(CMPINCLUDE_FILES)
	cat $^ | $(CC) $(AM_CPPFLAGS) $(AM_CFLAGS) -E -I./h/ - | $(AWK) '/^# |^$$|^#pragma/ {next}{print}' > $@

h/cmpinclude.h: h/mcompdefs.h h/cmpincludea.h h/cmponly_last.h h/config.h | xbin/move-if-changed
	cat $(filter-out h/config.h,$^) >tmph
	$| mv tmph $@
	rm -f tmph

INI_FILES=$(filter-out o/new_init.ini,$(patsubst %.c,%.ini,$(C_SRC)))
if AMM_GPROF
INI_FILES+=o/gprof.ini
endif

h/new_decl.h: $(INI_FILES) | xbin/move-if-changed
	echo '#include "make-decl.h"' > foo.c
	cat $^ |sed 's,DEFBFUN,DEFUN,g' >> foo.c
	$(CPP) $(AM_CPPFLAGS) $(CPPFLAGS) foo.c | sed -n -e '/#/d' -e '/DO_/d' -e '/[a-zA-Z;]/p' > tmpini
	$| mv tmpini $@
	rm -f foo.c tmpini

o/boot.h: o/boot.ini
	echo '#include "make-init.h"' > $@
	echo 'void gcl_init_boot(void){' >> $@
	cat $< >> $@
	echo '}' >> $@

unixport/libboot.so: o/boot.c o/boot.h h/new_decl.h
	$(CC) $(AM_CPPFLAGS) -Io $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) \
		-fPIC -shared -Wl,-undefined -Wl,dynamic_lookup $< -o $@

o/boot.ini: CPPFLAGS += -DNO_BOOT_H
o/%.ini:  o/%.c | o/grab_defs xbin/move-if-changed
	$(CPP) $(AM_CPPFLAGS) -DINICOMP -DNO_DEFUN $(CPPFLAGS) $< | $(word 1,$|) > $*.inj
	$(word 2,$|) mv $*.inj $@

NDF=$(C_SRC) $(patsubst o/%.c,o/lib_libbase_gcl_gprof_a-%.c,$(C_SRC) o/gprof.c) o/user_init.c o/user_match.c o/gprof.c o/lib_libgprof_a-gprof.c gcl-tk/g_gcltkaux-guis.c gcl-tk/g_gcltkaux-tkAppInit.c gcl-tk/g_gcltkaux-tkMain.c
$(patsubst %.c,%.o,$(NDF)): h/new_decl.h

o/new_init.c: $(INI_FILES)
	echo '#include "make-init.h"' > $@
	echo 'void NewInit(void){' >> $@
	cat $^ >> $@
	echo '}' >> $@
	! cat $@ | awk -F, '/DEFUN/ {print $$1,$$2}' | grep -v object || (rm $@ && false)

o/foo.c:
	touch $@

a/copy: ansi-tests | a
	cp $</*.lsp $(@D)
	touch $@

a/test_results: a/copy | unixport/saved_ansi_gcl
	cd $(@D) && echo '(load "gclload")' | ../$| |tee $(@F)

bin/gcl: bin/gcl.sh majvers minvers
	sed -e "s,@EXT@,$(PEXT),g" \
	    -e "s,@VERS@,$$(cat $(word 2,$^)).$$(cat $(word 3,$^)),g" \
	    -e "s,@TKVERS@,$$(echo $(TK_CONFIG_PREFIX) |sed 's,.*/tk,,g'),g" $< >$@
	chmod a+x $@

check: a/copy
check_SCRIPTS=a/test_results

g/gcltksrv$(EXEEXT): gcl-tk/gcltksrv.in | g
	cat $<  | sed -e "s!TK_LIBRARY=.*!TK_LIBRARY=${TK_LIBRARY}!g" \
	-e "s!TCL_LIBRARY=.*!TCL_LIBRARY=${TCL_LIBRARY}!g" \
	-e "s!TK_XLIB_DIR=.*!TK_XLIB_DIR=${TK_XLIB_DIR}!g" \
	-e "s!GCL_TK_DIR=.*!GCL_TK_DIR=$(my_unixportdir)/gcl-tk!g" > $@
	chmod a+x $@

g/%.o: gcl-tk/%.lisp | unixport/saved_ansi_gcl g g/demos
	$(word 1,$|) -compile $< -o $@

g/%.o: gcl-tk/%.lsp | unixport/saved_ansi_gcl g
	$(word 1,$|) -compile $< -o $@

g/foo: $(addprefix g/,gcltksrv tkl.o tinfo.o demos/gc-monitor.o gcltkaux)

my_gcltkdir=$(my_libdir)/gcl-tk
my_gcltk_PROGRAMS=g/gcltkaux g/gcltksrv
g_gcltksrv_SOURCES=
g_gcltkaux_SOURCES=gcl-tk/guis.c gcl-tk/tkAppInit.c gcl-tk/tkMain.c
g_gcltkaux_CPPFLAGS=$(AM_CPPFLAGS) $(TK_INCLUDE) $(TCL_INCLUDE) $(TK_XINCLUDES)
g_gcltkaux_LDADD=$(TK_LIB_SPEC) $(TCL_LIB_SPEC)

TEXI2DVI=$(srcdir)/tdf
TEXI2PDF=$(srcdir)/tdf
info_TEXINFOS=info/gcl.texi info/gcl-si.texi info/gcl-tk.texi

man1_MANS=man/man1/gcl.1

install-all: install install-dvi install-pdf install-html

lisp_DATA=elisp/ansi-doc.el elisp/dbl.el elisp/doc-to-texi.el elisp/gcl.el \
          elisp/man1-to-texi.el elisp/sshell.el elisp/smart-complete.el elisp/add-default.el 

c/gcl_collectfn.o: cmpnew/gcl_collectfn.lsp | unixport/saved_gcl c
	$(word 1,$|) -compile $< -o $@

my_unixport_DATA=unixport/init_raw.lsp unixport/gcl.script unixport/libboot.so

my_xgcl2dir=$(my_libdir)/xgcl-2
my_xgcl2_DATA=xgcl-2/sysdef.lisp xgcl-2/gcl_dwtest.lsp xgcl-2/gcl_dwtestcases.lsp

my_pcldir=$(my_libdir)/pcl
my_pcl_DATA=pcl/package.lisp

my_lspdir=$(my_libdir)/lsp
my_lsp_DATA=lsp/gcl_auto_new.lsp lsp/gcl_autoload.lsp lsp/gcl_defmacro.lsp
my_lsp_DATA+=lsp/gcl_evalmacros.lsp lsp/gcl_export.lsp lsp/gcl_module.lsp lsp/gcl_top.lsp

my_hdir=$(my_libdir)/h
my_h_DATA=h/cmpinclude.h

my_cmpnewdir=$(my_libdir)/cmpnew
my_cmpnew_DATA=cmpnew/gcl_cmpopt.lsp c/gcl_collectfn.o cmpnew/gcl_lfun_list.lsp

my_clcsdir=$(my_libdir)/clcs
my_clcs_DATA=clcs/package.lisp

my_gcltk_DATA=g/tkl.o g/tinfo.o gcl-tk/tk-package.lsp gcl-tk/gcl.tcl

my_gcltkddir=$(my_libdir)/gcl-tk/demos
my_gcltkd_DATA=gcl-tk/demos/gc-monitor.lisp g/demos/gc-monitor.o g/demos/index.lsp \
	       gcl-tk/demos/mkBasic.lisp gcl-tk/demos/mkCanvText.lisp gcl-tk/demos/mkdialog.lisp \
	       gcl-tk/demos/mkEntry2.lisp gcl-tk/demos/mkEntry.lisp gcl-tk/demos/mkForm.lisp \
	       gcl-tk/demos/mkHScale.lisp gcl-tk/demos/mkItems.lisp gcl-tk/demos/mkLabel.lisp \
	       gcl-tk/demos/mkListbox.lisp gcl-tk/demos/mkPlot.lisp gcl-tk/demos/mkRadio.lisp \
	       gcl-tk/demos/mkRuler.lisp gcl-tk/demos/mkSearch.lisp gcl-tk/demos/mkStyles.lisp \
	       gcl-tk/demos/mkTextBind.lisp gcl-tk/demos/mkVScale.lisp gcl-tk/demos/nqthm-stack.lisp \
	       gcl-tk/demos/showVars.lisp gcl-tk/demos/widget.lisp

g/demos/index.lsp: g/tkl.o | unixport/saved_gcl
	cd $(@D) && echo "(load \"../../$<\")(tk::get-autoloads (directory \"*.lisp\"))" | ../../$|

bin_SCRIPTS=bin/gcl

