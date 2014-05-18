use strict;
use warnings;
use utf8;
use JSON::PS;

my $Data = {};

sub set ($$) {
  for (0..$#{$_[0]}) {
    $Data->{months}->[$_]->{$_[1]} = $_[0]->[$_];
  }
} # set

set [1..12] => 'iso_number';
set [qw[
  January February March April May June July August September October
  November December
]] => 'iso_name';
set [map { $_ . q[月] } 1..12] => 'jis_name';
set [qw[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]] => 'abbr_3';
set [qw[
  一月 二月 三月 四月 五月 六月 七月 八月 九月 十月 十一月 十二月
]] => 'jp_name';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
