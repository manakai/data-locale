ROOT_PATH = ../../

PERL = $(ROOT_PATH)/perl

all: build

build: build.pl \
    $(ROOT_PATH)/bin/extract-era-transitions.pl \
    $(ROOT_PATH)/data/calendar/era-defs.json \
    $(ROOT_PATH)/data/calendar/era-transitions.json \
    $(ROOT_PATH)/data/tags.json
	$(PERL) build.pl

## License: Public Domain.
