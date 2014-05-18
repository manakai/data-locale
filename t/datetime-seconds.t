#!/bin/sh
echo "1..2"
basedir=`dirname $0`/..
jq=$basedir/local/bin/jq

test() {
  (cat $basedir/data/datetime/seconds.json | $jq "$2" | sh && echo "ok $1") || echo "not ok $1"
}

test 1 '.positive_leap_seconds["1972-06-30T23:59:60Z"].next_unix == 78796800'
test 2 '.positive_leap_seconds["2012-06-30T23:59:60Z"].prev_unix == 1341100799'
