use strict;
use warnings;
use utf8;
use JSON::PS;

my $Data = {};

sub set ($$) {
  for (0..$#{$_[0]}) {
    $Data->{weekday}->[$_]->{$_[1]} = $_[0]->[$_];
  }
} # set

set [7, 1..6] => 'iso_number';
set [qw[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]]
    => 'iso_name';
set [qw[日曜日 月曜日 火曜日 水曜日 木曜日 金曜日 土曜日]] => 'jis_name';
set [qw[Su Mo Tu We Th Fr Sa]] => 'abbr_2';
set [qw[Sun Mon Tue Wed Thu Fri Sat]] => 'abbr_3';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
