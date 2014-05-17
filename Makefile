WGET = wget
GIT = git

all: deps data

clean: clean-data clear-json-ps

updatenightly: update-submodules dataautoupdate

update-submodules:
	#$(CURL) https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	#$(GIT) add bin/modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config

dataautoupdate: clean all
	$(GIT) add data

## ------ Setup ------

deps: git-submodules pmbp-install json-ps

git-submodules:
	$(GIT) submodule update --init

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(WGET) -O $@ https://raw.github.com/wakaba/perl-setupenv/master/bin/pmbp.pl
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl --update-pmbp-pl
pmbp-update: git-submodules pmbp-upgrade
	perl local/bin/pmbp.pl --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl --install \
            --create-perl-command-shortcut perl \
            --create-perl-command-shortcut prove

json-ps: local/perl-latest/pm/lib/perl5/JSON/PS.pm
clean-json-ps:
	rm -fr local/perl-latest/pm/lib/perl5/JSON/PS.pm
local/perl-latest/pm/lib/perl5/JSON/PS.pm:
	mkdir -p local/perl-latest/pm/lib/perl5/JSON
	$(WGET) -O $@ https://raw.githubusercontent.com/wakaba/perl-json-ps/master/lib/JSON/PS.pm

## ------ Generation ------

PERL = ./perl

data: data/calendar/jp-holidays.json data/calendar/ryukyu-holidays.json \
    data/datetime/durations.json data/datetime/gregorian.json \
    data/datetime/weeks.json
clean-data:

data/calendar/jp-holidays.json: bin/calendar-jp-holidays.pl
	$(PERL) $< > $@
data/calendar/ryukyu-holidays.json: bin/calendar-ryukyu-holidays.pl
	$(PERL) $< > $@

data/datetime/durations.json: bin/datetime-durations.pl
	$(PERL) $< > $@
data/datetime/gregorian.json: bin/datetime-gregorian.pl
	$(PERL) $< > $@
data/datetime/weeks.json: bin/datetime-weeks.pl
	$(PERL) $< > $@

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
#	$(PROVE) t/*.t