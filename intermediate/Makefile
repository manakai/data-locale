ROOT_PATH = ../
DATA_PATH = $(ROOT_PATH)/data

PERL = $(ROOT_PATH)/perl

all: variants.json

variants.json: variants.pl \
    $(DATA_PATH)/calendar/era-stats.json
	$(PERL) $< > $@

$(DATA_PATH)/calendar/era-stats.json: always
	cd $(ROOT_PATH) && $(MAKE) data/calendar/era-stats.json

always:

## License: Public Domain.
