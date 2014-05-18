use strict;
use warnings;
use Time::Local qw(timegm);
use Path::Tiny;
use JSON::PS;

my $Data = {};

{
  my $epoch = timegm 0, 0, 0, 1, 1-1, 1900;

  my $path = path (__FILE__)->parent->parent->child ('local/leap-seconds.txt');
  for (split /\x0D?\x0A/, $path->slurp) {
    if (/^([0-9]+)\s+([0-9]+)\s+/) {
      my $s = $1;
      next if $s == 2272060800; ## Start of the UTC
      my $second1 = $s + $epoch - 1;
      my @time1 = gmtime $second1;
      my $ts1 = sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ',
          $time1[5]+1900, $time1[4]+1, $time1[3],
          $time1[2], $time1[1], $time1[0];
      my $ts0 = sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ',
          $time1[5]+1900, $time1[4]+1, $time1[3],
          $time1[2], $time1[1], $time1[0] + 1;
      my $second2 = $second1 + 1;
      my @time2 = gmtime $second2;
      my $ts2 = sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ',
          $time2[5]+1900, $time2[4]+1, $time2[3],
          $time2[2], $time2[1], $time2[0];
      $Data->{positive_leap_seconds}->{$ts0}
          = {prev => $ts1, prev_unix => $second1,
           next => $ts2, next_unix => $second2};
    }
  }
}

$Data->{negative_leap_seconds} = {};

print perl2json_bytes_for_record $Data;

## License: Public Domain.
