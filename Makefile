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
	$(GIT) add data intermediate

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

data: data-deps data-main

data-deps: deps

data-main: \
    data/calendar/jp-holidays.json data/calendar/ryukyu-holidays.json \
    data/calendar/kyuureki-genten.json \
    data/calendar/kyuureki-shoki-genten.json \
    data/calendar/kyuureki-sources.json \
    data/datetime/durations.json data/datetime/gregorian.json \
    data/datetime/weeks.json data/datetime/months.json \
    data/datetime/seconds.json \
    data/timezones/mail-names.json \
    data/langs/locale-names.json data/langs/plurals.json \
    data/calendar/jp-flagdays.json data/calendar/era-systems.json \
    data/calendar/era-defs.json data/calendar/era-codes.html \
    data/calendar/era-yomis.html \
    day-era-maps \
    data/numbers/kanshi.json
clean-data:
	rm -fr local/cldr-core* local/*.json

data/calendar/jp-holidays.json: bin/calendar-jp-holidays.pl \
    local/calendar-new-jp-holidays.json \
    local/calendar-old-jp-holidays.json \
    data/calendar/kyuureki-map.txt
	$(PERL) $< > $@
data/calendar/jp-flagdays.json: bin/calendar-jp-flagdays.pl \
    data/calendar/jp-holidays.json
	$(PERL) $< > $@
data/calendar/ryukyu-holidays.json: bin/calendar-ryukyu-holidays.pl
	$(PERL) $< > $@
local/calendar-new-jp-holidays.json: bin/calendar-new-jp-holidays.pl
	$(PERL) $< > $@
local/calendar-old-jp-holidays.json: bin/calendar-old-jp-holidays.pl
	$(PERL) $< > $@

data/calendar/kyuureki-genten.json: bin/calendar-kyuureki-genten.pl
	mkdir -p tables
	$(PERL) $<
	mv tables/genten-data.json $@
data/calendar/kyuureki-shoki-genten.json: bin/calendar-kyuureki-shoki-genten.pl
	$(PERL) $< > $@
local/kyuureki-sansei.json: bin/calendar-kyuureki-sansei.pl
	$(PERL) $< > $@
data/calendar/kyuureki-sources.json: bin/calendar-kyuureki-sources.pl \
    local/kyuureki-sansei.json data/calendar/kyuureki-map.txt
	$(PERL) $< > $@

local/wp-jp-eras.html:
	$(WGET) -O $@ https://ja.wikipedia.org/wiki/%E5%85%83%E5%8F%B7%E4%B8%80%E8%A6%A7_%28%E6%97%A5%E6%9C%AC%29
local/wp-jp-eras-bare.json: bin/parse-wp-jp-eras-html.pl local/wp-jp-eras.html
	$(PERL) $< > $@
src/wp-jp-eras.json: bin/parse-wp-jp-eras.pl #local/wp-jp-eras-bare.json
	$(PERL) $< > $@
src/eras/wp-jp-era-sets.txt: bin/generate-wp-jp-era-sets.pl \
    src/wp-jp-eras.json
	$(PERL) $< > $@
src/eras/jp-emperor-era-sets.txt: bin/generate-jp-emperor-eras-sets.pl \
    src/jp-emperor-eras.txt
	$(PERL) $< > $@
local/era-defs-jp.json: bin/generate-era-defs-jp.pl \
    src/wp-jp-eras.json data/calendar/kyuureki-map.txt
	$(PERL) $< > $@
local/era-defs-jp-emperor.json: bin/generate-jp-emperor-eras-defs.pl \
    src/jp-emperor-eras.txt
	$(PERL) $< > $@
local/wp-jp-eras-en.html:
	$(WGET) -O $@ https://en.wikipedia.org/wiki/Template:Japanese_era_names
src/wp-jp-eras-en.json: bin/parse-wp-jp-eras-en.pl #local/wp-jp-eras-en.html
	$(PERL) $< > $@
local/wp-cn-eras-tw.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-tw/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
local/wp-cn-eras-cn.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-cn/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
local/wp-cn-eras-tw.json: bin/parse-wp-cn-eras.pl local/wp-cn-eras-tw.html
	$(PERL) $< < local/wp-cn-eras-tw.html > $@
local/wp-cn-eras-cn.json: bin/parse-wp-cn-eras.pl local/wp-cn-eras-cn.html
	$(PERL) $< < local/wp-cn-eras-cn.html > $@
src/wp-cn-eras.json: bin/merge-wp-cn-eras.pl \
    #local/wp-cn-eras-tw.json local/wp-cn-eras-cn.json
	$(PERL) $< > $@
data/calendar/era-systems.json: bin/calendar-era-systems.pl \
    src/eras/*.txt data/calendar/kyuureki-map.txt \
    data/calendar/kyuureki-ryuukyuu-map.txt
	$(PERL) $< > $@
local/era-defs-dates.json: bin/generate-era-defs-dates.pl \
    data/calendar/era-systems.json local/era-defs-jp.json \
    local/era-defs-jp-emperor.json
	$(PERL) $< > $@
local/era-defs-jp-wp-en.json: bin/era-defs-jp-wp-en.pl \
    local/era-defs-jp.json \
    local/era-defs-dates.json src/wp-jp-eras-en.json
	$(PERL) $< > $@
local/number-values.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-chars/master/data/number-values.json
local/era-yomi-list.json: bin/era-yomi-list.pl \
    src/wp-jp-eras.json src/era-yomi*.txt \
    local/era-defs-jp-wp-en.json
	$(PERL) $< > $@
data/calendar/era-yomis.html: bin/calendar-era-yomis.pl \
    local/era-yomi-list.json
	$(PERL) $< > $@
data/calendar/era-defs.json: bin/calendar-era-defs.pl \
    local/era-defs-jp.json local/era-defs-jp-emperor.json \
    local/era-defs-dates.json src/char-variants.txt \
    local/era-defs-jp-wp-en.json src/era-data.txt src/era-yomi.txt \
    src/jp-private-eras.txt src/era-variants.txt \
    src/wp-cn-eras.json src/era-china-dups.txt local/number-values.json \
    src/era-viet.txt src/era-korea.txt src/era-tw.txt \
    data/calendar/era-systems.json data/numbers/kanshi.json \
    intermediate/era-ids.json \
    src/era-codes-14.txt src/era-codes-15.txt \
    local/cldr-core-json/ja.json
	$(PERL) $< > $@
#intermediate/era-ids.json: data/calendar/era-defs.json
data/calendar/era-codes.html: bin/calendar-era-codes.pl \
    data/calendar/era-defs.json
	$(PERL) $< > $@

day-era-maps: \
    data/calendar/day-era/map-jp.txt \
    data/calendar/day-era/map-jp-filtered.txt \
    data/calendar/day-era/map-ryuukyuu.txt \
    data/calendar/day-era/map-ryuukyuu-filtered.txt

data/calendar/day-era/map-jp.txt: bin/generate-day-era-map.pl \
    data/calendar/era-systems.json data/calendar/era-defs.json
	$(PERL) $< jp > $@
data/calendar/day-era/map-jp-filtered.txt: bin/filter-day-era-map.pl \
    data/calendar/day-era/map-jp.txt
	$(PERL) $< data/calendar/day-era/map-jp.txt > $@
data/calendar/day-era/map-ryuukyuu.txt: bin/generate-day-era-map.pl \
    data/calendar/era-systems.json data/calendar/era-defs.json
	$(PERL) $< ryuukyuu > $@
data/calendar/day-era/map-ryuukyuu-filtered.txt: bin/filter-day-era-map.pl \
    data/calendar/day-era/map-ryuukyuu.txt
	$(PERL) $< data/calendar/day-era/map-ryuukyuu.txt > $@

local/era-chars.json: bin/generate-era-chars.pl \
    data/calendar/era-defs.json
	$(PERL) $< > $@
local/cn-era-name-diff.txt: bin/generate-cn-era-name-diff.pl \
    src/wp-cn-eras.json
	$(PERL) $< > $@
local/era-jp-conflicts.json: bin/generate-era-jp-conflicts.pl \
    data/calendar/era-defs.json
	$(PERL) $< > $@
local/era-conflict-count.json: bin/generate-era-conflict-count.pl \
    data/calendar/era-defs.json
	$(PERL) $< > $@

local/leap-seconds.txt:
	$(WGET) -O $@ https://www.ietf.org/timezones/data/leap-seconds.list
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
	$(WGET) -O $@ https://www.unicode.org/repos/cldr/tags/latest/common/main/
local/cldr-locales.txt: local/cldr-locales.html
	perl -e 'while (<>) { if (/href="([0-9a-zA-Z_]+)\.xml"/) { print "$$1\n" } }' < $< > $@
local/fx-locales.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-web-impls/staging/data/firefox-locales.json
local/mediawiki-locales.php:
	$(WGET) -O $@ https://raw.githubusercontent.com/wikimedia/mediawiki/master/languages/data/Names.php
local/mediawiki-locales.txt: local/mediawiki-locales.php
	perl -e 'local $$/ = undef; $$x = <>; $$x =~ s{/\*.*?\*/}{}gs; $$x =~ s{#.*\n}{\n}g; $$q = chr 0x27; while ($$x =~ /$$q([a-z0-9-]+)$$q\s*=>/g) { print "$$1\n" }' < $< > $@

local/cldr-core.zip:
	$(WGET) -O $@ https://www.unicode.org/Public/cldr/latest/core.zip
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
local/cldr-core-json/ja.json: local/cldr-core-json-files

data/langs/locale-names.json: bin/langs-locale-names.pl \
  local/cldr-locales.txt src/ms-locales.txt src/chromewebstore-locales.txt \
  local/fx-locales.json src/java-locales.txt local/mediawiki-locales.txt \
  local/cldr-native-language-names.json src/lang-names-additional.txt \
  src/facebook-locales.json
	$(PERL) $< > $@

local/cldr-plurals.xml:
	$(WGET) -O $@ https://www.unicode.org/repos/cldr/trunk/common/supplemental/plurals.xml
local/cldr-plurals-ordinals.xml:
	$(WGET) -O $@ https://www.unicode.org/repos/cldr/trunk/common/supplemental/ordinals.xml
local/cldr-plurals.json: \
  local/cldr-plurals.xml local/cldr-plurals-ordinals.xml \
  bin/parse-cldr-plurals.pl
	$(PERL) bin/parse-cldr-plurals.pl > $@

data/langs/plurals.json: bin/langs-plurals.pl src/plural-exprs.txt \
  src/plural-additional.txt local/cldr-plurals.json
	$(PERL) $< > $@

data/numbers/kanshi.json: bin/numbers-kanshi.pl
	$(PERL) $< > $@

## ------ Tests ------

PROVE = ./prove

local/bin/jq:
	mkdir -p local/bin
	$(WGET) -O $@ https://stedolan.github.io/jq/download/linux64/jq
	chmod u+x $@

test: test-deps test-main

test-deps: deps local/bin/jq

test-main:
	$(PROVE) t/*.t

always:
