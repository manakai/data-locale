use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $json_path = $root_path->child ('src/wp-jp-eras.json');
my $json = json_bytes2perl $json_path->slurp;

use POSIX;
sub j2g ($$$) {
  my ($jy, $jm, $jd) = @_;
  my $y = $jy + floor (($jm - 3) / 12);
  my $m = ($jm - 3) % 12;
  my $d = $jd - 1;
  my $n = $d + floor ((153 * $m + 2) / 5) + 365 * $y + floor ($y / 4);
  my $mjd = $n - 678883;
  my $time = ($mjd + 2400000.5 - 2440587.5) * 24 * 60 * 60;
  my @time = gmtime $time;
  return ($time[5]+1900, $time[4]+1, $time[3]);
} # j2g

my $Data = {};

for (@{$json->{tables}}) {
  for (@$_) {
    my ($name, $read, $start, $end, $years, $emperor, $note) = @$_;
    next if {'－' => 1, 元号名 => 1, 漢字 => 1, '　漢字　' => 1}->{$name};
    next if $name eq $read;
    my $data = $Data->{$name} ||= {};
    $data->{name} = $name;
    $data->{name_kana} ||= $read;
    $data->{name_kanas}->{$read} = 1;
    if ($start =~ m{^\w+(?:\d+|元)年閏?\d+月(?:\d+日|)(?:\s*\[[0-9]+\]|)\s*（(\d+)年(\d+)月(?:(\d+)日|)）(?:\s*\[[0-9]+\]|)$}) {
      my ($y, $m, $d) = ($1, $2, $3 || 1);
      if ($1 < 1582) {
        ($y, $m, $d) = j2g ($y, $m, $d);
      }
      $data->{start} = sprintf '%04d-%02d-%02d', $y, $m, $d;
    } elsif ($start =~ m{^\w+(?:\d+|元)年（(\d+)年）\s*(\d+)月(?:(\d+)日|)(?:\s*\[[0-9]+\]|)$}) {
      my ($y, $m, $d) = ($1, $2, $3 || 1);
      if ($1 < 1582) {
        ($y, $m, $d) = j2g ($y, $m, $d);
      }
      $data->{start} = sprintf '%04d-%02d-%02d', $y, $m, $d;
    } else {
      die "Bad start |$start|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
