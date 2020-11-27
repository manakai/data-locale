
{
use Time::Local qw(timegm_nocheck);

## 祝日、祭日
## <https://ja.wikipedia.org/wiki/%E7%A5%9D%E7%A5%AD%E6%97%A5>
## <https://ja.wikipedia.org/wiki/%E5%9B%BD%E6%B0%91%E3%81%AE%E7%A5%9D%E6%97%A5>
## <https://wiki.suikawiki.org/n/%E6%97%A5%E6%9C%AC%E3%81%AE%E7%A5%9D%E6%97%A5>

sub _d {$_[0] < 1870? 0: timegm_nocheck(0,0,0,$_[2],$_[1]-1,$_[0])}
my %d = (
    M6	=> _d(1873,10,14),	## Meiji 6 Dajoukan Fukoku No.344
    M11 => _d(1878,6,5),        ## Meiji 11 Dajoukan Fukoku No.23
    M12	=> _d(1879,7,5),	## Meiji 12 Dajoukan Fukoku No.27
    T1	=> _d(1912,9,3),	## Taishou 1 Chokurei No.19
    T2	=> _d(1913,7,16),	## Taishou 2 Chokurei No.259
    S2	=> _d(1927,3,3),	## Shouwa 2 Chokurei No.25
    S23	=> _d(1948,7,20),	## Shouwa 23 Law No.178
    S41	=> _d(1966,6,25),	## Shouwa 41 Law No.86
    S48	=> _d(1948,7,20),	## Shouwa 48 Law No.10
    S60	=> _d(1985,12,27),	## Shouwa 60 Law No.103
    H1	=> _d(1998,2,17),	## Heisei 1 Law No.5
    H7	=> _d(1996,1,1),	## Heisei 7 Law No.22
    H10	=> _d(2000,1,1),	## Heisei 10 Law No.141
    H13 => _d(2003,1,1),	## H13-06-22
    H17 => _d(2007,1,1),	## H17-05-20
    H26 => _d(2016,1,1),        ## H26 (2014)
    H31 => _d(2019,5,1),        ## H29 Law #63 / H29 Ordinance #302
    H32 => _d(2020,1,1),        ## H30 Law #55, #57
    R3  => _d(2021,1,1),    ## XXX R2 Law #?? / R? Ordinance #?
);

## 春分、秋分
## <https://www.nao.ac.jp/faq/a0301.html>
## <http://www.asahi-net.or.jp/~ci5m-nmr/misc/equinox.html>
## <https://ja.wikipedia.org/wiki/%E6%98%A5%E5%88%86>
## <https://ja.wikipedia.org/wiki/%E7%A7%8B%E5%88%86>

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
  [qw(2200 2223 21 21 21 21)],
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
  [qw(2200 2227 23 23 23 24)],
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

$SUNDAY = 0;
$MONDAY = 1;

use utf8;
sub isholiday ($$$) {
  my ($year, $month, $day) = @_;
  my $time = _d($year,$month,$day);
  my $wday = (gmtime($time))[6];
  
  return 0 if $time < _d(1873,1,1);	## 1983AD = Meiji6
  
  if ($month == 1) {
    return '元日' if $day == 1 && $d{S23} <= $time;
    return '四方節' if $day == 1 && $d{S23} > $time;
        ## Not explicitly defined by laws
    return '振替休日' if $wday == $MONDAY && $day == 2 && $d{S48} <= $time;
    
    return '成人の日' if $wday == $MONDAY && 8 <= $day && $day <= 14 &&
                $d{H10} < $time;
    return '成人の日' if $day == 15 && $d{S23} <= $time && $time < $d{H10};
    return '振替休日' if $wday == $MONDAY && $day == 16 &&
                $d{S48} <= $time && $time < $d{H10};
    
    return '元始祭' if $day == 3 && $d{M6} <= $time && $time < $d{S23};
    return '新年宴会' if $day == 5 && $d{M6} <= $time && $time < $d{S23};
    return '孝明天皇祭' if $day == 30 && $d{M6} <= $time && $time < $d{T1};

    return '紀元節' if $day == 29 && $year == 1873;
  } elsif ($month == 2) {
    return '建国記念の日' if $day == 11 && $d{S41} <= $time;
    return '紀元節' if $day == 11 && $d{M6} <= $time && $time < $d{S23};
    return '振替休日' if $wday == $MONDAY && $day == 12 && $d{S48} <= $time;
    return '天皇誕生日' if $day == 23 && $d{H31} <= $time;
    return '振替休日' if $wday == $MONDAY && $day == 24 && $d{H31} <= $time;
    return '昭和天皇の大喪の礼の行われる日' if $year == 1989 && $day == 24;
    	## Heisei 1 Law No.4
  } elsif ($month == 3) {
    my $shunbun = get_sday \@Shunbun, $year;
    return '春季皇霊祭' if 1873 <= $year && $year < 3000 &&
        $day == $shunbun && $d{M11} <= $time && $time < $d{S23};
    return '春分の日' if 1873 <= $year && $year < 3000 &&
        $day == $shunbun && $d{S23} <= $time;
    return '振替休日' if $wday == $MONDAY && $day == $shunbun+1 && $d{S48} <= $time;
  } elsif ($month == 4) {
    return '天長節' if $day == 29 && $d{S2} <= $time && $time < $d{S23};
    return '天皇誕生日' if $day == 29 && $d{S23} <= $time && $time < $d{H1};
    return 'みどりの日' if $day == 29 && $d{H1} <= $time && $time < $d{H17};
    return '昭和の日' if $day == 29 && $d{H17} <= $time;
    return '振替休日' if $wday == $MONDAY && $day == 30 && $d{S48} <= $time;
    
    return '神武天皇祭' if $d{M6} <= $time && $time < $d{S23} && $day == 3;

    return '皇太子明仁親王の結婚の儀の行われる日' if $year == 1959 && $day == 10;
    	## Shouwa 34 Law No.16
    return '国民の休日' if $year == 2019 && $day == 30;
  } elsif ($month == 5) {
    return '天皇の即位の日' if $year == 2019 && $day == 1;
    return '国民の休日' if $year == 2019 && $day == 2;
    return '憲法記念日' if $day == 3 && $d{S23} <= $time;

    return '振替休日' if $wday == $MONDAY && $day == 4 &&
                $d{S48} <= $time && $time < $d{H17};
    return '国民の休日' if $wday != $SUNDAY && $day == 4 && $d{S60} <= $time && $time < $d{H17};
    return 'みどりの日' if $wday != $SUNDAY && $day == 4 && $d{H17} <= $time;

    return 'こどもの日' if $day == 5 && $d{S23} <= $time;
    return '振替休日' if $wday == $MONDAY && $day == 6 && $d{S48} <= $time; # 5/5 is Sunday
    return '振替休日' if $wday == $MONDAY+1 && $day == 6 && $d{H17} <= $time; # 5/4 is Sunday
    return '振替休日' if $wday == $MONDAY+2 && $day == 6 && $d{H17} <= $time; # 5/3 is Sunday
  } elsif ($month == 6) {
      return '皇太子徳仁親王の結婚の儀の行われる日' if $year == 1993 && $day == 9;
    	## Heisei 5 Law No.32
  } elsif ($month == 7) {
    return '海の日' if $day == 20 && $d{H7} <= $time && $time < $d{H13};
    return '海の日' if $wday == $MONDAY && 15 <= $day && $day <= 21 && $d{H13} <= $time && $year != 2020 && $year != 2021;
    return '海の日' if $day == 23 && $year == 2020;
    return '海の日' if $day == 22 && $year == 2021;
    return 'スポーツの日' if $day == 24 && $year == 2020;
    return 'スポーツの日' if $day == 23 && $year == 2021;
    return '振替休日' if $wday == $MONDAY && $day == 21 && $d{H7} <= $time && $time < $d{H13};

    return '明治天皇祭' if $day == 30 && $d{T1} <= $time && $time < $d{S2};
  } elsif ($month == 8) {
    ## <https://wiki.suikawiki.org/n/%E6%97%A5%E6%9C%AC%E3%81%AE%E7%A5%9D%E6%97%A5#anchor-211>
    return '天長節' if $day == 31 && $year == 1912;

    return '天長節' if $day == 31 && $d{T1} <= $time && $time < $d{S2};
    return '山の日' if $day == 11 && $d{H26} <= $time && $year != 2020 && $year != 2021;
    return '山の日' if $day == 10 && $year == 2020;
    return '山の日' if $day == 8 && $year == 2021;
    return '振替休日' if $wday == $MONDAY && $day == 12 && $d{H26} <= $time;
  } elsif ($month == 9) {
    return '敬老の日' if $day == 15 && $d{S41} <= $time && $time < $d{H13};
    return '敬老の日' if $wday == $MONDAY && 15 <= $day && $day <= 21 && $d{H13} <= $time;
    return '振替休日' if $wday == $MONDAY && $day == 16 && $d{S48} <= $time && $time < $d{H13};

    my $shuubun = get_sday \@Shuubun, $year;
    return '国民の休日' if $wday-1 == $MONDAY && 15 <= $day-1 && $day-1 <= 21 && $day+1 == $shuubun && $d{H13} <= $time;

    return '秋季皇霊祭' if 1873 <= $year && $year < 3000 &&
        $day == $shuubun && $d{M11} <= $time && $time < $d{S23};
    return '秋分の日' if 1873 <= $year && $year < 3000 &&
        $day == $shuubun && $time >= $d{S23};
    return '振替休日' if $wday == $MONDAY && $d{S48} <= $time &&
        $day == $shuubun+1;
    
    return '神嘗祭' if $day == 17 && $d{M6} <= $time && $time < $d{M12};
  } elsif ($month == 10) {
    return 'スポーツの日' if $wday == $MONDAY && 8 <= $day && $day <= 14 &&
                $d{H32} <= $time && $year != 2020 && $year != 2021;
    return '体育の日' if $wday == $MONDAY && 8 <= $day && $day <= 14 &&
                $d{H10} <= $time && $time < $d{H32};
    return '体育の日' if $day == 10 && $d{S41} <= $time && $time < $d{H10};
    return '振替休日' if $wday == $MONDAY && $day == 11 &&
                $d{S48} <= $time && $time < $d{H10};
    
    return '神嘗祭' if $day == 17 && $d{M12} <= $time && $time < $d{S23};
    return '即位礼正殿の儀の行われる日' if $year == 2019 && $day == 22;
    return '天長節祝日' if $day == 31 && $d{T2} <= $time && $time < $d{S2};

    return '皇大神宮遷御当日' if $day == 2 && $year == 1929;
        ## Shouwa 4 Chokurei No. 265 (1929-09-03)
  } elsif ($month == 11) {
    return '天長節' if $day == 3 && $d{M6} <= $time && $time < $d{T1};
    return '文化の日' if $day == 3 && $d{S2} <= $time;
    return '振替休日' if $wday == $MONDAY && $day == 4 && $d{S48} <= $time;

    return '新嘗祭' if $day == 23 && $d{M6} <= $time && $time < $d{S23};
    return '勤労感謝の日' if $day == 23 and $d{S23} <= $time;
    return '振替休日' if $wday == $MONDAY && $day == 24 && $d{S48} <= $time;
    
    return '即位ノ禮' if ($year == 1915 || $year == 1928) && $day == 10;
    return '大嘗祭' if ($year == 1915 || $year == 1928) && $day == 14;
    return '即位禮及大嘗祭後大饗第一日' if ($year == 1915 || $year == 1928) && $day == 16;
    	## Taishou 4 Chokurei No.161, Shouwa 3 Chokurei No.226

    return '即位礼正殿の儀の行われる日' if $year == 1990 && $day == 12;
    	## Heisei 2 Law No.24
  } elsif ($month == 12) {
    return '天皇誕生日' if $day == 23 && $d{H1} <= $time && $time < $d{H31};
    return '振替休日' if $wday == $MONDAY && $day == 24 && $d{H1} <= $time && $time < $d{H31};
    return '大正天皇祭' if $day == 25 && $d{S2} <= $time && $time < $d{S23};
  }
  
  return 0;
} # isholiday

1;

  ## Derived from
  ## <https://suika.suikawiki.org/gate/cvs/melon/suikacvs/perl/lib/Calender/Special/JP.pm?revision=1.1&view=markup>
  ## (2001/12/24 08:13:56).
  ##
  ## This program is free software; you can redistribute it and/or
  ## modify it under the same terms as Perl itself.
}

use JSON::PS;

my $Data = {};

for my $year (1870..2200) {
  for my $month (1..12) {
    for my $day (1..31) {
      my $name = isholiday ($year, $month, $day) or next;
      $Data->{sprintf '%04d-%02d-%02d', $year, $month, $day} = $name;
    }
  }
}

## 国民の休日
## <https://ja.wikipedia.org/wiki/%E5%9B%BD%E6%B0%91%E3%81%AE%E4%BC%91%E6%97%A5>

## Government holidays 1873-1876.3
for my $year (1873..1875) {
  use utf8;
  for my $month (1..12) {
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 1} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 6} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 11} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 16} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 21} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 26} ||= '一六日';
  }
}
for my $year (1876) {
  use utf8;
  for my $month (1..3) {
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 1} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 6} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 11} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 16} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 21} ||= '一六日';
    $Data->{sprintf '%04d-%02d-%02d', $year, $month, 26} ||= '一六日';
  }
}

print perl2json_bytes_for_record $Data;
