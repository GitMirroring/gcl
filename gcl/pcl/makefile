# makefile for making pcl -- W. Schelter.

-include ../makedefs

FILES:=$(shell ls -1 gcl_*.lisp | sed 's,\.lisp,,1')

AFILES:=$(FILES)

SETUP='(load "../clcs/package.lisp")(load "../clcs/myload1.lisp")(load "sys-package.lisp")' \
	'(setq *features* (delete (quote :kcl) *features*))'\
	'(progn (setq si::*code-block-reserve* (make-array 30000000 :element-type (quote character) :static t)) nil)'\
	'(load "defsys.lisp")(push (quote :kcl) *features*)' \
	'(setq pcl::*default-pathname-extensions* (cons "lisp" "o"))' \
	'(setq pcl::*pathname-extensions* (cons "lisp" "o"))' \
	'(load "sys-proclaim.lisp")' \
	'(setq compiler::*default-h-file* t)'\
	'(setq compiler::*default-c-file* t)'\
	'(setq compiler::*default-data-file* t)'\
	'(setq compiler::*default-system-p* t)' \
	'(setq compiler::*assert-ftype-proclamations* t)' \
	'(setq compiler::*tmp-dir* "" si::*disable-recompile* t)'

LISP?=../unixport/saved_mod_gcl
APPEND=../xbin/append


all: $(addsuffix .c,$(AFILES)) $(addsuffix .o,$(AFILES)) 

gprof_objs: $(addprefix ../gprof/,$(addsuffix .o,$(AFILES)))

../gprof/%.o: %.c #$(DECL)
	$(CC) -I../h -c $(filter-out -fomit-frame-pointer,$(CFLAGS)) $(DEFS) -pg $*.c $(AUX_INFO) -o $@
	${APPEND} ${NULLFILE} $*.data  $@

saved_gcl_pcl: $(LISP)
	cp ../h/cmpinclude.h .
	echo $(SETUP) '(pcl::compile-pcl)' | $< 
	echo $(SETUP) '(pcl::load-pcl)(si::save-system "$@")' | $< $(LISPFLAGS)

$(addsuffix .c,$(AFILES)) $(addsuffix .data,$(AFILES))\
	$(addsuffix .h,$(AFILES)): \
	$(addsuffix .lisp,$(FILES))
	cp ../h/cmpinclude.h .
	echo ${SETUP} '(pcl::compile-pcl)' | $(LISP)

%.o: %.c %.h %.data
	$(CC) $(CFLAGS) -c $< -o $@
	../xbin/append $*.data $@

clean:
	rm -f *.o *.fn *.exe *.dll saved_gcl_pcl cmpinclude.h *.c *.h *.data


# remake the sys-package.lisp and sys-proclaim.lisp files
# Those files may be empty on a first build.
remake-sys-files:
	$(MAKE) clean
	rm -f sys-proclaim.lisp
	touch sys-proclaim.lisp
	$(MAKE)
	echo $(SETUP) '(pcl::load-pcl)(load "../cmpnew/gcl_collectfn.lsp")(pcl::renew-sys-files)' \
		| $(LISP) ../unixport/ $(LISPFLAGS)
	$(MAKE) clean
	$(MAKE)
	echo $(SETUP) '(pcl::load-pcl)(si::all-conflicts)' \
		| $(LISP) ../unixport/ $(LISPFLAGS)

tar:
	$(MAKE) -f makefile.gcl  tar1 DIR=`pwd`

tar1:
	(cd .. ; tar cvf - `basename ${DIR}` | gzip -c > `basename ${DIR}`.tgz) 
.PRECIOUS: gcl_pcl_boot.c
