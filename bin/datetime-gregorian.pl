use strict;
use warnings;
use JSON::PS;

my $Data = {};

## <http://www.whatwg.org/specs/web-apps/current-work/#number-of-days-in-month-month-of-year-year>
$Data->{month_days}->[$_ - 1] = 31
    for 1, 3, 5, 7, 8, 10, 12;
$Data->{month_days}->[$_ - 1] = 30
    for 4, 6, 9, 11;
$Data->{month_days}->[$_ - 1] = 29 # or 28
    for 2;

print perl2json_bytes_for_record $Data;

## License: Public Domain.
