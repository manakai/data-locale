# -*- Makefile -*-

WGET = wget
GIT = git

all: deps data

clean: clean-data

dataautoupdate: clean all
	$(GIT) add data

## ------ Setup ------

deps: git-submodules pmbp-install

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

## ------ Generation ------

PERL = ./perl

data: data/calendar/jp-holidays.json data/calendar/ryukyu-holidays.json
clean-data:
	rm -fr data/calendar/jp-holidays.json
	rm -fr data/calendar/ryukyu-holidays.json

data/calendar/jp-holidays.json: bin/calendar-jp-holidays.pl
	$(PERL) $< > $@

data/calendar/ryukyu-holidays.json: bin/calendar-ryukyu-holidays.pl
	$(PERL) $< > $@

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
#	$(PROVE) t/*.t