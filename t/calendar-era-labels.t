#!/bin/sh
echo "1..4"
basedir=`dirname $0`/..
jq=$basedir/local/bin/jq

test() {
  (cat $basedir/data/calendar/era-labels.json | $jq "$2" | sh && echo "ok $1") || echo "not ok $1"
}

test 1 '.eras["3"].label_sets[0].labels[0].form_groups[0].form_sets[2].hiragana[0] == "しょう"'
test 2 '.eras["3"].label_sets[0].labels[0].form_groups[0].form_sets[2].hiragana_modern[1] == "わ"'
test 3 '.eras["3"].label_sets[0].labels[0].form_groups[0].form_sets[2].hiragana_classic[0] == "せう"'
test 4 '.eras["3"].label_sets[0].labels[0].form_groups[0].form_sets[2].latin[0] == "sho"'

## License: Public Domain.
