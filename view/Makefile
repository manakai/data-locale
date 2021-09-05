ROOT_PATH = ../
DATA_PATH = $(ROOT_PATH)/data

PERL = $(ROOT_PATH)/perl

all: era-names.html

era-names.html: era-names.pl $(DATA_PATH)/calendar/era-defs.json
	$(PERL) $< > $@

## License: Public Domain.
