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
  542 => 'BE iota',
  950 => 'BE kappa',
  951 => 'BE lambda',
  608 => 'BE mu',
  928 => 'BE nu',
  567 => 'BE xi',
  444 => 'BE omicron',
  1028 => 'BE pi',

  960 => 'BE gamma-11',
  947 => 'BE gamma+2',
  532 => 'BE epsilon-1',
  536 => 'BE epsilon-5',
  545 => 'BE beta-1',
  554 => 'BE theta-9',
  
  941 => '(BE) eta+7',

  -638 => 'Burma',
  -590 => 'Fasli-',
  -591 => 'Fasli+',
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

sub to_year_desc ($) {
  my $ad = shift;
  return sprintf "AD %d = BC %d = Shouou %d = Bokuou %d = Kyouou %d (%s 0:%d 1:%d)",
      $ad,
      1 - $ad,
      - -1051 + $ad + 1,
      - -1000 + $ad + 1,
      - -945 + $ad + 1,
      (to_ykanshi $ad);
} # to_year_desc

binmode STDOUT, qw(:encoding(utf-8));

printf "Year %d (%s)\n",
    $year, to_thai $year;
printf "... is year %d (if year 0 is AD %d)\n",
    $base_year - 1 + $year, $base_year;
printf "... is year %d (if year 1 is AD %d)\n",
    $base_year - 1 + $year + 1, $base_year;
printf "... is %s, then:\n",
    to_year_desc $base_year;
printf "    year 0 is %s;\n",
    to_year_desc $base_year - $year;
printf "    year 1 is %s;\n",
    to_year_desc $base_year - $year + 1;
printf "    Y = AD + %d %s\n",
    $year - $base_year,
    $desc->{$year - $base_year} // '';
