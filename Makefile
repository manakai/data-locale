WGET = wget
GIT = git

all: deps data view

clean: clean-data

updatenightly: update-submodules dataautoupdate

update-submodules:
	$(CURL) -s -S -L https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	$(GIT) add bin/modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/ciconfig/master/ciconfig | RUN_GIT=1 REMOVE_UNUSED=1 perl

dataautoupdate: clean all
	$(GIT) add data intermediate view

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

build-github-pages:
	rm -fr ./bin/ ./modules/ ./t_deps/

## ------ Generation ------

PERL = ./perl -I bin/modules/json-ps/lib

NAMES_DEPS = \
    bin/names.pl \
    local/char-leaders.dat \
    intermediate/kanjion-binran.txt

data: data-deps data-main

data-deps: deps

data-main: \
    data/tags.json data/tag-labels.json \
    data/calendar/jp-holidays.json data/calendar/ryukyu-holidays.json \
    data/calendar/kyuureki-genten.json \
    data/calendar/kyuureki-shoki-genten.json \
    data/calendar/kyuureki-sources.json \
    intermediate/calendar-kyuureki-annotations.json \
    data/datetime/durations.json data/datetime/gregorian.json \
    data/datetime/weeks.json data/datetime/months.json \
    data/datetime/seconds.json \
    data/timezones/mail-names.json \
    data/langs/locale-names.json data/langs/plurals.json \
    data/calendar/jp-flagdays.json data/calendar/era-systems.json \
    data/calendar/era-defs.json data/calendar/era-codes.html \
    data/calendar/era-yomi-sources.json \
    data/calendar/era-kodai-years.html \
    data/calendar/era-kodai-starts.html \
    data/calendar/era-transitions.json \
    data/calendar/era-stats.json \
    data/calendar/era-relations.json \
    data/calendar/era-labels.json \
    data/calendar/dts.json \
    data/calendar/serialized/dtsjp1.txt \
    data/calendar/serialized/dtsjp2.txt \
    data/calendar/serialized/dtsjp3.txt \
    day-era-maps \
    data/numbers/kanshi.json \
    all-langtags \
    intermediate/variants.json
clean-data: clean-langtags
	rm -fr local/cldr-core* local/*.json


local/era-data-tags.txt: src/era-data*.txt
	grep '^%tag ' --no-filename src/era-data*.txt | sed -e 's/^%tag //' > $@
local/tags-0.json: bin/tags.pl $(NAMES_DEPS) \
    src/tags.txt local/era-data-tags.txt
	$(PERL) $< > $@
local/tag-labels-0.json: bin/tag-labels-0.pl $(NAMES_DEPS) \
    local/tags-0.json
	$(PERL) $< > $@
data/tags.json: bin/tags-1.pl local/tags-0.json \
    local/tag-labels-0.json
	$(PERL) $< > $@
data/tag-labels.json: bin/cleanup.pl \
    local/tag-labels-0.json
	$(PERL) $< local/tag-labels-0.json > $@


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
intermediate/calendar-kyuureki-annotations.json: \
    bin/calendar-kyuureki-annotations.pl \
    data/calendar/kyuureki-genten.json \
    data/calendar/kyuureki-shoki-genten.json \
    data/calendar/kyuureki-sources.json \
    src/kyuureki-annotations.txt
	$(PERL) $< > $@

local/wp-jp-eras.html:
	$(WGET) -O $@ https://ja.wikipedia.org/wiki/%E5%85%83%E5%8F%B7%E4%B8%80%E8%A6%A7_%28%E6%97%A5%E6%9C%AC%29
local/wp-jp-eras-bare.json: bin/parse-wp-jp-eras-html.pl local/wp-jp-eras.html
	$(PERL) $< > $@
src/wp-jp-eras.json: bin/parse-wp-jp-eras.pl #local/wp-jp-eras-bare.json
	$(PERL) $< > $@
local/era-defs-jp.json: bin/generate-era-defs-jp.pl src/wp-jp-eras.json
	$(PERL) $< > $@
local/era-defs-jp-emperor.json: bin/generate-jp-emperor-eras-defs.pl \
    src/jp-emperor-eras.txt
	$(PERL) $< > $@
local/wp-jp-eras-en.html:
	$(WGET) -O $@ https://en.wikipedia.org/wiki/Template:Japanese_era_names
src/wp-jp-eras-en.json: bin/parse-wp-jp-eras-en.pl #local/wp-jp-eras-en.html
	$(PERL) $< > $@
#intermediate/wikimedia/*.json:
#	cd intermediate/wikimedia && $(MAKE) all
local/cn-ryuukyuu-era-list.json: bin/cn-ryuukyuu-era-list.pl \
    src/eras/ryuukyuu.txt
	$(PERL) $< > $@

local/era-defs-jp-wp-en.json: bin/era-defs-jp-wp-en.pl \
    local/era-defs-jp.json \
    local/era-date-list.json src/wp-jp-eras-en.json
	$(PERL) $< > $@
local/number-values.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-chars/master/data/number-values.json

local/era-kodai.json: bin/era-kodai.pl \
    src/era-kodai.txt src/era-kodai-6100.txt src/era-kodai-6150.txt
	$(PERL) $< > $@
data/calendar/era-kodai-years.html: bin/calendar-era-kodai-years.pl \
    local/era-kodai.json
	$(PERL) $< > $@
data/calendar/era-kodai-starts.html: bin/calendar-era-kodai-starts.pl \
    local/era-kodai.json
	$(PERL) $< > $@

local/era-date-list.json: bin/era-date-list.pl src/era-start-315.txt
	$(PERL) $< > $@

local/era-yomi-list.json: bin/era-yomi-list.pl \
    src/wp-jp-eras.json src/era-yomi*.txt \
    local/era-defs-jp-wp-en.json \
    local/cldr-core-json/root.json local/cldr-core-json/ja.json \
    intermediate/wikimedia/wp-en-jp-eras.json \
    intermediate/wikimedia/wp-ko-jp-eras.json \
    intermediate/wikimedia/wp-vi-jp-eras.json
	$(PERL) $< > $@
data/calendar/era-yomi-sources.json: bin/calendar-era-yomi-sources.pl \
    data/calendar/era-defs.json \
    local/calendar-era-labels-0.json \
    local/era-yomi-list.json
	$(PERL) $< > $@
local/calendar-era-labels-0.json: bin/calendar-era-labels.pl \
    $(NAMES_DEPS) \
    local/calendar-era-defs-0.json \
    local/era-transitions-0.json \
    src/era-codes-14.txt \
    src/era-codes-15.txt \
    src/era-codes-24.txt \
    local/cldr-core-json/ja.json \
    local/number-values.json \
    data/tags.json data/tag-labels.json
	$(PERL) $< > $@
data/calendar/era-labels.json: bin/cleanup.pl \
    local/calendar-era-labels-0.json
	$(PERL) $< local/calendar-era-labels-0.json > $@

data/calendar/era-defs.json: bin/calendar-era-defs-events.pl \
    local/calendar-era-defs-0.json \
    local/era-transitions-0.json \
    local/calendar-era-relations-0.json \
    local/calendar-era-labels-0.json \
    data/tags.json
	$(PERL) $< > $@
local/calendar-era-defs-0.json: bin/calendar-era-defs.pl \
    $(NAMES_DEPS) \
    local/era-defs-jp.json local/era-defs-jp-emperor.json \
    src/wp-jp-eras.json \
    local/era-defs-jp-wp-en.json \
    src/era-data*.txt \
    src/era-variants.txt \
    intermediate/wikimedia/wp-*-eras.json \
    data/numbers/kanshi.json \
    intermediate/era-ids.json \
    local/era-yomi-list.json \
    local/era-date-list.json \
    local/cn-ryuukyuu-era-list.json \
    data/tags.json \
    src/era-ids-1.txt
	$(PERL) $< > $@
#intermediate/era-ids.json: data/calendar/era-defs.json

data/calendar/era-codes.html: bin/calendar-era-codes.pl \
    data/calendar/era-defs.json
	$(PERL) $< > $@

local/era-transitions-0.json: bin/calendar-era-transitions.pl \
    local/calendar-era-defs-0.json \
    data/tags.json
	$(PERL) $< > $@
data/calendar/era-transitions.json: bin/calendar-era-transitions-1.pl \
    local/era-transitions-0.json
	$(PERL) $< > $@

local/calendar-era-relations-0.json: bin/calendar-era-relations.pl \
    local/calendar-era-defs-0.json \
    local/calendar-era-labels-0.json \
    data/calendar/era-transitions.json
	$(PERL) $< > $@
local/calendar-era-relations-1.json: bin/calendar-era-relations-1.pl \
    data/calendar/era-defs.json
	$(PERL) $< > $@
data/calendar/era-relations.json: bin/cleanup.pl \
    local/calendar-era-relations-1.json
	$(PERL) $< local/calendar-era-relations-1.json > $@

data/calendar/era-stats.json: bin/calendar-era-stats.pl \
    local/char-leaders.dat \
    data/calendar/era-defs.json \
    local/calendar-era-labels-0.json
	$(PERL) $< > $@

local/chars-maps.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-chars/master/data/maps.json
local/char-leaders.jsonl:
	$(WGET) -O $@ https://manakai.github.io/data-chars/local/generated/charrels/hans/char-leaders.jsonl
local/char-cluster.jsonl:
	$(WGET) -O $@ https://manakai.github.io/data-chars/local/generated/charrels/hans/char-cluster.jsonl
local/merged-index.json:
	$(WGET) -O $@ https://manakai.github.io/data-chars/local/generated/charrels/hans/merged-index.json

local/char-leaders.dat: bin/char-leaders-dump.pl \
    local/merged-index.json local/char-leaders.jsonl
	$(PERL) $<

local/eras/all: \
    local/eras/jp.txt \
    local/eras/jp-south.txt \
    local/eras/jp-north.txt \
    local/eras/jp-heishi.txt \
    local/eras/jp-kyoto.txt \
    local/eras/jp-east.txt
	touch $@
local/eras/jp.txt: bin/extract-era-transitions.pl \
    data/calendar/era-defs.json \
    data/calendar/era-transitions.json \
    data/tags.json
	mkdir -p local/eras
	echo '*jp:\n+$$DEF-jp\n$$DEF-jp:' > $@
	TAGS_INCLUDED=日本南朝 $(PERL) $< 神武天皇 >> $@
local/eras/jp-south.txt: bin/extract-era-transitions.pl \
    data/calendar/era-defs.json \
    data/calendar/era-transitions.json \
    data/tags.json
	mkdir -p local/eras
	echo '*jp-south:\n+$$DEF-jp-south\n$$DEF-jp-south:' > $@
	TAGS_INCLUDED=日本南朝 $(PERL) $< 神武天皇 >> $@
local/eras/jp-north.txt: bin/extract-era-transitions.pl \
    data/calendar/era-defs.json \
    data/calendar/era-transitions.json \
    data/tags.json
	mkdir -p local/eras
	echo '*jp-north:\n+$$DEF-jp-north\n$$DEF-jp-north:' > $@
	TAGS_INCLUDED=日本北朝 TAGS_EXCLUDED=日本南朝 $(PERL) $< 神武天皇 >> $@
local/eras/jp-heishi.txt: bin/extract-era-transitions.pl \
    data/calendar/era-defs.json \
    data/calendar/era-transitions.json \
    data/tags.json
	mkdir -p local/eras
	echo '*jp-heishi:\n+$$DEF-jp-heishi\n$$DEF-jp-heishi:' > $@
	TAGS_INCLUDED=平氏,日本南朝 $(PERL) $< 神武天皇 >> $@
local/eras/jp-kyoto.txt: bin/extract-era-transitions.pl \
    data/calendar/era-defs.json \
    data/calendar/era-transitions.json \
    data/tags.json
	mkdir -p local/eras
	echo '*jp-kyoto:\n+$$DEF-jp-kyoto\n$$DEF-jp-kyoto:' > $@
	TAGS_INCLUDED=京都 TAGS_EXCLUDED=日本南朝 $(PERL) $< 神武天皇 >> $@
local/eras/jp-east.txt: bin/extract-era-transitions.pl \
    data/calendar/era-defs.json \
    data/calendar/era-transitions.json \
    data/tags.json
	mkdir -p local/eras
	echo '*jp-east:\n+$$DEF-jp-east\n$$DEF-jp-east:' > $@
	TAGS_INCLUDED=関東 TAGS_EXCLUDED=日本南朝,南那須町,自由民権運動,異説発生 $(PERL) $< 神武天皇 >> $@
data/calendar/era-systems.json: bin/calendar-era-systems.pl \
    src/eras/*.txt data/calendar/kyuureki-map.txt \
    data/calendar/kyuureki-ryuukyuu-map.txt \
    local/eras/all
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

data/calendar/dts.json: bin/calendar-dts.pl \
    local/dtsjp1.json local/dtsjp2.json local/dtsjp3.json
	$(PERL) $< > $@
local/dtsjp1.json: bin/calendar-dts-jp.pl \
    data/calendar/era-defs.json data/calendar/era-systems.json
	$(PERL) $< dtsjp1 > $@
local/dtsjp2.json: bin/calendar-dts-jp.pl \
    data/calendar/era-defs.json data/calendar/era-systems.json
	$(PERL) $< dtsjp2 > $@
local/dtsjp3.json: bin/calendar-dts-jp.pl \
    data/calendar/era-defs.json data/calendar/era-systems.json
	$(PERL) $< dtsjp3 > $@
data/calendar/serialized/dtsjp1.txt: bin/calendar-serialize-dts.pl \
    data/calendar/dts.json
	$(PERL) $< dtsjp1 > $@
data/calendar/serialized/dtsjp2.txt: bin/calendar-serialize-dts.pl \
    data/calendar/dts.json
	$(PERL) $< dtsjp2 > $@
data/calendar/serialized/dtsjp3.txt: bin/calendar-serialize-dts.pl \
    data/calendar/dts.json
	$(PERL) $< dtsjp3 > $@

local/era-chars.json: bin/generate-era-chars.pl \
    data/calendar/era-defs.json
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
local/cldr-locales.txt: local/cldr-repo always
	ls local/cldr-repo/common/main/*.xml | \
	perl -e 'while (<>) { if (/\/([0-9a-zA-Z_]+)\.xml/) { print "$$1\n" } }' > $@
local/fx-locales.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-web-impls/staging/data/firefox-locales.json
local/mediawiki-locales.php:
	$(WGET) -O $@ https://raw.githubusercontent.com/wikimedia/mediawiki/master/includes/languages/data/Names.php
local/mediawiki-locales.txt: local/mediawiki-locales.php
	perl -e 'local $$/ = undef; $$x = <>; $$x =~ s{/\*.*?\*/}{}gs; $$x =~ s{#.*\n}{\n}g; $$q = chr 0x27; while ($$x =~ /$$q([a-z0-9-]+)$$q\s*=>/g) { print "$$1\n" }' < $< > $@

local/cldr-repo: always
	$(GIT) clone --depth 1 https://github.com/unicode-org/cldr $@ || true
	cd local/cldr-repo && $(GIT) pull
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

local/cldr-plurals.xml: local/cldr-repo
	cp local/cldr-repo/common/supplemental/plurals.xml $@
local/cldr-plurals-ordinals.xml: local/cldr-repo
	cp local/cldr-repo/common/supplemental/ordinals.xml $@
local/cldr-plurals.json: \
  local/cldr-plurals.xml local/cldr-plurals-ordinals.xml \
  bin/parse-cldr-plurals.pl
	$(PERL) bin/parse-cldr-plurals.pl > $@

data/langs/plurals.json: bin/langs-plurals.pl src/plural-exprs.txt \
  src/plural-additional.txt local/cldr-plurals.json
	$(PERL) $< > $@

data/numbers/kanshi.json: bin/numbers-kanshi.pl
	$(PERL) $< > $@

## ------ Language tags ------

all-langtags: data/langs/langtags.json
clean-langtags:
	rm -f local/langtags/subtag-registry local/langtags/ext-registry
	rm -f local/langtags/cldr-bcp47/update
	rm -fr local/chars-*.json

local/langtags/subtag-registry:
	mkdir -p local/langtags
	$(WGET) https://www.iana.org/assignments/language-subtag-registry -O $@
local/langtags/ext-registry:
	mkdir -p local/langtags
	$(WGET) https://www.iana.org/assignments/language-tag-extensions-registry -O $@

local/chars-scripts.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-chars/master/data/scripts.json

data/langs/langtags.json: bin/langs-langtags.pl \
  local/langtags/subtag-registry local/langtags/ext-registry \
  local/chars-scripts.json \
  local/cldr-repo
	$(PERL) $< \
	  local/langtags/subtag-registry local/langtags/ext-registry \
	  local/cldr-repo/common/bcp47/*.xml > $@

intermediate/variants.json: data/calendar/era-stats.json always
	cd intermediate && $(MAKE) variants.json

view: always
	cd view && $(MAKE) all

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
