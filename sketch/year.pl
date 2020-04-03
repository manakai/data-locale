use strict;
use warnings;

my $year = shift || 0;
my $base_year = shift || 0;

my $desc = {
  543 => 'BE alpha',
  544 => 'BE beta',
  949 => 'BE gamma',
  566 => 'BE delta',
  531 => 'BE epsilon',
  1027 => 'BE zeta',
  948 => 'BE eta',
  565 => 'BE theta',

  1028 => 'BE zeta-1',
  960 => 'BE gamma-11',
  950 => 'BE gamma-1',
  947 => 'BE gamma+2',
  567 => 'BE delta-1',
  532 => 'BE epsilon-1',
  536 => 'BE epsilon-5',
  545 => 'BE beta-1',
  554 => 'BE theta-9',
  
  941 => '(BE) eta+7',
  
  -1918 => 'ROK',
  2333 => 'Dangi',
  -1945 => 'AH-',
  -1946 => 'AH+',
  1793133 => 'Tenson',
};

sub to_thai ($) {
  use utf8;
  my $n = shift;
  $n =~ tr/0-9/๐๑๒๓๔๕๖๗๘๙/;
  return $n;
} # to_thai

sub to_ykanshi ($) {
  my $year = shift;
  use utf8;
  my $k = qw(庚 辛 壬 癸 甲 乙 丙 丁 戊 己)[$year % 10]
    .
    qw(申 酉 戌 亥 子 丑 寅 卯 辰 巳 午 未)[$year % 12];
  my $v0 = ($year - 4) % 60;
  my $v1 = $v0 + 1;
  return ($k, $v0, $v1);
} # to_ykanshi

binmode STDOUT, qw(:encoding(utf-8));

printf "Year %d (%s)\n",
    $year, to_thai $year;
printf "... is year %d (if year 0 is AD %d)\n",
    $base_year - 1 + $year, $base_year;
printf "... is year %d (if year 1 is AD %d)\n",
    $base_year - 1 + $year + 1, $base_year;
printf "... is AD %d (%s 0:%d 1:%d), then:\n",
    $base_year, (to_ykanshi $base_year);
printf "    year 0 is AD %d = BC %d = Shouou %d = Bokuou %d = Kyouou %d (%s 0:%d 1:%d);\n",
    $base_year - $year,
    1 - ($base_year - $year),
    - -1051 + ($base_year - $year) + 1,
    - -948 + ($base_year - $year) + 1,
    - -945 + ($base_year - $year) + 1,
    (to_ykanshi $base_year - $year);
printf "    year 1 is AD %d = BC %d = Shouou %d = Bokuou %d = Kyouou %d (%s 0:%d 1:%d);\n",
    $base_year - $year + 1,
    1 - ($base_year - $year + 1),
    - -1051 + ($base_year - $year + 1) + 1,
    - -948 + ($base_year - $year + 1) + 1,
    - -945 + ($base_year - $year + 1) + 1,
    (to_ykanshi $base_year - $year + 1);
printf "    Y = AD + %d %s\n",
    $year - $base_year,
    $desc->{$year - $base_year} // '';
