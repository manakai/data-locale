#!/bin/sh
echo "1..1"
basedir=`dirname $0`/..
jq=$basedir/local/bin/jq

test() {
  (cat $basedir/data/calendar/jp-holidays.json | $jq "$2" | sh && echo "ok $1") || echo "not ok $1"
}

test 1 '.["2014-10-13"] == "体育の日"'
