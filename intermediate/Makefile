ROOT_PATH = ../
DATA_PATH = $(ROOT_PATH)/data

PERL = $(ROOT_PATH)/perl

all: variants.json wikimedia-all

wikimedia-all:
	cd wikimedia && $(MAKE) all

variants.json: variants.pl \
    $(DATA_PATH)/calendar/era-stats.json \
    $(ROOT_PATH)/local/merged-index.json \
    $(ROOT_PATH)/local/char-leaders.jsonl
	$(PERL) $< > $@

$(ROOT_PATH)/local/merged-index.json:
	cd $(ROOT_PATH) && $(MAKE) local/merged-index.json
$(ROOT_PATH)/local/char-leaders.jsonl:
	cd $(ROOT_PATH) && $(MAKE) local/char-leaders.jsonl

$(DATA_PATH)/calendar/era-stats.json: always
	cd $(ROOT_PATH) && $(MAKE) data/calendar/era-stats.json

always:

## License: Public Domain.
