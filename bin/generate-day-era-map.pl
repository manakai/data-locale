use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
binmode STDOUT, ':encoding(utf-8)';

my $root_path = path (__FILE__)->parent->parent;
my $json_path = $root_path->child ('data/calendar/era-systems.json');
my $json = json_bytes2perl $json_path->slurp;

my $def_json_path = $root_path->child ('data/calendar/era-defs.json');
my $def_json = json_bytes2perl $def_json_path->slurp;

my $sys_name = shift or die "Usage: $0 name";
my $sys = $json->{systems}->{$sys_name}
    or die "Era system |$sys_name| not defined";
my $points = $sys->{points};

my $min_day = 1477809;
my $max_day = 2488109;

sub jd2g_ymd ($) {
  my @time = gmtime (($_[0] - 2440587.5) * 24 * 60 * 60);
  return undef unless defined $time[5];
  return ($time[5]+1900, $time[4]+1, $time[3]);
} # jd2g_ymd

my $point;
my $day = $min_day;
while ($day <= $max_day) {
  my ($year, $m, $d) = jd2g_ymd $day;
  while (@$points and
         (($points->[0]->[0] eq 'jd' and $points->[0]->[1] <= $day) or
          ($points->[0]->[0] eq 'y' and $points->[0]->[1] <= $year))) {
    $point = shift @$points;
  }
  my $g;
  if ($year < 0) {
    $g = sprintf '-%04d-%02d-%02d', -$year, $m, $d;
  } else {
    $g = sprintf '%04d-%02d-%02d', $year, $m, $d;
  }
  my $v;
  if (defined $point and defined $point->[2]) {
    my $def = $def_json->{eras}->{$point->[2]}
        or die "Bad era key |$point->[2]|";
    die "Era |$point->[2]| has no offset" if not defined $def->{offset};
    $v = $point->[2] . ' ' . ($year - $def->{offset});
  } else {
    $v = 'null';
  }
  print "$g\t$v\n";
  $day++;
}

## License: Public Domain.
