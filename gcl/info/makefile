.SUFFIXES:
.SUFFIXES: .info .dvi .texi

INFO_DIR=${prefix}/lib/info

PEXT?=
BN:=gcl$(PEXT) $(addprefix gcl$(PEXT),-si -tk)
GCL_TEXI:=$(addsuffix .texi,${BN} gcl${PEXT}-si-index)
GCL_DVI:=$(addsuffix .dvi,${BN})
GCL_PDF:=$(addsuffix .pdf,${BN})
GCL_INFO:=$(addsuffix .info,${BN})
GCL_HTML:=$(addsuffix _html,${BN})

-include ../makedefs

FILES:=${GCL_TEXI} ${GCL_INFO} $(GCL_PDF) $(GCL_HTML) $(GCL_DVI)

all: ${FILES}

${GCL_TEXI}:
	cat $$(echo $@ | sed 's,gcl${PEXT},gcl,g') | \
		sed -e 's,gcl\([:.-]\),gcl${PEXT}\1,g' >$@

%$.info: %.texi
	$(MAKEINFO) $< --output $@

%.tex: %.texi
	$(MAKEINFO) --latex $< --output $@

%.pdf: %.tex
	latex -output-format=pdf $<

%.dvi: %.tex
	latex $<

%_html: %.texi
	mkdir -p $@
	$(MAKEINFO) --html $< --output $@

install: ${FILES}
	mkdir -p $(DESTDIR)${INFO_DIR}
	[ -f $(DESTDIR)$(INFO_DIR)/dir ] || touch $(DESTDIR)$(INFO_DIR)/dir
	grep gcl${PEXT}-si $(DESTDIR)${INFO_DIR}/dir >/dev/null 2>&1 || \
	echo "* GCL Doc: (gcl${PEXT}-si.info).	GNU Common Lisp specific Documentation." >> $(DESTDIR)${INFO_DIR}/dir
	grep gcl${PEXT}-tk $(DESTDIR)${INFO_DIR}/dir >/dev/null 2>&1 || \
	echo "* GCL TK Doc: (gcl${PEXT}-tk.info).	TK window GCL interface." >> $(DESTDIR)${INFO_DIR}/dir
	grep gcl${PEXT}.info $(DESTDIR)${INFO_DIR}/dir >/dev/null 2>&1 || \
	echo "* GCL Ansi Doc: (gcl${PEXT}.info).  Ansi Common Lisp Specification." >> $(DESTDIR)${INFO_DIR}/dir
	cp *.info* $(DESTDIR)${INFO_DIR}/
	mkdir -p $(DESTDIR)$(INFO_DIR)/../doc
	cp -a ${GCL_HTML} $(DESTDIR)$(INFO_DIR)/../doc

clean:
	rm -f *.info* *.html *.dvi *.cp *.ky *.vr *.tp *.pg *.toc *.aux *.log *.fn
	rm -rf *.IC *.IE *.IG *.IP *.IR *.IT *.fu
	rm -rf $(GCL_DVI) $(GCL_HTML) $(GCL_PDF)
	rm -rf *.fns *.vrs *.ICs *.IGs *.IPs *.IRs *.ITs
	[ "${PEXT}" = "" ] || rm -f ${GCL_TEXI}
