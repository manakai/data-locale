WGET = wget
GIT = git

all: deps data

clean: clean-data clean-json-ps

updatenightly: update-submodules dataautoupdate

update-submodules:
	#$(CURL) https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	$(GIT) add bin/modules
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
    data/calendar/kyuureki-genten.json \
    data/datetime/durations.json data/datetime/gregorian.json \
    data/datetime/weeks.json data/datetime/months.json \
    data/datetime/seconds.json \
    data/timezones/mail-names.json \
    data/langs/locale-names.json data/langs/plurals.json \
    data/calendar/jp-flagdays.json
clean-data:
	rm -fr local/cldr-core*

data/calendar/jp-holidays.json: bin/calendar-jp-holidays.pl
	$(PERL) $< > $@
data/calendar/jp-flagdays.json: bin/calendar-jp-flagdays.pl \
    data/calendar/jp-holidays.json
	$(PERL) $< > $@
data/calendar/ryukyu-holidays.json: bin/calendar-ryukyu-holidays.pl
	$(PERL) $< > $@

data/calendar/kyuureki-genten.json: bin/calendar-kyuureki-genten.pl
	mkdir -p tables
	$(PERL) $<
	mv tables/genten-data.json $@

local/leap-seconds.txt:
	$(WGET) -O $@ http://www.ietf.org/timezones/data/leap-seconds.list
	touch $@

data/datetime/durations.json: bin/datetime-durations.pl
	$(PERL) $< > $@
data/datetime/gregorian.json: bin/datetime-gregorian.pl
	$(PERL) $< > $@
data/datetime/weeks.json: bin/datetime-weeks.pl
	$(PERL) $< > $@
data/datetime/months.json: bin/datetime-months.pl
	$(PERL) $< > $@
data/datetime/seconds.json: bin/datetime-seconds.pl local/leap-seconds.txt
	$(PERL) $< > $@

data/timezones/mail-names.json: bin/timezones-mail-names.pl
	$(PERL) $< > $@

local/cldr-locales.html:
	$(WGET) -O $@ http://www.unicode.org/repos/cldr/tags/latest/common/main/
local/cldr-locales.txt: local/cldr-locales.html
	perl -e 'while (<>) { if (/href="([0-9a-zA-Z_]+)\.xml"/) { print "$$1\n" } }' < $< > $@
local/fx-locales.html:
	$(WGET) -O $@ https://archive.mozilla.org/pub/mozilla.org/firefox/releases/latest/linux-x86_64/
local/fx-locales.txt: local/fx-locales.html
	perl -e 'while (<>) { if (m{href="(?:[^"]+?/|)([0-9a-zA-Z-]+)/"}) { print "$$1\n" unless {xpi => 1}->{$$1} } }' < $< > $@
local/mediawiki-locales.php:
	$(WGET) -O $@ https://raw.githubusercontent.com/wikimedia/mediawiki/master/languages/Names.php
local/mediawiki-locales.txt: local/mediawiki-locales.php
	perl -e 'local $$/ = undef; $$x = <>; $$x =~ s{/\*.*?\*/}{}gs; $$x =~ s{#.*\n}{\n}g; $$q = chr 0x27; while ($$x =~ /$$q([a-z0-9-]+)$$q\s*=>/g) { print "$$1\n" }' < $< > $@

local/cldr-core.zip:
	$(WGET) -O $@ http://www.unicode.org/Public/cldr/latest/core.zip
local/cldr-core-files: local/cldr-core.zip
	mkdir -p local/cldr-core
	cd local/cldr-core && unzip ../cldr-core.zip
	touch $@
local/cldr-core-json-files: local/cldr-core-files bin/parse-cldr-main.pl
	$(PERL) bin/parse-cldr-main.pl
	touch $@
local/cldr-native-language-names.json: local/cldr-core-json-files \
  bin/cldr-native-language-names.pl
	$(PERL) bin/cldr-native-language-names.pl > $@

local/facebook-locales.xml:
	$(WGET) -O $@ https://www.facebook.com/translations/FacebookLocales.xml
local/facebook-locales.json: local/facebook-locales.xml \
  bin/parse-facebook-locales.pl
	$(PERL) bin/parse-facebook-locales.pl > $@

data/langs/locale-names.json: bin/langs-locale-names.pl \
  local/cldr-locales.txt src/ms-locales.txt src/chromewebstore-locales.txt \
  local/fx-locales.txt src/java-locales.txt local/mediawiki-locales.txt \
  local/cldr-native-language-names.json src/lang-names-additional.txt \
  local/facebook-locales.json
	$(PERL) $< > $@

local/cldr-plurals.xml:
	$(WGET) -O $@ http://www.unicode.org/repos/cldr/trunk/common/supplemental/plurals.xml
local/cldr-plurals-ordinals.xml:
	$(WGET) -O $@ http://www.unicode.org/repos/cldr/trunk/common/supplemental/ordinals.xml
local/cldr-plurals.json: \
  local/cldr-plurals.xml local/cldr-plurals-ordinals.xml \
  bin/parse-cldr-plurals.pl
	$(PERL) bin/parse-cldr-plurals.pl > $@

data/langs/plurals.json: bin/langs-plurals.pl src/plural-exprs.txt \
  src/plural-additional.txt local/cldr-plurals.json
	$(PERL) $< > $@

## ------ Tests ------

PROVE = ./prove

local/bin/jq:
	mkdir -p local/bin
	$(WGET) -O $@ http://stedolan.github.io/jq/download/linux64/jq
	chmod u+x $@

test: test-deps test-main

test-deps: deps local/bin/jq

test-main:
	$(PROVE) t/*.t

always:
