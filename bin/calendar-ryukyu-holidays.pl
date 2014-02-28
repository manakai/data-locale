use strict;
use warnings;
use utf8;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib');
use Time::Local qw(timegm_nocheck);
use JSON::Functions::XS qw(perl2json_bytes_for_record);

## <http://ja.wikipedia.org/wiki/%E4%BD%8F%E6%B0%91%E3%81%AE%E7%A5%9D%E7%A5%AD%E6%97%A5>

my $Data = {};

## 春分、秋分
## <http://www.asahi-net.or.jp/~ci5m-nmr/misc/equinox.html>
## <http://ja.wikipedia.org/wiki/%E6%98%A5%E5%88%86>
## <http://ja.wikipedia.org/wiki/%E7%A7%8B%E5%88%86>

my @Shunbun = (
  [qw(1800 1827 21 21 21 21)],
  [qw(1828 1859 20 21 21 21)],
  [qw(1860 1891 20 20 21 21)],
  [qw(1892 1899 20 20 20 21)],
  [qw(1900 1923 21 21 21 22)],
  [qw(1924 1959 21 21 21 21)],
  [qw(1960 1991 20 21 21 21)],
  [qw(1992 2023 20 20 21 21)],
  [qw(2024 2055 20 20 20 21)],
  [qw(2056 2091 20 20 20 20)],
  [qw(2092 2099 19 20 20 20)],
  [qw(2100 2123 20 21 21 21)],
  [qw(2124 2155 20 20 21 21)],
  [qw(2156 2187 20 20 20 21)],
  [qw(2188 2199 20 20 20 20)],
);

my @Shuubun = (
  [qw(1800 1823 23 23 24 24)],
  [qw(1824 1851 23 23 23 24)],
  [qw(1852 1887 23 23 23 23)],
  [qw(1888 1899 22 23 23 23)],
  [qw(1900 1919 23 24 24 24)],
  [qw(1920 1947 23 23 24 24)],
  [qw(1948 1979 23 23 23 24)],
  [qw(1980 2011 23 23 23 23)],
  [qw(2012 2043 22 23 23 23)],
  [qw(2044 2075 22 22 23 23)],
  [qw(2076 2099 22 22 22 23)],
  [qw(2100 2103 23 23 23 24)],
  [qw(2104 2139 23 23 23 23)],
  [qw(2140 2167 22 23 23 23)],
  [qw(2168 2199 22 22 23 23)],
);

sub get_sday ($$) {
  my ($tbl, $year) = @_;
  for (@$tbl) {
    if ($_->[0] <= $year and $year <= $_->[1]) {
      return $_->[2 + ($year % 4)];
    }
  }
  return undef;
} # get_sday

## 1961/7/24公布・施行
## 住民の祝祭日に関する立法 (1961年立法第85号)

## 1972/5/15施行
## 琉球諸島及び大東諸島に関する日本国とアメリカ合衆国との間の協定

for my $year (1961..1972) {
  if ($year > 1961) {
    $Data->{"$year-01-01"} = '元日';
    $Data->{"$year-01-15"} = '成人の日';

    my $shunbun = get_sday \@Shunbun, $year;
    $Data->{sprintf '%04d-%02d-%02d', $year, 3, $shunbun} = '春分の日';

    $Data->{"$year-04-01"} = '琉球政府創立記念日';
    $Data->{"$year-04-29"} = '天皇誕生日';
    $Data->{"$year-05-03"} = '憲法記念日' if $year >= 1965;
    $Data->{"$year-05-05"} = 'こどもの日';

    for my $day (8..14) { # 第2日曜日
      my $time = timegm_nocheck (0, 0, 0, $day, 5-1, $year-1900);
      my $wday = (gmtime($time))[6];
      $Data->{sprintf '%04d-%02d-%02d', $year, 5, $day} = '母の日'
          if $wday == 0;
    }

    last if $year == 1972;

    $Data->{"$year-06-22"} = '慰霊の日' if $year <= 1965;
    $Data->{"$year-06-23"} = '慰霊の日' if $year >= 1965;
  }

  $Data->{'1961-08-25'} = 'お盆の日' if $year == 1961;
  $Data->{'1962-08-14'} = 'お盆の日' if $year == 1962;
  $Data->{'1963-09-02'} = 'お盆の日' if $year == 1963;
  $Data->{'1964-08-22'} = 'お盆の日' if $year == 1964;
  $Data->{'1965-08-11'} = 'お盆の日' if $year == 1965;
  $Data->{'1966-08-30'} = 'お盆の日' if $year == 1966;
  $Data->{'1967-08-20'} = 'お盆の日' if $year == 1967;
  $Data->{'1968-08-08'} = 'お盆の日' if $year == 1968;
  $Data->{'1969-08-27'} = 'お盆の日' if $year == 1969;
  $Data->{'1970-08-16'} = 'お盆の日' if $year == 1970;
  $Data->{'1971-09-04'} = 'お盆の日' if $year == 1971;

  $Data->{"$year-09-15"} = 'としよりの日';

  my $shuubun = get_sday \@Shuubun, $year;
  $Data->{sprintf '%04d-%02d-%02d', $year, 9, $shuubun} = '秋分の日';

  for my $day (8..14) { # 第2土曜日
    my $time = timegm_nocheck (0, 0, 0, $day, 10-1, $year-1900);
    my $wday = (gmtime($time))[6];
    $Data->{sprintf '%04d-%02d-%02d', $year, 10, $day} = '体育の日'
        if $wday == 6;
  }

  $Data->{"$year-11-03"} = '文化の日';
  $Data->{"$year-11-23"} = '勤労感謝の日';
}

## 皇太子明仁親王の結婚の儀の行われる日を休日とする立法 1959年立法第26号
$Data->{"1959-04-10"} = '皇太子明仁親王の結婚の儀の行われる日';

print perl2json_bytes_for_record $Data;
