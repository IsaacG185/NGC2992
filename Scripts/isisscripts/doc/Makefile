SL2TM        = bin/tm-strip
TM-SORT      = bin/tm-sort.sl
TMEXPAND     = bin/tmexpand
TM_INCLUDE   = share
TM_SLHLP     = slhlp_isisscripts
MODIFY_TEX   = bin/modify_linuxdoc-tex.pl

SLHLP_FILE   = isisscripts_help.txt
DOC_FILENAME = ISISscripts
DOC_FILENAME_BT = ISISscripts_by_topic

########################################################################

BUILDFILES = $(SLHLP_FILE) $(DOC_FILENAME).pdf src/isisscripts.tm src/isisscripts.tm.BAK $(DOC_FILENAME).md

all: $(BUILDFILES)

clean:
	rm -rf *~ */*~ src/isisscripts src/$(DOC_FILENAME).sgml $(DOC_FILENAME).tex  *.log *.aux *.out *.toc *.dvi

distclean: clean
	rm -f $(BUILDFILES) $(DOC_FILENAME)-*.html

########################################################################

src/isisscripts:
	@cd ..; make clean; cd -
	@mkdir -p src
	find ../src -type d -print | perl -ne 'chomp($$_); m|../src(.*)|; my $$dir = "src/isisscripts$$1"; my $$file = "$$dir/tm"; print "if [ ! -d $$dir ]; then mkdir -p $$dir; fi\nrm -f $$file\nfind $$_ -maxdepth 1 -type f -name \\*.sl -exec '$(SL2TM)' {} >> $$file \\;\n'$(TM-SORT)' $$file\nrm -f $$file.BAK\n";' > src/tm-strip.sh
	sh src/tm-strip.sh # | tee tm-strip.log
	@rm -f src/tm-strip.sh

src/isisscripts.tm: src/isisscripts
	@rm -f $@
	find $< -type f -exec cat {} >> $@ \;
	@$(TM-SORT) $@ # | tee tm-sort.log

$(SLHLP_FILE): src/isisscripts.tm $(DOC_FILENAME).md
	$(TMEXPAND) -I$(TM_INCLUDE) -M$(TM_SLHLP) $< $(SLHLP_FILE) # | tee tmexpand_slhlp.log

$(DOC_FILENAME).tex: doc/ISISscripts_tex.tm src/isisscripts.tm
	$(TMEXPAND) -Isrc $< $@

$(DOC_FILENAME).md: doc/ISISscripts_md.tm src/isisscripts.tm
	$(TMEXPAND) -Isrc $< $@

$(DOC_FILENAME).html: doc/ISISscripts_html.tm src/isisscripts.tm
	$(TMEXPAND) -Isrc $< $@

isisscripts_help.md: $(DOC_FILENAME).md
	mv $(DOC_FILENAME).md $@

isisscripts_help.html: $(DOC_FILENAME).html
	mv $(DOC_FILENAME).html $@

%.pdf: %.tex
	xelatex $<
	xelatex $< > /dev/null
	rm -f $(subst .tex,.log,$<) $(subst .tex,.aux,$<) $(subst .tex,.out,$<) $(subst .tex,.toc,$<)

$(DOC_FILENAME).ps: $(DOC_FILENAME).tex
	latex $<
	latex $< > /dev/null
	dvips $(DOC_FILENAME).dvi
	rm -f $(subst .tex,.log,$<) $(subst .tex,.aux,$<) $(subst .tex,.out,$<) $(subst .tex,.toc,$<) $(subst .tex,.dvi,$<)

$(DOC_FILENAME_BT).tex: doc/ISISscripts_by_topic_tex.tm src/isisscripts.tm
	$(TMEXPAND) -Isrc $< $@
