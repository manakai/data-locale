ROOT_PATH = ../
DATA_PATH = $(ROOT_PATH)/data

PERL = $(ROOT_PATH)/perl

all: era-names.html era-yomis.html era-kanjions.html \
    era-relations.html \
    era-transitions.html \
    era-transition-sequences-all

era-transition-sequences-all:
	cd era-transition-sequences && $(MAKE) all

era-names.html: era-names.pl $(DATA_PATH)/calendar/era-defs.json \
    $(ROOT_PATH)/local/calendar-era-labels-0.json
	$(PERL) $< > $@

era-yomis.html: era-yomis.pl $(DATA_PATH)/calendar/era-yomi-sources.json
	$(PERL) $< > $@

era-kanjions.html: era-kanjions.pl \
    $(ROOT_PATH)/local/calendar-era-labels-0.json
	$(PERL) $< > $@

era-relations.html: era-relations.pl \
    $(DATA_PATH)/calendar/era-defs.json \
    $(ROOT_PATH)/local/calendar-era-relations-0.json
	$(PERL) $< > $@

era-transitions.html: era-transitions.pl \
    $(DATA_PATH)/calendar/era-defs.json \
    $(DATA_PATH)/calendar/era-transitions.json \
    $(DATA_PATH)/tags.json
	$(PERL) $< > $@

$(DATA_PATH)/calendar/era-defs.json: always
	cd $(ROOT_PATH) && $(MAKE) data/calendar/era-defs.json
$(DATA_PATH)/calendar/era-yomi-sources.json: always
	cd $(ROOT_PATH) && $(MAKE) data/calendar/era-yomi-sources.json
$(ROOT_PATH)/local/calendar-era-defs-0.json: always
	cd $(ROOT_PATH) && $(MAKE) local/calendar-era-defs-0.json
$(ROOT_PATH)/local/calendar-era-relations-0.json: always
	cd $(ROOT_PATH) && $(MAKE) local/calendar-era-relations-0.json
$(ROOT_PATH)/local/calendar-era-labels-0.json: always
	cd $(ROOT_PATH) && $(MAKE) local/calendar-era-labels-0.json
$(DATA_PATH)/calendar/era-transitions.json: always
	cd $(ROOT_PATH) && $(MAKE) data/calendar/era-transitions.json

always:

## License: Public Domain.
