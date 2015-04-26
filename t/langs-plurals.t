#!/bin/sh
echo "1..2"
basedir=`dirname $0`/..
jq=$basedir/local/bin/jq

test() {
  (cat $basedir/data/langs/plurals.json | $jq "$2" | sh && echo "ok $1") || echo "not ok $1"
}

test 1 '.forms["ends in 01"].examples == "1 101 201 301 401 501 601 701 801 901"'
test 2 '.rules["2:is 1/everything else"].cldr_locales.cardinal.en | not | not'