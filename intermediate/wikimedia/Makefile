ROOT_PATH = ../..
DATA_PATH = $(ROOT_PATH)/data
BIN_PATH = $(ROOT_PATH)/bin
TEMP_PATH = $(ROOT_PATH)/local/wikimedia

PERL = $(ROOT_PATH)/perl \
    -I$(ROOT_PATH)/bin/modules/json-ps/lib  \
    -I$(ROOT_PATH)/bin/modules/web-encodings/lib 

WGET = wget

all: $(TEMP_PATH) \
    wp-cn-eras.json wp-vn-eras.json wp-tw-eras.json \
    wp-mn-eras.json wp-kr-eras.json wp-jp-eras.json wp-jpp-eras.json \
    wp-vi-cn-eras.json wp-vi-vn-eras.json wp-vi-jp-eras.json \
    wp-vi-kr-eras.json \
    wp-ko-cn-eras.json wp-ko-vn-eras.json wp-ko-jp-eras.json \
    wp-ko-mn-eras.json wp-ko-kr-eras.json wp-ko-krr-eras.json \
    wp-en-cn-eras.json wp-en-vn-eras.json wp-en-jp-eras.json \
    wp-en-kr-eras.json \
    shiki \
    k3 \
    kourai

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

$(TEMP_PATH)/wp-vi-cn-eras.html:
	$(WGET) -O $@ https://vi.wikipedia.org/wiki/Ni%C3%AAn_hi%E1%BB%87u_Trung_Qu%E1%BB%91c
$(TEMP_PATH)/wp-vi-vn-eras.html:
	$(WGET) -O $@ https://vi.wikipedia.org/wiki/Ni%C3%AAn_hi%E1%BB%87u_Vi%E1%BB%87t_Nam
$(TEMP_PATH)/wp-vi-jp-eras.html:
	$(WGET) -O $@ https://vi.wikipedia.org/wiki/Ni%C3%AAn_hi%E1%BB%87u_Nh%E1%BA%ADt_B%E1%BA%A3n
$(TEMP_PATH)/wp-vi-kr-eras.html:
	$(WGET) -O $@ https://vi.wikipedia.org/wiki/Ni%C3%AAn_hi%E1%BB%87u_Tri%E1%BB%81u_Ti%C3%AAn

$(TEMP_PATH)/wp-ko-kr-eras.html:
	$(WGET) -O $@ https://ko.wikipedia.org/wiki/%ED%95%9C%EA%B5%AD%EC%9D%98_%EC%97%B0%ED%98%B8
$(TEMP_PATH)/wp-ko-krr-eras.html:
	$(WGET) -O $@ https://ko.wikipedia.org/wiki/%EC%A1%B0%EC%84%A0%EC%9D%98_%EC%97%B0%ED%98%B8
$(TEMP_PATH)/wp-ko-mn-eras.html:
	$(WGET) -O $@ https://ko.wikipedia.org/wiki/%EB%AA%BD%EA%B3%A8%EC%9D%98_%EC%97%B0%ED%98%B8
$(TEMP_PATH)/wp-ko-cn-eras.html:
	$(WGET) -O $@ https://ko.wikipedia.org/wiki/%EC%A4%91%EA%B5%AD%EC%9D%98_%EC%97%B0%ED%98%B8_%EB%AA%A9%EB%A1%9D
$(TEMP_PATH)/wp-ko-jp-eras.html:
	$(WGET) -O $@ https://ko.wikipedia.org/wiki/%EC%9D%BC%EB%B3%B8%EC%9D%98_%EC%97%B0%ED%98%B8
$(TEMP_PATH)/wp-ko-vn-eras.html:
	$(WGET) -O $@ https://ko.wikipedia.org/wiki/%EB%B2%A0%ED%8A%B8%EB%82%A8%EC%9D%98_%EC%97%B0%ED%98%B8

$(TEMP_PATH)/wp-en-cn-eras.html:
	$(WGET) -O $@ https://en.wikipedia.org/wiki/List_of_Chinese_era_names
$(TEMP_PATH)/wp-en-vn-eras.html:
	$(WGET) -O $@ https://en.wikipedia.org/wiki/Vietnamese_era_name
$(TEMP_PATH)/wp-en-kr-eras.html:
	$(WGET) -O $@ https://en.wikipedia.org/wiki/Korean_era_name
$(TEMP_PATH)/wp-en-jp-eras.html:
	$(WGET) -O $@ https://en.wikipedia.org/wiki/Japanese_era_name

$(TEMP_PATH)/wp-vi-cn-eras.json \
$(TEMP_PATH)/wp-vi-vn-eras.json \
$(TEMP_PATH)/wp-vi-jp-eras.json \
$(TEMP_PATH)/wp-vi-kr-eras.json: \
$(TEMP_PATH)/wp-vi-%.json: parse-wp-vi.pl $(TEMP_PATH)/wp-vi-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-vi-$*.html > $@

$(TEMP_PATH)/wp-ko-cn-eras.json \
$(TEMP_PATH)/wp-ko-vn-eras.json \
$(TEMP_PATH)/wp-ko-jp-eras.json \
$(TEMP_PATH)/wp-ko-mn-eras.json \
$(TEMP_PATH)/wp-ko-kr-eras.json \
$(TEMP_PATH)/wp-ko-krr-eras.json: \
$(TEMP_PATH)/wp-ko-%.json: parse-wp-ko.pl $(TEMP_PATH)/wp-ko-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-ko-$*.html > $@

$(TEMP_PATH)/wp-en-cn-eras.json \
$(TEMP_PATH)/wp-en-vn-eras.json \
$(TEMP_PATH)/wp-en-jp-eras.json \
$(TEMP_PATH)/wp-en-kr-eras.json: \
$(TEMP_PATH)/wp-en-%.json: parse-wp-en.pl $(TEMP_PATH)/wp-en-%.html
	$(PERL) $< < $(TEMP_PATH)/wp-en-$*.html > $@

wp-vi-cn-eras.json wp-vi-vn-eras.json \
wp-vi-jp-eras.json wp-vi-kr-eras.json: wp-vi-%.json: \
    $(BIN_PATH)/fill-era-ids.pl \
    $(TEMP_PATH)/wp-vi-%.json \
    $(ROOT_PATH)/local/old-ced.json era-id-map.txt
	$(PERL) $< $(TEMP_PATH)/wp-vi-$*.json > $@

wp-ko-cn-eras.json wp-ko-vn-eras.json \
wp-ko-jp-eras.json wp-ko-mn-eras.json \
wp-ko-kr-eras.json wp-ko-krr-eras.json: wp-ko-%.json: \
    $(BIN_PATH)/fill-era-ids.pl \
    $(TEMP_PATH)/wp-ko-%.json \
    $(ROOT_PATH)/local/old-ced.json era-id-map.txt
	$(PERL) $< $(TEMP_PATH)/wp-ko-$*.json > $@

wp-en-cn-eras.json wp-en-vn-eras.json \
wp-en-jp-eras.json wp-en-kr-eras.json: wp-en-%.json: \
    $(BIN_PATH)/fill-era-ids.pl \
    $(TEMP_PATH)/wp-en-%.json \
    $(ROOT_PATH)/local/old-ced.json era-id-map.txt
	$(PERL) $< $(TEMP_PATH)/wp-en-$*.json > $@

shiki: \
    era-data-table2.txt \
    era-data-table3.txt \
    era-data-table5.txt \
    era-data-table6.txt \
    era-data-table7.txt \
    era-data-table8.txt \
    era-data-table9.txt

$(TEMP_PATH)/table2.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E5%8D%B7014?action=edit&veswitched=1"
$(TEMP_PATH)/table3.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E5%8D%B7015?action=edit&veswitched=1"
$(TEMP_PATH)/table5.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E5%8D%B7017?action=edit&veswitched=1"
$(TEMP_PATH)/table6.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E9%AB%98%E7%A5%96%E5%8A%9F%E8%87%A3%E4%BE%AF%E8%80%85%E5%B9%B4%E8%A1%A8?action=edit&veswitched=1"
$(TEMP_PATH)/table7.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E6%83%A0%E6%99%AF%E9%96%92%E7%9F%A6%E8%80%85%E5%B9%B4%E8%A1%A8?action=edit&veswitched=1"
$(TEMP_PATH)/table8.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E5%8D%B7020?action=edit&veswitched=1"
$(TEMP_PATH)/table9.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E5%8D%B7021?action=edit&veswitched=1"

table2.json: parse-table.pl $(TEMP_PATH)/table2.html
	$(PERL) $< table2 $(TEMP_PATH)/table2.html > $@
table3.json: parse-table.pl $(TEMP_PATH)/table3.html
	$(PERL) $< table3 $(TEMP_PATH)/table3.html > $@
table5.json: parse-table.pl $(TEMP_PATH)/table5.html
	$(PERL) $< table5 $(TEMP_PATH)/table5.html > $@
table6.json: parse-table.pl $(TEMP_PATH)/table6.html
	$(PERL) $< table6 $(TEMP_PATH)/table6.html > $@
table7.json: parse-table.pl $(TEMP_PATH)/table7.html
	$(PERL) $< table7 $(TEMP_PATH)/table7.html > $@
table8.json: parse-table.pl $(TEMP_PATH)/table8.html
	$(PERL) $< table8 $(TEMP_PATH)/table8.html > $@
table9.json: parse-table.pl $(TEMP_PATH)/table9.html
	$(PERL) $< table9 $(TEMP_PATH)/table9.html > $@

eras-table2.json: read-table.pl table2.json
	$(PERL) $< table2.json > $@
eras-table3.json: read-table.pl table3.json
	$(PERL) $< table3.json > $@
eras-table5.json: read-table.pl table5.json
	$(PERL) $< table5.json > $@
eras-table6.json: read-table6.pl table6.json
	$(PERL) $< table6.json > $@
eras-table7.json: read-table6.pl table7.json
	$(PERL) $< table7.json > $@
eras-table8.json: read-table6.pl table8.json
	$(PERL) $< table8.json > $@
eras-table9.json: read-table6.pl table9.json
	$(PERL) $< table9.json > $@

era-data-table2.txt: create-era-data.pl eras-table2.json
	$(PERL) $< eras-table2.json > $@
era-data-table3.txt: create-era-data.pl eras-table3.json
	$(PERL) $< eras-table3.json > $@
era-data-table5.txt: create-era-data.pl eras-table5.json
	$(PERL) $< eras-table5.json > $@
era-data-table6.txt: create-era-data.pl eras-table6.json
	$(PERL) $< eras-table6.json > $@
era-data-table7.txt: create-era-data.pl eras-table7.json
	$(PERL) $< eras-table7.json > $@
era-data-table8.txt: create-era-data.pl eras-table8.json
	$(PERL) $< eras-table8.json > $@
era-data-table9.txt: create-era-data.pl eras-table9.json
	$(PERL) $< eras-table9.json > $@

k3: era-list-k3china.txt era-data-k3.txt

$(TEMP_PATH)/k3table1.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E4%B8%89%E5%9C%8B%E5%8F%B2%E8%A8%98/%E5%8D%B729?action=edit&veswitched=1"
$(TEMP_PATH)/k3table2.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E4%B8%89%E5%9C%8B%E5%8F%B2%E8%A8%98/%E5%8D%B730?action=edit&veswitched=1"
$(TEMP_PATH)/k3table3.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E4%B8%89%E5%9C%8B%E5%8F%B2%E8%A8%98/%E5%8D%B731?action=edit&veswitched=1"
$(TEMP_PATH)/kouraitable1.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E9%AB%98%E9%BA%97%E5%8F%B2/%E5%8D%B7%E5%85%AB%E5%8D%81%E5%85%AD?action=edit&veswitched=1"
$(TEMP_PATH)/kouraitable2.html:
	$(WGET) -O $@ "https://zh.wikisource.org/wiki/%E9%AB%98%E9%BA%97%E5%8F%B2/%E5%8D%B7%E5%85%AB%E5%8D%81%E4%B8%83?action=edit&veswitched=1"
k3table1.json: parse-table.pl $(TEMP_PATH)/k3table1.html
	$(PERL) $< k3table1 $(TEMP_PATH)/k3table1.html > $@
k3table2.json: parse-table.pl $(TEMP_PATH)/k3table2.html
	$(PERL) $< k3table2 $(TEMP_PATH)/k3table2.html > $@
k3table3.json: parse-table.pl $(TEMP_PATH)/k3table3.html
	$(PERL) $< k3table3 $(TEMP_PATH)/k3table3.html > $@
kouraitable1.json: parse-table.pl $(TEMP_PATH)/kouraitable1.html
	$(PERL) $< kouraitable1 $(TEMP_PATH)/kouraitable1.html > $@
kouraitable2.json: parse-table.pl $(TEMP_PATH)/kouraitable2.html
	$(PERL) $< kouraitable2 $(TEMP_PATH)/kouraitable2.html > $@

era-list-k3china.txt: k3-china.pl k3table1.json k3table2.json k3table3.json
	$(PERL) $< > $@
eras-k3.json: k3-korea.pl k3table1.json k3table2.json k3table3.json
	$(PERL) $< > $@
era-data-k3.txt: create-era-data.pl eras-k3.json
	$(PERL) $< eras-k3.json > $@

kourai: era-list-kouraichina.txt era-data-kourai.txt

era-list-kouraichina.txt: kourai-china.pl kouraitable1.json kouraitable2.json
	$(PERL) $< > $@
eras-kourai.json: kourai-korea.pl kouraitable1.json kouraitable2.json
	$(PERL) $< > $@
era-data-kourai.txt: create-era-data.pl eras-kourai.json
	$(PERL) $< eras-kourai.json > $@

## License: Public Domain.
