ROOT_PATH = ../../
DATA_PATH = $(ROOT_PATH)/data
BIN_PATH = $(ROOT_PATH)/bin
TEMP_PATH = $(ROOT_PATH)/local/wikimedia

PERL = $(ROOT_PATH)/perl

WGET = wget

all: ../wp-cn-eras.json

$(TEMP_PATH):
	mkdir -p $@

$(TEMP_PATH)/wp-cn-eras-tw.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-tw/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
$(TEMP_PATH)/wp-cn-eras-cn.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-cn/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
$(TEMP_PATH)/wp-cn-eras-hk.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-hk/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
$(TEMP_PATH)/wp-cn-eras-mo.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-mo/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
$(TEMP_PATH)/wp-cn-eras-my.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-my/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
$(TEMP_PATH)/wp-cn-eras-sg.html:
	$(WGET) -O $@ https://zh.wikipedia.org/zh-sg/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8
$(TEMP_PATH)/wp-cn-eras-tw.json: $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-cn-eras-tw.html
	$(PERL) $< < $(TEMP_PATH)/wp-cn-eras-tw.html > $@
$(TEMP_PATH)/wp-cn-eras-cn.json: $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-cn-eras-cn.html
	$(PERL) $< < $(TEMP_PATH)/wp-cn-eras-cn.html > $@
$(TEMP_PATH)/wp-cn-eras-hk.json: $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-cn-eras-hk.html
	$(PERL) $< < $(TEMP_PATH)/wp-cn-eras-hk.html > $@
$(TEMP_PATH)/wp-cn-eras-mo.json: $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-cn-eras-mo.html
	$(PERL) $< < $(TEMP_PATH)/wp-cn-eras-mo.html > $@
$(TEMP_PATH)/wp-cn-eras-my.json: $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-cn-eras-my.html
	$(PERL) $< < $(TEMP_PATH)/wp-cn-eras-my.html > $@
$(TEMP_PATH)/wp-cn-eras-sg.json: $(BIN_PATH)/parse-wp-cn-eras.pl $(TEMP_PATH)/wp-cn-eras-sg.html
	$(PERL) $< < $(TEMP_PATH)/wp-cn-eras-sg.html > $@

../wp-cn-eras.json: $(BIN_PATH)/merge-wp-cn-eras.pl \
    $(TEMP_PATH) \
    $(TEMP_PATH)/wp-cn-eras-tw.json \
    $(TEMP_PATH)/wp-cn-eras-cn.json \
    $(TEMP_PATH)/wp-cn-eras-hk.json \
    $(TEMP_PATH)/wp-cn-eras-mo.json \
    $(TEMP_PATH)/wp-cn-eras-my.json \
    $(TEMP_PATH)/wp-cn-eras-sg.json \
    $(ROOT_PATH)/src/wp-zh-era-id-map.txt
	$(PERL) $< > $@

## License: Public Domain.
