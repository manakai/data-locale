#!/bin/sh
echo "1..4"
basedir=`dirname $0`/..
jq=$basedir/local/bin/jq

test() {
  (cat $basedir/data/langs/locale-names.json | $jq "$2" | sh && echo "ok $1") || echo "not ok $1"
}

test 1 '.tags.en.cldr == "en"'
test 2 '.tags["en-gb"].ms == "2057"'
test 3 '.tags.und.cldr == "root"'
test 4 '.tags["ja-jp-u-ca-japanese"].java == "ja_JP_JP"'
