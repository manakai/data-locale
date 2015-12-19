use strict;
use warnings;
use utf8;
use JSON::PS;

my $Data = {};

for my $year (1616..1872) {
  $Data->{sprintf '%04d-%02d-%02d', $year, 1, 1} = '歳首';
  $Data->{sprintf '%04d-%02d-%02d', $year, 1, 15} = '小正月';
  $Data->{sprintf '%04d-%02d-%02d', $year, 7, 15} = '盆';
}

for my $year (1616..1872) {
  $Data->{sprintf '%04d-%02d-%02d', $year, 1, 7} = '人日';
  $Data->{sprintf '%04d-%02d-%02d', $year, 3, 3} = '上巳';
  $Data->{sprintf '%04d-%02d-%02d', $year, 5, 5} = '端午';
  $Data->{sprintf '%04d-%02d-%02d', $year, 7, 7} = '七夕';
  $Data->{sprintf '%04d-%02d-%02d', $year, 8, 1} = '八朔';
  $Data->{sprintf '%04d-%02d-%02d', $year, 9, 9} = '重陽';
}

for my $year (1868..1872) {
  $Data->{sprintf '%04d-%02d-%02d', $year, 9, 22} = '紀元節';
}
for my $year (1870..1872) {
  $Data->{sprintf '%04d-%02d-%02d', $year, 3, 11} = '神武天皇祭';
}

for my $year (1868..1872) {
  for my $month (1..12) {
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 1} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 6} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 11} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 16} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 21} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 26} ||= '一六日';
  }
  for my $month (
    ($year == 1868 ? 4 : ()),
    ($year == 1870 ? 10 : ()),
  ) {
    $Data->{sprintf '%04d-%02d\'-%02d', $year, $month, 1} ||= '一六日';
    $Data->{sprintf '%04d-%02d\'-%02d', $year, $month, 6} ||= '一六日';
    $Data->{sprintf '%04d-%02d\'-%02d', $year, $month, 11} ||= '一六日';
    $Data->{sprintf '%04d-%02d\'-%02d', $year, $month, 16} ||= '一六日';
    $Data->{sprintf '%04d-%02d\'-%02d', $year, $month, 21} ||= '一六日';
    $Data->{sprintf '%04d-%02d\'-%02d', $year, $month, 26} ||= '一六日';
  }
}
#delete $Data->{'1868-01-01'};
delete $Data->{'1868-01-06'};
delete $Data->{'1868-01-11'};
delete $Data->{'1868-01-16'};
delete $Data->{'1868-09-21'};
delete $Data->{'1873-12-26'};
delete $Data->{'1872-12-06'};
delete $Data->{'1872-12-11'};
delete $Data->{'1872-12-16'};
delete $Data->{'1872-12-21'};
delete $Data->{'1872-12-26'};

print perl2json_bytes_for_record $Data;

## License: Public Domain.
