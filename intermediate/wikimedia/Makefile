ROOT_PATH = ../..
DATA_PATH = $(ROOT_PATH)/data
BIN_PATH = $(ROOT_PATH)/bin
TEMP_PATH = $(ROOT_PATH)/local/wikimedia

PERL = $(ROOT_PATH)/perl

WGET = wget

all: $(TEMP_PATH) ../wp-cn-eras.json \
    wp-cn-eras.json wp-vn-eras.json wp-tw-eras.json \
    wp-mn-eras.json wp-kr-eras.json wp-jp-eras.json wp-jpp-eras.json

$(TEMP_PATH):
	mkdir -p $@

WP_FILES = \
    $(TEMP_PATH)/wp-KEY-tw.json \
    $(TEMP_PATH)/wp-KEY-cn.json \
    $(TEMP_PATH)/wp-KEY-hk.json \
    $(TEMP_PATH)/wp-KEY-mo.json \
    $(TEMP_PATH)/wp-KEY-my.json \
    $(TEMP_PATH)/wp-KEY-sg.json

$(subst json,html,$(subst KEY,cn-eras,$(WP_FILES))): $(TEMP_PATH)/wp-cn-eras-%.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-$*/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
$(subst json,html,$(subst KEY,vn-eras,$(WP_FILES))): $(TEMP_PATH)/wp-vn-eras-%.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-$*/%E8%B6%8A%E5%8D%97%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
$(subst json,html,$(subst KEY,tw-eras,$(WP_FILES))): $(TEMP_PATH)/wp-tw-eras-%.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-$*/%E5%8F%B0%E7%81%A3%E5%B9%B4%E8%99%9F%E5%88%97%E8%A1%A8
$(subst json,html,$(subst KEY,mn-eras,$(WP_FILES))): $(TEMP_PATH)/wp-mn-eras-%.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-$*/%E8%92%99%E5%8F%A4%E5%B9%B4%E8%99%9F%E5%88%97%E8%A1%A8
$(subst json,html,$(subst KEY,kr-eras,$(WP_FILES))): $(TEMP_PATH)/wp-kr-eras-%.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-$*/%E6%9C%9D%E9%AE%AE%E5%8D%8A%E5%B3%B6%E5%B9%B4%E8%99%9F%E5%88%97%E8%A1%A8
$(subst json,html,$(subst KEY,jp-eras,$(WP_FILES))): $(TEMP_PATH)/wp-jp-eras-%.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-$*/%E6%97%A5%E6%9C%AC%E5%B9%B4%E8%99%9F%E5%88%97%E8%A1%A8
$(subst json,html,$(subst KEY,jpp-eras,$(WP_FILES))): $(TEMP_PATH)/wp-jpp-eras-%.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-$*/%E6%97%A5%E6%9C%AC%E7%A7%81%E5%B9%B4%E8%99%9F

$(subst KEY,cn-eras,$(WP_FILES)): $(TEMP_PATH)/wp-cn-eras-%.json: $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-cn-eras-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-cn-eras-$*.html > $@

$(subst KEY,vn-eras,$(WP_FILES)): $(TEMP_PATH)/wp-vn-eras-%.json: \
    $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-vn-eras-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-vn-eras-$*.html > $@
$(subst KEY,tw-eras,$(WP_FILES)): $(TEMP_PATH)/wp-tw-eras-%.json: \
    $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-tw-eras-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-tw-eras-$*.html > $@
$(subst KEY,mn-eras,$(WP_FILES)): $(TEMP_PATH)/wp-mn-eras-%.json: \
    $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-mn-eras-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-mn-eras-$*.html > $@
$(subst KEY,kr-eras,$(WP_FILES)): $(TEMP_PATH)/wp-kr-eras-%.json: \
    $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-kr-eras-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-kr-eras-$*.html > $@
$(subst KEY,jp-eras,$(WP_FILES)): $(TEMP_PATH)/wp-jp-eras-%.json: \
    $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-jp-eras-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-jp-eras-$*.html > $@
$(subst KEY,jpp-eras,$(WP_FILES)): $(TEMP_PATH)/wp-jpp-eras-%.json: \
    $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-jpp-eras-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-jpp-eras-$*.html > $@

#../wp-cn-eras.json: $(BIN_PATH)/merge-wp-cn-eras.pl \
#    $(subst KEY,cn-eras,$(WP_FILES)) \
#    $(ROOT_PATH)/src/wp-zh-era-id-map.txt
#	$(PERL) $< cn-eras > $@

$(TEMP_PATH)/wp-cn-eras-0.json \
$(TEMP_PATH)/wp-vn-eras-0.json $(TEMP_PATH)/wp-tw-eras-0.json \
$(TEMP_PATH)/wp-mn-eras-0.json $(TEMP_PATH)/wp-kr-eras-0.json \
$(TEMP_PATH)/wp-jp-eras-0.json $(TEMP_PATH)/wp-jpp-eras-0.json: \
$(TEMP_PATH)/wp-%-0.json: $(BIN_PATH)/merge-wp-cn-eras.pl \
    $(subst KEY,%,$(WP_FILES))
	$(PERL) $< $* > $@

wp-cn-eras.json \
wp-vn-eras.json wp-tw-eras.json wp-mn-eras.json wp-kr-eras.json \
wp-jp-eras.json wp-jpp-eras.json: wp-%.json: $(BIN_PATH)/fill-era-ids.pl \
    $(TEMP_PATH)/wp-%-0.json $(ROOT_PATH)/local/old-ced.json era-id-map.txt
	$(PERL) $< $(TEMP_PATH)/wp-$*-0.json > $@

$(ROOT_PATH)/local/old-ced.json:
	$(WGET) -O $@ https://raw.githubusercontent.com/manakai/data-locale/master/data/calendar/era-defs.json

## License: Public Domain.
