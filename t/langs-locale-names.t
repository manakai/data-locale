#!/bin/sh
echo "1..11"
basedir=`dirname $0`/..
jq=$basedir/local/bin/jq

test() {
  (cat $basedir/data/langs/locale-names.json | $jq "$2" | sh && echo "ok $1") || echo "not ok $1"
}

test 1 '.tags.en.cldr == "en"'
test 2 '.tags["en-gb"].ms == "2057"'
test 3 '.tags["en-za"].firefox == "en-ZA"'
test 4 '.tags.und.cldr == "root"'
test 5 '.tags["ja-jp-u-ca-japanese"].java == "ja_JP_JP"'
test 6 '.tags["zh-hk"].mediawiki | not | not'
test 7 '.countryless_tags["ja-jp"] == "ja"'
test 8 '.countryless_tags["pt-pt"] == "pt"'
test 9 '.countryless_tags["en-us"] == "en"'
test 10 '.countryless_tags["zh-cn"] | not'
test 11 '.countryless_tags["en-gb"] | not'
