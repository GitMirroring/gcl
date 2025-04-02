export C_INCLUDE_PATH=$(srcdir)/h:$(srcdir)/gcl-tk

AM_CPPFLAGS=$(BASE_CPPFLAGS)
AM_CFLAGS=$(BASE_CFLAGS)
AM_LDFLAGS=$(BASE_LDFLAGS)
AUTOMAKE_OPTIONS=subdir-objects info-in-builddir


my_libdir=$(libdir)/$(PACKAGE)-$(PACKAGE_VERSION)
my_unixportdir=$(my_libdir)/unixport
my_gcltkdir=$(my_libdir)/gcl-tk
my_xgcl2dir=$(my_libdir)/xgcl-2
my_pcldir=$(my_libdir)/pcl
my_lspdir=$(my_libdir)/lsp
my_hdir=$(my_libdir)/h
my_cmpnewdir=$(my_libdir)/cmpnew
my_clcsdir=$(my_libdir)/clcs
my_gcltkddir=$(my_libdir)/gcl-tk/demos
docdir=$(datarootdir)/doc/$(PACKAGE)

# primaries

noinst_PROGRAMS=bin/dpp o/grab_defs
my_unixport_PROGRAMS=unixport/saved_gcl unixport/saved_ansi_gcl
my_gcltk_PROGRAMS=gcl-tk/gcltkaux gcl-tk/gcltksrv
noinst_LIBRARIES=lib/libbase_gcl.a
my_unixport_LIBRARIES=unixport/libgcl.a unixport/libansi_gcl.a
bin_SCRIPTS=bin/gcl
check_SCRIPTS=ansi-tests/test_results
info_TEXINFOS=info/gcl.texi info/gcl-si.texi info/gcl-tk.texi
man1_MANS=man/man1/gcl.1
lisp_DATA=elisp/ansi-doc.el elisp/dbl.el elisp/doc-to-texi.el elisp/gcl.el \
          elisp/man1-to-texi.el elisp/sshell.el elisp/smart-complete.el elisp/add-default.el
my_unixport_DATA=$(addprefix unixport/,init_raw.lsp gcl.script libboot.so \
				       gcl_cmpnopt_gcl.lsp gcl_cmpnopt_ansi_gcl.lsp)
my_xgcl2_DATA=xgcl-2/sysdef.lisp xgcl-2/gcl_dwtest.lsp xgcl-2/gcl_dwtestcases.lsp
my_pcl_DATA=pcl/package.lisp
my_lsp_DATA=lsp/gcl_auto_new.lsp lsp/gcl_autoload.lsp lsp/gcl_defmacro.lsp
my_lsp_DATA+=lsp/gcl_evalmacros.lsp lsp/gcl_export.lsp lsp/gcl_module.lsp lsp/gcl_top.lsp
my_h_DATA=h/cmpinclude.h
my_cmpnew_DATA=cmpnew/gcl_cmpopt.lsp c/gcl_collectfn.o cmpnew/gcl_lfun_list.lsp
my_clcs_DATA=clcs/package.lisp
my_gcltk_DATA=gcl-tk/tkl.o gcl-tk/tinfo.o gcl-tk/tk-package.lsp gcl-tk/gcl.tcl
my_gcltkd_DATA=$(addprefix gcl-tk/demos/,gc-monitor.lisp mkBasic.lisp mkCanvText.lisp mkdialog.lisp \
	            mkEntry2.lisp mkEntry.lisp mkForm.lisp mkHScale.lisp mkItems.lisp mkLabel.lisp \
	            mkListbox.lisp mkPlot.lisp mkRadio.lisp mkRuler.lisp mkSearch.lisp mkStyles.lisp \
	            mkTextBind.lisp mkVScale.lisp nqthm-stack.lisp showVars.lisp widget.lisp) \
	       $(addprefix gcl-tk/demos/,gc-monitor.o index.lsp)
doc_DATA=$(DWDOCS) xgcl-2/dwdoc.pdf

if AMM_GPROF
LIBGPROF=lib/libgprof.a
noinst_LIBRARIES+=$(LIBGPROF) lib/libbase_gcl_gprof.a
my_unixport_PROGRAMS+=unixport/saved_gcl_gprof unixport/saved_ansi_gcl_gprof
my_unixport_LIBRARIES+=unixport/libgcl_gprof.a unixport/libansi_gcl_gprof.a
endif

if AMM_XGCL
X_OBJS=$(addprefix gcl_,$(addsuffix .o,\
	Xlib Xutil X XAtom defentry_events Xstruct XStruct_l_3 \
	general keysymdef X10 Xinit dwtrans tohtml index))
X_LIB=lib/libxgcl.a
noinst_LIBRARIES+=$(X_LIB)
if AMM_GPROF
noinst_LIBRARIES+=lib/libxgcl_gprof.a
endif
endif


# end of primaries


lib_libbase_gcl_a_SOURCES=$(C_SRC)
lib_libgprof_a_SOURCES=o/gprof.c
lib_libgprof_a_CFLAGS=$(AM_CFLAGS) -fno-omit-frame-pointer -pg
$(patsubst %.c,%.o,$(C_SRC)) o/lib_libgprof_a-gprof.o: h/new_decl.h # FIXME
lib_libbase_gcl_gprof_a_SOURCES=$(C_SRC) o/gprof.c
lib_libbase_gcl_gprof_a_CFLAGS=$(AM_CFLAGS) -fno-omit-frame-pointer -pg
lib_libbase_gcl_gprof_a_CPPFLAGS=$(AM_CPPFLAGS) -DGCL_GPROF
$(patsubst %.c,%.o,$(patsubst o/%,o/lib_libbase_gcl_gprof_a-%,$(C_SRC) o/gprof.c)): h/new_decl.h #FIXME
X_SRC=xgcl-2/Events.c xgcl-2/general-c.c xgcl-2/XStruct-2.c xgcl-2/XStruct-4.c xgcl-2/Xutil-2.c
lib_libxgcl_a_SOURCES=$(X_SRC)
lib_libxgcl_gprof_a_SOURCES=$(X_SRC)
lib_libxgcl_gprof_a_CFLAGS=$(AM_CFLAGS) -fno-omit-frame-pointer -pg

unixport_saved_gcl_SOURCES=
unixport/saved_gcl$(EXEEXT):
unixport_saved_ansi_gcl_SOURCES=
unixport/saved_ansi_gcl$(EXEEXT):
unixport_saved_gcl_gprof_SOURCES=
unixport/saved_gcl_gprof$(EXEEXT):
unixport_saved_ansi_gcl_gprof_SOURCES=
unixport/saved_ansi_gcl_gprof$(EXEEXT):
unixport/libgcl.a:
unixport/libansi_gcl.a:
unixport/libgcl_gprof.a:
unixport/libansi_gcl_gprof.a:

GCLTK_SRC=gcl-tk/guis.c gcl-tk/tkAppInit.c gcl-tk/tkMain.c
gcl_tk_gcltksrv_SOURCES=
gcl_tk_gcltkaux_SOURCES=$(GCLTK_SRC)
gcl_tk_gcltkaux_CPPFLAGS=$(AM_CPPFLAGS) $(TK_INCLUDE) $(TCL_INCLUDE) $(TK_XINCLUDES)
gcl_tk_gcltkaux_LDADD=$(TK_LIB_SPEC) $(TCL_LIB_SPEC)
$(patsubst %.c,%.o,$(patsubst gcl-tk/%,gcl-tk/gcltkaux-%,$(GCLTK_SRC))): h/new_decl.h # FIXME

DWDOCS=$(addprefix xgcl-2/dwdoc/dwdoc,$(addsuffix .html,1 2 3 contents index))

TEXI2DVI=xbin/tdf
TEXI2PDF=xbin/tdf

MY_DIRS=gcl0 gcl1 gcl2 gcl3 gcl mod_gcl0 mod_gcl pcl_gcl ansi_gcl

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
	 o/gcl_readline.c o/package.c o/read.c o/symbol.c \
	 o/bcmp.c o/bcopy.c o/bzero.c o/user_init.c o/user_match.c

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

MOD_STUBS=ansi_io defpackage destructuring_bind loop make_defpackage
MOD_OBJS=$(addprefix gcl_,$(addsuffix .o,$(MOD_STUBS))) $(X_OBJS)
MOD_FOBJS=$(addprefix mod_gcl/,$(MOD_OBJS)) $(L_FOBJS) $(X_LIB)

PCL_STUBS=boot braid cache combin compat cpl ctypes defclass defcombin defs dfun dlisp2\
	  dlisp env fast_init fin fixup fngen fsc generic_functions impl_low init iterate\
	  low macros methods pkg precom1 precom2 slots_boot slots std_class vector walk
PCL_OBJS=$(addprefix gcl_pcl_,$(addsuffix .o,$(PCL_STUBS)))
PCL_FOBJS=$(addprefix pcl_gcl/,$(PCL_OBJS)) $(MOD_FOBJS)

CLCS_STUBS=condition_definitions conditions precom
CLCS_OBJS=$(addprefix gcl_clcs_,$(addsuffix .o,$(CLCS_STUBS)))
ANSI_FOBJS=$(addprefix ansi_gcl/,$(CLCS_OBJS)) $(PCL_FOBJS)

$(addprefix unixport/saved_,gcl ansi_gcl gcl_gprof ansi_gcl_gprof):\
unixport/saved_%: unixport/raw_% # rebuild these only when out of date

unixport/saved_%: | unixport/raw_% unixport/gcl_cmpnopt_%.lsp h/cmpinclude.h \
		    unixport/libboot.so unixport/init_raw.lsp
	rm -rf sb_$* # FIXME sandbox ugliness for parallel builds
	mkdir sb_$*
	cd sb_$* && \
		ar x ../unixport/lib$*.a $$(ar t ../unixport/lib$*.a |grep ^gcl_) && \
		ln -snf gcl_cmpnopt_$*.lsp ../unixport/gcl_cmpnopt.lsp && \
		mkdir h && \
		ln -snf ../../h/cmpinclude.h h/ && \
		GCL_LSPSYSDIR=../$(srcdir)/unixport/ \
			../unixport/raw_$* $$(dirname $$(pwd))/unixport/ -libdir $$(dirname $$(pwd))/ \
			    < <(cat ../unixport/init_raw.lsp <(echo "(system:save-system \"../$@\")"))
	rm -rf sb_$*

unixport/raw_%: unixport/lib%.a
	$(CC) $(AM_LDFLAGS) -rdynamic -Wl,-z,relro $(LDFLAGS) -o $@ $< $(LIBS) #FIXME relro

unixport/gcl_cmpnopt_gcl_gprof.lsp unixport/gcl_cmpnopt_ansi_gcl_gprof.lsp:\
unixport/gcl_cmpnopt_%_gprof.lsp: unixport/gcl_cmpnopt_%.lsp
	ln -snf $$(basename $<) $@
unixport/gcl_cmpnopt_pre_gcl.lsp: # FIXME necessary?
	touch $@
unixport/gcl_cmpnopt_%.lsp: unixport/lib%.a | unixport/%
	echo "(mapc (quote load) (directory \"$*/*.hsh\"))" \
	     "(compiler::dump-inl-hash \"$@\")" | $|

$(addprefix unixport/lib,$(addsuffix .a,pre_gcl $(MY_DIRS))): \
unixport/lib%.a: lib/libbase_gcl.a $(LIBGPROF) unixport/sys_%.o
$(addprefix unixport/lib,$(addsuffix .a,gcl_gprof ansi_gcl_gprof)): \
unixport/lib%.a:lib/libbase_gcl_gprof.a unixport/sys_%.o

.POSIX: # parallel job ordering
E0=s typep nr deftype cmptype cmpinline cmpflet
L0=c listlib seqlib type evalmacros
E0_OBJS=$(addprefix gcl_,$(addsuffix .o,$(E0)))
M0_OBJS=$(filter-out $(E0_OBJS) $(L0_OBJS),$(L_OBJS))
L0_OBJS=$(addprefix gcl_,$(addsuffix .o,$(L0)))
unixport/libgcl0.a: $(addprefix gcl0/,$(E0_OBJS) $(M0_OBJS) $(L0_OBJS))

$(addprefix unixport/lib,$(addsuffix .a,gcl1 gcl2 gcl3 gcl)):\
unixport/lib%.a: $(addprefix %/,$(L_OBJS))
unixport/libmod_gcl0.a unixport/libmod_gcl.a:\
unixport/lib%.a: $(addprefix %/,$(MOD_OBJS)) $(L_FOBJS) $(X_LIB)
unixport/libgcl.a unixport/libmod_gcl.a: unixport/lib%.a: %/recompile
unixport/libpcl_gcl.a: $(PCL_FOBJS)
unixport/libansi_gcl.a: $(ANSI_FOBJS)

unixport/libgcl_gprof.a: $(patsubst %.o,%.go,$(L_FOBJS))
unixport/libansi_gcl_gprof.a: $(patsubst %.o,%.go,$(ANSI_FOBJS))

unixport/lib%.a: | xbin/ar_merge
	$| crus $@ $^

%/recompile: | unixport/%
	$| -batch \
	   -eval "(let ((si::*do-recomp-output-dir* \"$(@D)\")) (si::do-recomp t))" \
	   -eval "(compiler::dump-inl-hash \"$(@D)/all.hsh\")"
	touch $@

unixport/sys_%.o: unixport/sys_init.c h/new_decl.h
	i=$$(echo $* | sed 's,[0-9],,g' | sed 's,_gprof,,g'); \
	   $(CC) $(AM_CPPFLAGS) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) -D $$i -D FLAVOR="$$i" -c $< -o $@

unixport/gcl0: | unixport/saved_pre_gcl
unixport/gcl1: | unixport/saved_gcl0
unixport/gcl2: | unixport/saved_gcl1
unixport/gcl3: | unixport/saved_gcl2
unixport/gcl:  | unixport/saved_gcl3
unixport/mod_gcl0:  | unixport/saved_gcl
unixport/mod_gcl:  | unixport/saved_mod_gcl0
unixport/pcl_gcl:  | unixport/saved_mod_gcl
unixport/ansi_gcl:  | unixport/saved_pcl_gcl
$(addprefix unixport/,gcl0 gcl1): unixport/% : unixport/cinit.lisp | %
	$(word 2,$|) < <(cat $< <(echo "(system:save-system \"$@\")"))
$(addprefix unixport/,gcl2 gcl3 gcl mod_gcl): unixport/% : | %
	ln -snf $$(basename $(word 2,$|)) $@

unixport/mod_gcl0: xgcl-2/sysdef.lisp | mod_gcl0
	rm -f $(@D)/in
	[ "$(X_OBJS)" = "" ] || echo "(load \"$<\")" >$(@D)/in
	echo "(compiler::cdebug)(si::save-system \"$@\")" >>$(@D)/in
	$(word 2,$|) <$(@D)/in
	rm $(@D)/in
	cp gcl/all.hsh $(word 1,$|) #FIXME

unixport/pcl_gcl: clcs/package.lisp clcs/myload1.lisp cmpnew/gcl_collectfn.lsp pcl/defsys.lisp  | pcl_gcl
	echo  "(let ((*features* (remove :kcl *features*))) (mapc (quote load) (list $(patsubst %,\"%\",$^))))" \
	      "(compiler::cdebug)" \
	      "(setq compiler::*assert-ftype-proclamations* t)" \
	      "(setq pcl::*pcl-directory* (cons \"$$(dirname $(word 4,$^))/\" \"$(@F)/\"))" \
	      "(print pcl::*pcl-directory*)" \
	      "(setq pcl::*default-pathname-extensions* (cons \"lisp\" \"o\"))" \
	      "(setq pcl::*pathname-extensions* (cons \"lisp\" \"o\"))" \
	      "(si::save-system \"$@\")" | $(word 2,$|)

unixport/ansi_gcl: clcs/package.lisp clcs/gcl_clcs_precom.lisp \
		   clcs/gcl_clcs_conditions.lisp clcs/gcl_clcs_condition_definitions.lisp \
		   | ansi_gcl
	echo "(mapc (quote load) (list $(patsubst %,\"%\",$^)))" \
             "(compiler::cdebug)" \
             "(si::save-system \"$@\")" | $(word 2,$|)
	cp pcl_gcl/all.hsh $(word 1,$|) #FIXME

gcl0/%.o: $(srcdir)/*/%.lsp | unixport/gcl0
	$| -eval "(mapc 'load (directory \"$(@D)/*.done\"))" -compile $< -o $@
	[ "$*" = "gcl_c" ] || [ "$*" = "gcl_listlib" ] || \
		ln -f $@ $$(echo $@ |sed 's,\.o,\.done,g') #FIXME directory link

gcl1/%.o: $(srcdir)/*/%.lsp  | unixport/gcl1
	$| -eval "(mapc 'load (directory \"$(@D)/*.done\"))" \
	   -eval "(setq compiler::*dump-inl-hash* t)" \
	   -compile $< -o $@
	ln -f $@ $$(echo $@ |sed 's,\.o,\.done,g')

gcl2/%.o: $(srcdir)/*/%.lsp  | unixport/gcl2
	$| -eval "(compiler::cdebug)(setq compiler::*dump-inl-hash* t)" -compile $< -o $@

gcl3/%.o: $(srcdir)/*/%.lsp  | unixport/gcl3
	$| -eval "(compiler::cdebug)(setq compiler::*dump-inl-hash* t)" -compile $< -o $@

gcl/%.o: gcl3/%.o | gcl
	cp $(patsubst %.o,%.*,$<) $(@D)

mod_gcl0/%.o: $(srcdir)/*/%.lsp | unixport/mod_gcl0
	$| -eval "(setq compiler::*dump-inl-hash* t)" -compile $< -o $@

mod_gcl/%.o: mod_gcl0/%.o | unixport/mod_gcl
	cp $(patsubst %.o,%.*,$<) $(@D)


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
	echo "(mapc (quote load) (list $(patsubst %,\"%\",$^)))" \
	     "(pcl::compile-pcl)" \
	     "(compiler::dump-inl-hash \"$@\")" | $|

%/all.hsh: %/p1.lisp %/all.hs1 | unixport/pcl_gcl
	echo "pcl conflicts:"
	echo "(pcl::load-pcl)(si::all-conflicts)" | $|
	cat $^ > $@

$(addprefix pcl_gcl/,$(PCL_OBJS)): pcl_gcl/all.hsh 
	touch $@


ansi_gcl/%.o: clcs/%.lisp | unixport/ansi_gcl
	$| -eval "(setq compiler::*dump-inl-hash* t)" -compile $< -o $@

%.go: %.o mod_gcl/recompile #FIXME parallel
	$(CC) $(AM_CPPFLAGS) -I $(<D) $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) \
	      -fno-omit-frame-pointer -pg -c $*.c -o $@
	cat $*.data >>$@

CMPINCLUDE_FILES=h/cmpincl1.h h/gclincl.h h/compbas.h h/type.h h/mgmp.h \
		 h/lu.h h/globals.h  h/vs.h h/bds.h h/frame.h h/lex.h \
		 h/mstdint.h h/compbas2.h h/compprotos.h  h/immnum.h

h/mstdint.h:
	echo "#include <stdint.h>" | $(CC) -E -I./h/ - | $(AWK) '/fsid/ {next} {print}' >$@

h/mcompdefs.h: h/compdefs.h h/new_decl.h
	$(AWK) 'BEGIN {print "#include \"include.h\"";print "#include \"page.h\"";print "---"} {a=$$1;gsub("\\.\\.\\.","",a);print "\"#define " $$1 "\" " a}' $< |\
	$(CC) $(AM_CPPFLAGS) $(AM_CFLAGS) -E -P -I./h/ - |\
	$(AWK) '/^\-\-\-$$/ {i=1;next} {if (!i) next} {gsub("\"","");print}' >$@

h/cmpincludea.h: $(filter-out gclincl.h,$(CMPINCLUDE_FILES)) | h/gclincl.h # FIXME!
	cat $< $| $(filter-out $<,$^) | \
		$(CC) $(AM_CPPFLAGS) $(AM_CFLAGS) -E -I./h/ - | \
		$(AWK) '/^# |^$$|^#pragma/ {next}{print}' > $@

h/cmpinclude.h: h/mcompdefs.h h/cmpincludea.h h/cmponly_last.h h/config.h | xbin/move-if-changed
	cat $(filter-out h/config.h,$^) >tmph # FIXME config.h order only
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
	$| mv tmpini $@ # FIXME obsolete
	rm -f foo.c tmpini

o/boot.h: o/boot.ini
	echo '#include "make-init.h"' > $@
	echo 'void gcl_init_boot(void){' >> $@
	cat $< >> $@
	echo '}' >> $@

unixport/libboot.so: o/boot.c o/boot.h h/new_decl.h
	$(CC) $(AM_CPPFLAGS) -Io $(CPPFLAGS) $(AM_CFLAGS) $(CFLAGS) \
		-fPIC -shared -Wl,-undefined -Wl,dynamic_lookup $< -o $@

# parallel builds can only have one target accessing an intermediate file
o/boot.ini: CPPFLAGS += -DNO_BOOT_H
o/%.ini:  o/%.d | o/grab_defs xbin/move-if-changed xbin/mktmp bin/dpp # FIXME parallel ugliness
	i=$$($(word 3,$|) $<);j=$$i.c;$(word 4,$|) $< $$j;\
		$(CPP) $(AM_CPPFLAGS) -DINICOMP -DNO_DEFUN $(CPPFLAGS) $$j | $(word 1,$|) > $(@D)/$*.inj;\
		rm $$j;
	$(word 2,$|) mv $(@D)/$*.inj $@
o/%.ini:  o/%.c | o/grab_defs xbin/move-if-changed
	$(CPP) $(AM_CPPFLAGS) -DINICOMP -DNO_DEFUN $(CPPFLAGS) $< | $(word 1,$|) > $(@D)/$*.inj
	$(word 2,$|) mv $(@D)/$*.inj $@

o/new_init.c: $(INI_FILES)
	echo '#include "make-init.h"' > $@
	echo 'void NewInit(void){' >> $@
	cat $^ >> $@
	echo '}' >> $@
	! cat $@ | awk -F, '/DEFUN/ {print $$1,$$2}' | grep -v object || (rm $@ && false)

ansi-tests/test_results: ansi-tests/*.lsp | unixport/saved_ansi_gcl
	[ -d $(@D) ] || (mkdir $(@D) && cp $^ $(@D)) # FIXME testsuite in separate directory, hard
	cd $(@D) && echo '(load "gclload")' | ../$| |tee $(@F)

bin/gcl: bin/in.gcl.sh majvers minvers # FIXME configure
	sed -e "s,@EXT@,,g" \
	    -e "s,@VERS@,$$(cat $(word 2,$^)).$$(cat $(word 3,$^)),g" \
	    -e "s,@TKVERS@,$$(echo $(TK_CONFIG_PREFIX) |sed 's,.*/tk,,g'),g" $< >$@
	chmod a+x $@

gcl-tk/gcltksrv$(EXEEXT): gcl-tk/gcltksrv.in | gcl-tk # FIXME configure
	cat $<  | sed -e "s!TK_LIBRARY=.*!TK_LIBRARY=${TK_LIBRARY}!g" \
	-e "s!TCL_LIBRARY=.*!TCL_LIBRARY=${TCL_LIBRARY}!g" \
	-e "s!TK_XLIB_DIR=.*!TK_XLIB_DIR=${TK_XLIB_DIR}!g" \
	-e "s!GCL_TK_DIR=.*!GCL_TK_DIR=$(my_unixportdir)/../gcl-tk!g" > $@
	chmod a+x $@

gcl-tk/%.o: gcl-tk/%.lisp | unixport/saved_ansi_gcl
	[ -d $(@D) ] || mkdir -p $(@D)
	$(word 1,$|) -compile $< -o $@

gcl-tk/%.o: gcl-tk/%.lsp | unixport/saved_ansi_gcl
	[ -d $(@D) ] || mkdir -p $(@D)
	$(word 1,$|) -compile $< -o $@

gcl-tk/demos/index.lsp: gcl-tk/tkl.o | unixport/saved_gcl
	cd $(@D) && echo "(load \"../../$<\")(tk::get-autoloads (directory \"*.lisp\"))" | ../../$|

c/gcl_collectfn.o: cmpnew/gcl_collectfn.lsp | unixport/saved_gcl c # FIXME directory
	$(word 1,$|) -compile $< -o $@

%.c: %.d | bin/dpp
	bin/dpp $< $@

gcl-tk/demos gcl-tk a c $(MY_DIRS): % :
	[ -d $@ ] || mkdir -p $@

$(DWDOCS): xgcl-2/dwdoc.tex xgcl-2/gcl_tohtml.lsp xgcl-2/gcl_index.lsp | unixport/saved_mod_gcl
	mkdir -p $(@D)
	echo "(in-package :xlib)" \
	     "(progn " \
		"(mapc (quote load) (list $(patsubst %,\"%\",$(filter-out $<,$^))))" \
		"(tohtml \"$<\" \"$(@D)/dwdoc\"))" \
		"(with-open-file (s \"$(@D)/dwdoccontents.html\" :direction :output)" \
			"(let ((*standard-output* s))" \
				"(makecont \"$<\" 1 \"$(@D)/dwdoc\")))" \
	        "(with-open-file (s \"$(@D)/dwdocindex.html\" :direction :output)" \
			"(let ((*standard-output* s))" \
				"(printindex indexdata \"$(@D)/dwdoc\")))" | $|

# package extension

bin/gcl%: bin/in.gcl.sh majvers minvers
	sed -e "s,@EXT@,$*,g" \
	    -e "s,@VERS@,$$(cat $(word 2,$^)).$$(cat $(word 3,$^)),g" \
	    -e "s,@TKVERS@,$$(echo $(TK_CONFIG_PREFIX) |sed 's,.*/tk,,g'),g" $< >$@
	chmod a+x $@

man/man1/gcl%.1: man/man1/gcl.1
	sed -e 's,\(\b\)gcl\(\b\),\1gcl$*\2,g' $< > $@

info/gcl%-si.texi: info/gcl-si.texi # FIXME one rule
	sed -e 's,gcl\([:.-]\),gcl$*\1,g' $< >$@
info/gcl%-tk.texi: info/gcl-tk.texi
	sed -e 's,gcl\([:.-]\),gcl$*\1,g' $< >$@
info/gcl%.texi: info/gcl.texi
	sed -e 's,gcl\([:.-]\),gcl$*\1,g' $< >$@

%.info: %.texi | xbin/mktmp # FIXME parallel ugliness
	i=$$($| $<);ln -f $< $$i;$(MAKEINFO) $$i --output $@;rm $$i
%.tex: %.texi | xbin/mktmp
	i=$$($| $<);ln -f $< $$i;$(MAKEINFO) --latex $$i --output $@;rm $$i
%.pdf: %.tex | xbin/mktmp
	i=$$($| $<);j=$$i.$$(echo $< | sed 's,.*\.,,g');ln -f $< $$j;\
		latex -output-format=pdf -output-directory=$(@D) $$j|tail && mv $$i.pdf $@ && rm $$i*
%.dvi: %.tex | xbin/mktmp
	i=$$($| $<);j=$$i.$$(echo $< | sed 's,.*\.,,g');ln -f $< $$j;\
		latex -output-directory=$(@D) $$i|tail && mv $$i.dvi $@ && rm $$i*
%.html: %.texi | xbin/mktmp
	mkdir -p $@
	i=$$($| $<);ln -f $< $$i;$(MAKEINFO) --html $$i --output $@;rm $$i

# end package extension

install-all: install install-dvi install-pdf install-html

clean_gcl_gprof: clean_% :
	rm -rf unixport/lib$*.a unixport/saved_$* gcl/*.go
clean_ansi_gcl_gprof: clean_% :
	rm -rf unixport/lib$*.a unixport/saved_$* $(addsuffix /*.go,mod_gcl pcl_gcl ansi_gcl)
clean_%:
	rm -rf $* unixport/$* unixport/lib$*.a unixport/saved_$*

clean-local:
	rm -rf $(MY_DIRS) $(addprefix unixport/,$(MY_DIRS))
	rm -rf unixport/*cmpnopt* unixport/lib* unixport/saved_* #FIXME
	rm -rf o/*.inj
	rm -rf h/cmpincludea.h h/mstdint.h # FIXME
	rm -rf $$(echo o/*.d | sed 's,\.d,.c,g') #FIXME
	rm -rf lib g #FIXME
	rm -rf $(addprefix ansi-tests/,\
		compile-file-test-lp.lsp compile-file-test-lp.out \
		file-that-was-renamed.txt foo.fasl foo.lsp foo.txt \
		foo.ufsl ldtest.lsp scratch/ temp.dat test_results \
		tmp.dat tmp.txt)
	rm -rf info/*.idx unixport/in

distclean-local:
	rm -rf o/.Tpo #FIXME
