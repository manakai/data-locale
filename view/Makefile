ROOT_PATH = ../
DATA_PATH = $(ROOT_PATH)/data

PERL = $(ROOT_PATH)/perl

all: era-names.html era-yomis.html

era-names.html: era-names.pl $(DATA_PATH)/calendar/era-defs.json
	$(PERL) $< > $@

era-yomis.html: era-yomis.pl $(DATA_PATH)/calendar/era-yomi-sources.json
	$(PERL) $< > $@

$(DATA_PATH)/calendar/era-defs.json: always
	cd $(ROOT_PATH) && $(MAKE) data/calendar/era-defs.json
$(DATA_PATH)/calendar/era-yomi-sources.json: always
	cd $(ROOT_PATH) && $(MAKE) data/calendar/era-yomi-sources.json

always:

## License: Public Domain.
