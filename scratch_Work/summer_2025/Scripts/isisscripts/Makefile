all: clean isisscripts help wiki html

isisscripts: share/isisscripts.sl
doc: help
wiki: share/isisscripts.md
help: share/isisscripts.txt
html: share/isisscripts.html

########################################################################

# ISIS scripts

.PHONY: share/isisscripts.sl
share/isisscripts.sl:
	@header='variable _isisscripts_version_string = "'$$(git rev-parse HEAD)' (built on '$$(date +"%Y-%m-%d %H:%M")')";'; \
	bin/makestatic --outfile=share/isisscripts.sl --dir=src --header="$$header" --prefix=build/isisscripts_prefix.sl --postfix=build/isisscripts_postfix.sl > $@
	@make test

.PHONY: test
test:   # fails if any command produces exit code != 0
	@for test in test/*.sl; do \
		echo; \
		echo $$test; \
		isis -g -n -q -10 --script ./$$test || exit 1; \
	done
	@awk -f test/number_of_if_endif_directives.awk share/isisscripts.sl

.PHONY: share/isisscripts.txt
share/isisscripts.txt:
	cd doc && make distclean isisscripts_help.txt isisscripts_help.md && make clean && cd ..
	mv doc/isisscripts_help.txt $@ && mv doc/isisscripts_help.md $@.md

# wiki entries

share/isisscripts.md:
	cd doc && make isisscripts_help.md && cd ..
	mv doc/isisscripts_help.md $@

# html function ref
share/isisscripts.html:
	cd doc && make isisscripts_help.html && cd ..
	mv doc/isisscripts_help.html $@

# S-Lang scripts

.PHONY: share/slangscripts.sl
share/slangscripts.sl:
	@bin/makestatic --dir=src/slang --first=help.sl --first=mean.sl > $@

# clean up

find_ws:
	find src -name \*.sl -exec bin/find_whitespace.pl {} \; | jed

clean:
	@echo "deleting the following files:"
	@find ./ -name \*~
	@find ./ -name \*~ -exec rm -f {} \;
	@echo "-----------------------------"
