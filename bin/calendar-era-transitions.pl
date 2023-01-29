use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {transitions => []};

my $Input;
my $Eras;
{
  my $path = $RootPath->child ('local/calendar-era-defs-0.json');
  my $json = json_bytes2perl $path->slurp;
  $Input = $json->{_TRANSITIONS};
  $Eras = $json->{eras};
}

my $ThisYear = [gmtime]->[5] + 1900;

sub ymd2string (@) {
  if ($_[0] < 0) {
    return sprintf '-%04d-%02d-%02d', -$_[0], $_[1], $_[2];
  } else {
    return sprintf '%04d-%02d-%02d', $_[0], $_[1], $_[2];
  }
} # ymd2string

sub ymmd2string (@) {
  if ($_[0] < 0) {
    return sprintf "-%04d-%02d%s-%02d", -$_[0], $_[1], $_[2]?"'":'', $_[3];
  } else {
    return sprintf "%04d-%02d%s-%02d", $_[0], $_[1], $_[2]?"'":'', $_[3];
  }
} # ymmd2string

sub parse_ystring ($) {
  my $s = shift;
  if ($s =~ m{^(-?[0-9]+)}) {
    return 0+$1;
  }

  die "Bad ystring |$s|";
} # parse_ystring

{
  ## Derived from |Time::Local|
  ## <http://cpansearch.perl.org/src/DROLSKY/Time-Local-1.2300/lib/Time/Local.pm>.

  use constant SECS_PER_MINUTE => 60;
  use constant SECS_PER_HOUR   => 3600;
  use constant SECS_PER_DAY    => 86400;

  my %Cheat;
  my $Epoc = 0;
  $Epoc = _daygm( gmtime(0) );
  %Cheat = ();

  use POSIX;
  sub _daygm {

    # This is written in such a byzantine way in order to avoid
    # lexical variables and sub calls, for speed
    return $_[3] + (
        $Cheat{ pack( 'ss', @_[ 4, 5 ] ) } ||= do {
            my $month = ( $_[4] + 10 ) % 12;
            my $year  = $_[5] + 1900 - int($month / 10);

            ( ( 365 * $year )
              + floor( $year / 4 )
              - floor( $year / 100 )
              + floor( $year / 400 )
              + int( ( ( $month * 306 ) + 5 ) / 10 )
            )
            - $Epoc;
        }
    );
  }

  sub timegm_nocheck {
    my ( $sec, $min, $hour, $mday, $month, $year ) = @_;

    my $days = _daygm( undef, undef, undef, $mday, $month, $year - 1900);

    return $sec
           + ( SECS_PER_MINUTE * $min )
           + ( SECS_PER_HOUR * $hour )
           + ( SECS_PER_DAY * $days );
  }
}

sub jd2g_ymd ($) {
  my @time = gmtime (($_[0] - 2440587.5) * 24 * 60 * 60);
  return undef unless defined $time[5];
  return ($time[5]+1900, $time[4]+1, $time[3]);
} # jd2g_ymd

require POSIX;
sub jd2j_ymd ($) {
  my $jd = $_[0];
  my $c = POSIX::floor ($jd + 0.5) + 32082;
  my $d = POSIX::floor ((4*$c + 3) / 1461);
  my $e = $c - POSIX::floor (1461 * $d / 4);
  my $m = POSIX::floor ((5*$e + 2) / 153);
  my $D = $e - POSIX::floor ((153*$m + 2) / 5) + 1;
  my $M = $m + 3 - 12 * POSIX::floor ($m / 10);
  my $Y = $d - 4800 + POSIX::floor ($m / 10);
  return ($Y, $M, $D);
} # jd2j_ymd

sub gymd2jd ($$$) {
  my ($y, $m, $d) = @_;

  my $unix = timegm_nocheck (0, 0, 0, $d, $m-1, $y);
  my $jd = $unix / (24*60*60) + 2440587.5;

  return $jd;
} # gymd2jd

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

sub jymd2jd ($$$) {
  my ($y, $m, $d) = @_;

  return &gymd2jd (j2g $y, $m, $d);
} # jymd2jd

sub jd2mjd ($) {
  return $_[0] - 2400000.5;
} # jd2mjd

sub jd2kanshi0 ($) {
  return (($_[0] + 0.5 + 49) % 60);
} # jd2kanshi0

my $IndexToKanshi = {map { my $x = $_; $x =~ s/\s+//g; $x =~ s/(\d+)/ $1 /g;
                           grep { length } split /\s+/, $x } q{
1甲子2乙丑3丙寅4丁卯5戊辰6己巳7庚午8辛未9壬申10癸酉11甲戌12乙亥13丙子
14丁丑15戊寅16己卯17庚辰18辛巳19壬午20癸未21甲申22乙酉23丙戌24丁亥25戊子
26己丑27庚寅28辛卯29壬辰30癸巳31甲午32乙未33丙申34丁酉35戊戌36己亥
37庚子38辛丑39壬寅40癸卯41甲辰42乙巳43丙午44丁未45戊申46己酉47庚戌48辛亥
49壬子50癸丑51甲寅52乙卯53丙辰54丁巳55戊午56己未57庚申58辛酉59壬戌60癸亥
}};
my $KanshiToIndex = {reverse %$IndexToKanshi};
sub kanshi0_to_label ($) { $IndexToKanshi->{$_[0]+1} // die $_[0] }
sub label_to_kanshi0 ($) {
  my $v = $_[0];
  $v =~ s/景/丙/g;
  my $kanshi = $KanshiToIndex->{$v}
      // die "Bad kanshi |$_[0]|";
  return $kanshi - 1;
} # label_to_kanshi0

sub year2kanshi0 ($) {
  return (($_[0]-4)%60);
} # year2kanshi0

my $KMaps = {};
my $GToKMapKey = {
  秦 => 'shinkan',
  漢 => 'shinkan',
  蜀 => 'shinkan',
  呉 => 'go',
  魏 => 'gishin',
  晋 => 'gishin',
  南 => 'south',
  北魏 => 'zuitou',
  東魏 => 'tougi',
  隋 => 'zuitou',
  唐 => 'zuitou',
  宋 => 'sou',
  遼 => 'zuitou',
  金 => 'zuitou',
  元 => 'zuitou',
  明 => 'zuitou',
  清 => 'shin',
  中華民国 => 'hk',
  中華人民共和国 => 'hk',
  高句麗 => 'gishin',
  百済 => 'south',
  新羅 => 'zuitou',
  高麗 => 'zuitou',
  李氏朝鮮 => 'shin',
  k => 'kyuureki',
};
sub get_kmap ($) {
  my $g = shift;
  my $kmap_key = $GToKMapKey->{$g} // die "Bad key |$g|";
  unless (defined $KMaps->{$kmap_key}) {
    my $path = $RootPath->child ("intermediate/j94-partial/$kmap_key.txt");
    my $g2k = {map { split /\t/, $_ } split /\x0D?\x0A/, $path->slurp};
    my $k2g = {reverse %$g2k};
    $KMaps->{$kmap_key} = $k2g;
  }

  my $kmap = $KMaps->{$kmap_key};
  return $kmap;
} # get_kmap

sub nymmd2jd ($$$$$) {
  my ($g, $y, $m, $lm, $d) = @_;

  if ($g eq '東魏' and ($y < 540 or 577 < $y)) {
    $g = '魏';
  }

  if ($g eq '魏' and 452 <= $y) {
    $g = '隋';
  } elsif ($g eq '明' and (1663 <= $y and $y <= 1683+1)) {
    ## No calendar available
    $g = '清';
  } elsif ($g eq '清' and $y <= 1644) {
    ## No calendar available
    $g = '明';
  }

  if ($g eq '宋' and $y > 1279) {
    $g = '元';
  }
  
  if ($g eq '魏' and $y < 237) {
    $g = '漢';
  }

  if ($g eq '越南') {
    if ($y > 1912) {
      $g = '中華民国';
    } elsif ($y > 1644) {
      $g = '清';
    } elsif ($y > 1279) {
      $g = '元';
    } else {
      $g = '宋';
    }
  }

  my $kmap = get_kmap ($g);

  my $gr;
  my $delta = 0;
  if ($d eq '末') {
    if ($lm) {
      $lm = 0;
      $m++;
      if ($m == 13) {
        $y++;
        $m = 1;
      }
      my $k1 = ymmd2string $y, $m, $lm, 1;
      if (defined $kmap->{$k1}) {
        $gr = $kmap->{$k1};
      } else {
        die "Bad date ($g, $y, $m, $lm, 1)";
      }
      $delta = -1;
    } else { # not $lm
      my $k1 = ymmd2string $y, $m, 1, 1; # same $m with leap
      if (defined $kmap->{$k1}) {
        $gr = $kmap->{$k1};
        $delta = -1;
      } else {
        $m++;
        if ($m == 13) {
          $y++;
          $m = 1;
        }
        my $k1 = ymmd2string $y, $m, 0, 1;
        if (defined $kmap->{$k1}) {
          $gr = $kmap->{$k1};
          $delta = -1;
        } else {
          die "Bad date ($g, $y, $m, $lm, 1)";
        }
      }
    }
  } else {
    my $k = ymmd2string $y, $m, $lm, $d;
    if (defined $kmap->{$k}) {
      $gr = $kmap->{$k};
    } else {
      my $k1 = ymmd2string $y, $m, $lm, 1;
      if (defined $kmap->{$k1}) {
        $gr = $kmap->{$k1};
        $delta = $d - 1;
      } else {
        die "Bad date ($g, $y, $m, $lm, $d)", Carp::longmess;
      }
    }
  }

  $gr =~ m{^(-?[0-9]+)-([0-9]+)-([0-9]+)$} or die "Bad gregorian date |$gr|";
  my $jd = gymd2jd $1, $2, $3;
  $jd += $delta;
  
  return $jd;
} # nymmd2jd

sub nymmk2jd ($$$$$) {
  my ($g, $y, $m, $lm, $kl) = @_;

  my $k = label_to_kanshi0 $kl;

  my $jd_ref = gymd2jd $y-1, 12, 21; # ~ 冬至
  my $jd_m = $jd_ref + (365.25 / 12) * ($m + 1);
  $jd_m += (365.25 / 12) / 2 if $lm;
  $jd_m = int ($jd_m) + 0.5;

  my $jd;
  my $k_m = jd2kanshi0 $jd_m;
  
  if ($k_m < $k) {
    my $delta = $k - $k_m;
    if ($delta > 30) {
      $jd = $jd_m + $delta - 60;
    } else {
      $jd = $jd_m + $delta;
    }
  } else { # $k <= $k_m
    my $delta = $k_m - $k;
    if ($delta > 30) {
      $jd = $jd_m - $delta + 60;
    } else {
      $jd = $jd_m - $delta;
    }
  }

  #warn ymd2string jd2g_ymd $jd_ref;
  #warn ymd2string (jd2g_ymd $jd_m), " ", $k_m;
  #warn ymd2string (jd2g_ymd $jd), " ", $k;
  #warn ymd2string (jd2g_ymd $jd-60), " ", $k;
  #warn ymd2string (jd2g_ymd $jd+60), " ", $k;

  return $jd;
} # nymmk2jd

sub gymd2nymmd ($$$$) {
  my ($g, $y, $m, $d) = @_;
  my $jd = gymd2jd $y, $m, $d;

  if ($g eq '明' and (1663 <= $y and $y <= 1683+1)) {
    ## No calendar available
    $g = '清';
  }

  if ($g eq '南' and $y <= 445) {
    $g = '晋';
  }
  
  if ($g eq '魏' and $y <= 237) {
    $g = '漢';
  }
  
  my $kmap = get_kmap ($g);

  my $prev_jd;
  my $prev_ymm;
  for my $ky ($y-1, $y, $y+1) {
    for my $km (1..12) {
      for my $kml (0, 1) {
        my $k = ymmd2string $ky, $km, $kml, 1;
        my $gr = $kmap->{$k} or next;
        $gr =~ /^(-?[0-9]+)-([0-9]+)-([0-9]+)$/
            or die "Bad gregorian date |$gr|";
        my $j = gymd2jd $1, $2, $3;
        if (defined $prev_jd and
            $prev_jd <= $jd and
            $jd < $j) {
          return (@$prev_ymm, 1 + $jd - $prev_jd);
        }
        $prev_jd = $j;
        $prev_ymm = [$ky, $km, $kml];
      }
    }
  }

  die "Bad date $y, $m, $d ($g)";
} # gymd2nymmd

{
my $g2k_map_path = $RootPath->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};
my $k2g_map = {reverse %$g2k_map};
$KMaps->{kyuureki} = $k2g_map;

  sub k2g ($) {
    return $k2g_map->{$_[0]} || die "Kyuureki |$_[0]| is not defined", Carp::longmess;
  } # k2g

  sub k2g_undef ($) {
    return $k2g_map->{$_[0]}; # or undef
  } # k2g_undef

  sub g2k ($) {
    return $g2k_map->{$_[0]} || die "Gregorian |$_[0]| is not defined", Carp::longmess;
  } # g2k

  sub g2k_undef ($) {
    return $g2k_map->{$_[0]}; # or undef
  } # g2k_undef
}

sub year_start_jd ($$) {
  my ($y, $tag_ids) = @_;

  my @jd;

  if (($tag_ids->{1008} or # 中国
       $tag_ids->{1086} or # 蒙古
       $tag_ids->{1084} or # 後金
       $tag_ids->{1009} or # 漢土
       $tag_ids->{1012} or # 朝鮮
       $tag_ids->{2084}) and # 越南
      not $tag_ids->{1344} and # グレゴリオ暦
      not $tag_ids->{3184}) { # 旧暦
    if ($y >= 1912) {
      push @jd, nymmd2jd '中華民国', $y, 1, 0, 1;
    } elsif ($y >= 1645+1) {
      push @jd, nymmd2jd '清', $y, 1, 0, 1;
    } elsif ($y >= 1367) {
      push @jd, nymmd2jd '明', $y, 1, 0, 1;
    } elsif ($y >= 1260) {
      push @jd, nymmd2jd '元', $y, 1, 0, 1;
    } elsif ($y >= 960) {
      push @jd, nymmd2jd '宋', $y, 1, 0, 1;
    } elsif ($y >= 618) {
      if ((690 <= $y and $y <= 700) or $y == 762) {
        push @jd, nymmd2jd '唐', $y-1, 11, 0, 1;
      } else {
        push @jd, nymmd2jd '唐', $y, 1, 0, 1;
      }
    } elsif ($y >= 581) {
      push @jd, nymmd2jd '隋', $y, 1, 0, 1;
    } elsif ($y >= 445) {
      push @jd, nymmd2jd '南', $y, 1, 0, 1;
    } elsif ($y >= 265) {
      push @jd, nymmd2jd '晋', $y, 1, 0, 1;
    } elsif ($y >= 237) {
      if (($y == 238 or $y == 239) and
          $tag_ids->{1153}) { # 魏の公年号
        push @jd, nymmd2jd '魏', $y-1, 12, 0, 1;
      } else {
        push @jd, nymmd2jd '魏', $y, 1, 0, 1;
      }
    } elsif ($y >= -205) {
      if ($tag_ids->{1161}) { # 新の公年号
        push @jd, nymmd2jd '漢', $y-1, 12, 0, 1;
      } elsif ($y <= -103) {
        push @jd, nymmd2jd '漢', $y-1, 10, 0, 1;
      } else {
        push @jd, nymmd2jd '漢', $y, 1, 0, 1;
      }
    } elsif ($y >= -245) {
      push @jd, nymmd2jd '秦', $y-1, 10, 0, 1;
    }
  }

  if ($tag_ids->{1003} and # 日本
      not $tag_ids->{1344}) { # グレゴリオ暦
    my $g = k2g_undef ymmd2string $y, 1, 0, 1;
    if (defined $g) {
      $g =~ /^(-?[0-9]+)-([0-9]+)-([0-9]+)$/
          or die "Bad gregorian date |$g|";
      push @jd, gymd2jd $1, $2, $3;
    }
  }

  if ($tag_ids->{1344}) { # グレゴリオ暦
    push @jd, gymd2jd $y, 1, 1;
  }

  return undef unless @jd;

  my $jd = shift @jd;
  for (@jd) {
    if ($jd != $_) {
      die "Conflicting days $jd @jd (year start, @{[join ',', values %$tag_ids]})", Carp::longmess;
    }
  }

  return $jd;
} # year_start_jd

sub ssday ($$) {
  my ($jd, $tag_ids) = @_;
  
  my ($y, $m, $d) = jd2g_ymd ($jd);
  my $g = ymd2string ($y, $m, $d);

  my ($jjy, $jjm, $jjd) = jd2j_ymd ($jd);
  my $jj = ymd2string ($jjy, $jjm, $jjd);

  my $kanshi = jd2kanshi0 $jd;
  my $day = {jd => $jd,
             mjd => (jd2mjd $jd),
             kanshi0 => $kanshi,
             kanshi_label => (kanshi0_to_label $kanshi),
             gregorian => $g,
             julian => $jj};

  if ($tag_ids->{1344}) { # グレゴリオ暦
    $day->{year} = $y;
  }

  if ($tag_ids->{1008} or # 中国
      $tag_ids->{1086} or # 蒙古
      $tag_ids->{1084} or # 後金
      $tag_ids->{1009} or # 漢土
      $tag_ids->{1012} or # 朝鮮
      $tag_ids->{2084}) { # 越南
    if ($y >= 1912) {
      unless ($tag_ids->{2084}) { # 越南
        $day->{nongli_tiger} = ymmd2string gymd2nymmd '中華民国', $y, $m, $d;
      }
    } elsif ($y >= 1645+1) {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '清', $y, $m, $d;
    } elsif ($y >= 1367) {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '明', $y, $m, $d;
    } elsif ($y >= 1260) {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '元', $y, $m, $d;
    } elsif ($y >= 960) {
      my @ymmd = gymd2nymmd '宋', $y, $m, $d;
      $day->{nongli_tiger} = ymmd2string @ymmd;

      if ($ymmd[0] == 1119 and $ymmd[1] >= 11) {
        $day->{nongli_rat} = ymmd2string $ymmd[0]+1, $ymmd[1]-10, $ymmd[2], $ymmd[3];
      } elsif ($ymmd[0] == 1120 and $ymmd[1] <= 10) {
        $day->{nongli_rat} = ymmd2string $ymmd[0], $ymmd[1]+2, $ymmd[2], $ymmd[3];
      }
    } elsif ($y >= 618) {
      my @ymmd = gymd2nymmd '唐', $y, $m, $d;
      $day->{nongli_tiger} = ymmd2string @ymmd;

      if ($ymmd[0] > 689 and $ymmd[0] < 700) {
        if ($ymmd[1] == 11 or $ymmd[1] == 12) {
          $day->{nongli_wuzhou} = ymmd2string $ymmd[0]+1, $ymmd[1], $ymmd[2], $ymmd[3];
        } else {
          $day->{nongli_wuzhou} = $day->{nongli_tiger};
        }
      } elsif ($ymmd[0] == 689) {
        if ($ymmd[1] == 11 or $ymmd[1] == 12) {
          $day->{nongli_wuzhou} = ymmd2string $ymmd[0]+1, $ymmd[1], $ymmd[2], $ymmd[3];
        }
      } elsif ($ymmd[0] == 700) {
        if ($ymmd[1] == 11 or $ymmd[1] == 12) {
          #
        } else {
          $day->{nongli_wuzhou} = $day->{nongli_tiger};
        }
      }

      if ($ymmd[0] == 761 and $ymmd[1] >= 11) {
        $day->{nongli_rat} = ymmd2string $ymmd[0]+1, $ymmd[1]-10, $ymmd[2], $ymmd[3];
      } elsif ($ymmd[0] == 762 and $ymmd[1] <= 10) {
        $day->{nongli_rat} = ymmd2string $ymmd[0], $ymmd[1]+2, $ymmd[2], $ymmd[3];
      }
      
      if ($ymmd[0] == 762 and $ymmd[1] >= 8 and $ymmd[1] <= 11) {
        $day->{nongli_ox} = ymmd2string $ymmd[0], $ymmd[1]+1, $ymmd[2], $ymmd[3];
      } elsif ($ymmd[0] == 763 and $ymmd[1] <= 11) {
        $day->{nongli_ox} = ymmd2string $ymmd[0], $ymmd[1]+1, $ymmd[2], $ymmd[3];
      }
    } elsif ($y >= 581) {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '隋', $y, $m, $d;
    } elsif ($y >= 445) {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '南', $y, $m, $d;
    } elsif ($y >= 265) {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '晋', $y, $m, $d;
    } elsif ($y >= 237) {
      my @ymmd = gymd2nymmd '魏', $y, $m, $d;
      $day->{nongli_tiger} = ymmd2string @ymmd;
      
      if ($ymmd[0] == 237 and $ymmd[1] >= 3 and $ymmd[1] <= 11) {
        $day->{nongli_ox} = ymmd2string $ymmd[0], $ymmd[1]+1, $ymmd[2], $ymmd[3];
      } elsif ($ymmd[0] >= 237 and $ymmd[0] <= 238 and $ymmd[1] == 12) {
        $day->{nongli_ox} = ymmd2string $ymmd[0]+1, $ymmd[1]-11, $ymmd[2], $ymmd[3];
      } elsif ($ymmd[0] >= 238 and $ymmd[0] <= 239 and $ymmd[1] <= 11) {
        $day->{nongli_ox} = ymmd2string $ymmd[0], $ymmd[1]+1, $ymmd[2], $ymmd[3];
      }
    } elsif ($y >= -205) {
      my @ymmd = gymd2nymmd '漢', $y, $m, $d;
      $day->{nongli_tiger} = ymmd2string @ymmd;
      
      if ($ymmd[0] >= 8 and $ymmd[0] <= 22 and $ymmd[1] == 12) {
        $day->{nongli_ox} = ymmd2string $ymmd[0]+1, $ymmd[1]-11, $ymmd[2], $ymmd[3];
      } elsif ($ymmd[0] >= 9 and $ymmd[0] <= 23 and $ymmd[1] <= 11) {
        $day->{nongli_ox} = ymmd2string $ymmd[0], $ymmd[1]+1, $ymmd[2], $ymmd[3];
      }

      if ($ymmd[0] < 1-104 and $ymmd[1] >= 10) {
        $day->{nongli_qin} = ymmd2string $ymmd[0]+1, $ymmd[1], $ymmd[2], $ymmd[3];
      } elsif ($ymmd[0] <= 1-104 and $ymmd[1] <= 9) {
        $day->{nongli_qin} = $day->{nongli_tiger};
      }
    } elsif ($y >= -245) {
      my @ymmd = gymd2nymmd '秦', $y, $m, $d;
      $day->{nongli_tiger} = ymmd2string @ymmd;

      if ($ymmd[1] >= 10) {
        $day->{nongli_qin} = ymmd2string $ymmd[0]+1, $ymmd[1], $ymmd[2], $ymmd[3];
      } else {
        $day->{nongli_qin} = $day->{nongli_tiger};
      }
    }
    
    if (not defined $day->{year} and
        defined $day->{nongli_tiger} and
        $day->{nongli_tiger} =~ m{^(-?[0-9]+)}) {
      $day->{year} = 0+$1;
    }
    if ($tag_ids->{1852} and # 秦正
        defined $day->{nongli_qin} and
        $day->{nongli_qin} =~ m{^(-?[0-9]+)}) {
      $day->{year} = 0+$1;
    }
    if ($tag_ids->{1853} and # 武周正
        defined $day->{nongli_wuzhou} and
        $day->{nongli_wuzhou} =~ m{^(-?[0-9]+)}) {
      $day->{year} = 0+$1;
    }
    if ($tag_ids->{1851} and # 丑正
        defined $day->{nongli_ox} and
        $day->{nongli_ox} =~ m{^(-?[0-9]+)}) {
      $day->{year} = 0+$1;
    }
    if ($tag_ids->{1850} and # 子正
        defined $day->{nongli_rat} and
        $day->{nongli_rat} =~ m{^(-?[0-9]+)}) {
      $day->{year} = 0+$1;
    }
  }

  if ($tag_ids->{1003}) { # 日本
    my $k = g2k_undef ymd2string $y, $m, $d;
    $day->{kyuureki} = $k if defined $k;
    #// die "No kyuureki date for ($y, $m, $d)";
    if (not $tag_ids->{1344} and # グレゴリオ暦
        defined $k and $k =~ m{^(-?[0-9]+)}) {
      die "($y, $m, $d) [$k]$1, $day->{year}; ", (perl2json_bytes $tag_ids),
          Carp::longmess
          if defined $day->{year} and $day->{year} != $1;
      $day->{year} = 0+$1;
    }
  }

  $day->{year} //= $y;
  
  return $day;
} # ssday

sub extract_day_year ($$) {
  my ($day, $tag_ids) = @_;

  if (($tag_ids->{1008} or # 中国
       $tag_ids->{1084} or # 後金
       $tag_ids->{1086} or # 蒙古
       $tag_ids->{1009}) and # 漢土
      not $tag_ids->{1344}) { # グレゴリオ暦
    if (defined $day->{nongli_tiger}) {
      return parse_ystring $day->{nongli_tiger};
    }
  }

  if ($tag_ids->{2084}) { # 越南
    if (defined $day->{nongli_tiger}) {
      return parse_ystring $day->{nongli_tiger};
    }
  }

  if ($tag_ids->{1003} and # 日本
      not $tag_ids->{1344}) { # グレゴリオ暦
    if (defined $day->{kyuureki}) {
      return parse_ystring $day->{kyuureki};
    }
  }
  
  return parse_ystring $day->{gregorian};
} # extract_day_year

my $Tags;
my $TagByKey = {};
{
  my $path = $RootPath->child ('data/tags.json');
  $Tags = (json_bytes2perl $path->slurp)->{tags};
  for my $item (values %$Tags) {
    $TagByKey->{$item->{key}} = $item;
  }
}

sub set_object_tag ($$) {
  my ($obj, $tkey) = @_;
  $tkey =~ s/_/ /g;
  my $item = $TagByKey->{$tkey};
  die "Tag |$tkey| not defined" unless defined $item;

  $obj->{tag_ids}->{$item->{id}} = $item->{key};
  for (qw(region_of group_of period_of)) {
    for (keys %{$item->{$_} or {}}) {
      my $item2 = $Tags->{$_};
      $obj->{tag_ids}->{$item2->{id}} = $item2->{key};
      if ($item2->{type} eq 'country') {
        for (keys %{$item2->{period_of} or {}}) {
          my $item3 = $Tags->{$_};
          $obj->{tag_ids}->{$item3->{id}} = $item3->{key};
        }
      }
    }
  }
} # set_object_tag

sub copy_transition_tags ($$;%) {
  my ($from, $to, %args) = @_;
  for (keys %{$from->{tag_ids}}) {
    set_object_tag $to, $from->{tag_ids}->{$_} if {
      country => 1,
      region => 1,
      calendar => 1,
    }->{$Tags->{$_}->{type}};
    set_object_tag $to, $from->{tag_ids}->{$_}
        if not $args{tail} and
           {
             1359 => '起事建元',
             1161 => '新の公年号',
             1153 => '魏の公年号',
             2107 => '分離',
           }->{$_};
  }
} # copy_transition_tags

sub parse_year ($) {
  my $s = shift;
  if ($s =~ s/^BC//) {
    return 1 - $s;
  } else {
    return 0+$s;
  }
} # parse_year

sub parse_date ($$;%) {
  my ($all, $v, %args) = @_;

  my @jd;
  while (length $v) {
    if ($v =~ s{^g:((?:-|BC|)[0-9]+)-([0-9]+)-([0-9]+)\s*}{}) {
      push @jd, gymd2jd parse_year ($1), $2, $3;
    } elsif ($v =~ s{^j:((?:-|BC|)[0-9]+)-([0-9]+)-([0-9]+)\s*}{}) {
      push @jd, jymd2jd parse_year ($1), $2, $3;
    } elsif ($v =~ s{^(秦|漢|蜀|呉|魏|晋|南|北魏|東魏|隋|唐|宋|遼|金|元|明|清|中華人民共和国|越南|高句麗|百済|新羅|高麗|李氏朝鮮):((?:-|BC|)[0-9]+)(?:\((\w\w)\)|)-([0-9]+)('|)-([0-9]+)\((\w\w)\)\s*}{}) {
      push @jd, nymmd2jd $1, parse_year ($2), $4, $5, $6;
      push @jd, nymmk2jd $1, parse_year ($2), $4, $5, $7;
      if (defined $3) {
        my $ky2 = label_to_kanshi0 $3;
        my $ky1 = year2kanshi0 $2;
        unless ($ky1 == $ky2) {
          die "Year mismatch ($ky1 vs $ky2) |$all|";
        }
      }
    } elsif ($v =~ s{^(秦|漢|蜀|呉|魏|晋|南|北魏|東魏|隋|唐|宋|遼|金|元|明|清|中華人民共和国|越南|高句麗|百済|新羅|高麗|李氏朝鮮|k):((?:-|BC|)[0-9]+)-([0-9]+)('|)-([0-9]+)\s*}{}) {
      push @jd, nymmd2jd $1, parse_year ($2), $3, $4, $5;
    } elsif ($v =~ s{^(秦|漢|蜀|呉|魏|晋|南|北魏|東魏|隋|唐|宋|遼|金|元|明|清|中華人民共和国|越南|高句麗|百済|新羅|高麗|李氏朝鮮):((?:-|BC|)[0-9]+)-([0-9]+)('|)-(\w\w)\s*}{}) {
      push @jd, nymmk2jd $1, parse_year ($2), $3, $4, $5;
    } elsif ($v =~ s{^(秦|漢|蜀|呉|魏|晋|南|北魏|東魏|隋|唐|宋|遼|金|元|明|清|中華人民共和国|越南|高句麗|百済|新羅|高麗|李氏朝鮮|k):((?:-|BC|)[0-9]+)-([0-9]+)('|)\s*}{}) {
      if ($args{start}) {
        push @jd, nymmd2jd $1, parse_year ($2), $3, $4, 1;
      } elsif ($args{end}) {
        push @jd, nymmd2jd $1, parse_year ($2), $3, $4, '末';
      } else {
        die "Bad date |$v| ($all)";
      }
    } elsif ($v =~ s{^g:([0-9]+)-([0-9]+)\s*}{}) {
      if ($args{start}) {
        push @jd, gymd2jd $1, $2, 1;
      } elsif ($args{end}) {
        my $y = $1;
        my $m = $2+1;
        if ($m == 13) {
          $y++;
          $m = 1;
        }
        push @jd, -1 + gymd2jd $y, $m, 1;
      } else {
        die "Bad date |$v| ($all)";
      }
    } elsif ($v =~ s{^(秦|漢|蜀|呉|魏|南|北魏|東魏|晋|隋|唐|宋|遼|金|元|明|清|中華人民共和国|越南|高句麗|百済|新羅|高麗|李氏朝鮮|k):((?:-|BC|)[0-9]+)\s*}{}) {
      if ($args{start}) {
        push @jd, nymmd2jd $1, parse_year ($2), 1, '', 1;
      } elsif ($args{end}) {
        push @jd, -1 + nymmd2jd $1, parse_year ($2) + 1, 1, '', 1;
      } else {
        die "Bad date |$v| ($all)";
      }
    } elsif ($v =~ s{^g:([0-9]+)\s*}{}) {
      if ($args{start}) {
        push @jd, gymd2jd $1, 1, 1;
      } elsif ($args{end}) {
        push @jd, -1 + gymd2jd $1+1, 1, 1;
      } else {
        die "Bad date |$v| ($all)";
      }
    } else {
      die "Bad date |$v| ($all)";
    }
  } # $v
  die "Bad date ($all)" unless @jd;
  
  my $jd = $jd[0];
  for (@jd) {
    unless ($jd == $_) {
      die "Date mismatch ($jd vs $_) |$all|";
    }
  }

  return $jd;
} # parse_date

$Eras->{干支年}->{id} = 0;
my $Transitions = [];
for my $tr (@$Input) {
  my $from_keys = [defined $tr->[0] ? split /,/, $tr->[0] : ()];
  my $to_keys = [defined $tr->[1] ? split /,/, $tr->[1] : ()];
  my $v = $tr->[2];
  my $source_info = $tr->[3];
  my $x = {};
  my $x_subject_tag_ids = [];

  if (ref $v eq 'HASH') { # comes from |bin/era-date-list.pl|.
    next if defined $v->{label} and $v->{label} eq '年末';
    
    set_object_tag $x, '日本';
    set_object_tag $x, '日本北朝' if $v->{prefix} eq 'north_';
    set_object_tag $x, '日本南朝' if $v->{prefix} eq 'south_';
    
    my $y = parse_ystring
        ((ref $v->{day} eq 'ARRAY' ? $v->{day}->[0] : $v->{day})->{gregorian});
    my $change;
    if ($tr->[1] eq '文武天皇') {
      $change = '日本改元日';
    } elsif ($tr->[1] =~ /天皇$|摂政$/) {
      $change = '天皇即位元年年始';
    } elsif ($y < 1870) {
      $change = '日本朝廷改元日';
    } elsif ($y < 1960) {
      $change = '大日本帝国改元日';
    } else {
      $change = '日本国改元日';
    }
    if ($v->{change_day}) {
      set_object_tag $x, $change;
      die 'XX'.'X' if $v->{incorrect};
    } else {
      if (defined $v->{label}) {
        set_object_tag $x, $v->{label};
        die 'XX'.'X' if $v->{incorrect};
        set_object_tag $x, '戦時異動' if $v->{type} eq 'wartime';
        set_object_tag $x, '分離' if @$from_keys and {
          AD => 1,
        }->{$from_keys->[0]};
        set_object_tag $x, '行政異動'
            if $v->{type} eq 'succeed' and not $v->{label} eq '改元前の崩御';
        set_object_tag $x, '通知受領' if $v->{type} eq 'received';
      } else {
        set_object_tag $x, $change;
        if ($v->{incorrect}) {
          set_object_tag $x, '旧説';
        } else {
          set_object_tag $x, '異説';
        }
      }
    }
    for (@{$v->{tags} or []}) {
      set_object_tag $x, $_;
    }
    
    if (ref $v->{day} eq 'ARRAY') {
      $x->{day_start} = ssday $v->{day}->[0]->{jd}, $x->{tag_ids};
      $x->{day_end} = ssday $v->{day}->[1]->{jd}, $x->{tag_ids};
    } else {
      $x->{day} = ssday $v->{day}->{jd}, $x->{tag_ids};
    }
  } else { # comes from |bin/calendar-era-defs.pl|.
    my $is_fork = $v =~ s/^\+//;
    set_object_tag $x, '併用' if $is_fork;

    $v =~ s/\s+$//;
    while (1) {
      if ($v =~ s{\s*#([\w_()\x{20000}-\x{3FFFF}]+)$}{}) {
        set_object_tag $x, $1;
      } elsif ($v =~ s{\s*#([\w_()\x{20000}-\x{3FFFF}]+)\{([#\w_()\x{20000}-\x{3FFFF}\s]*)(?:,([#\w_()\x{20000}-\x{3FFFF}\s]*)|)\}$}{}) {
        my $tags = $2;
        my $tags2 = $3;
        my $t1 = $1;
        $t1 =~ s/_/ /g;
        my $tag = $TagByKey->{$t1};
        die "Tag |$t1| not found" unless defined $tag;
        die "Not an action tag: |$t1|" unless $tag->{type} eq 'action';
        set_object_tag $x, $t1;
        die "Duplicate action tag: |$t1|" if defined $x->{action_tag_id};
        $x->{action_tag_id} = $tag->{id};
        my $param_tags = {};
        {
          while ($tags =~ s{\s*#([\w_()\x{20000}-\x{3FFFF}]+)$}{}) {
            my $t1 = $1;
            $t1 =~ s/_/ /g;
            my $tag = $TagByKey->{$t1};
            die "Tag |$t1| not found" unless defined $tag;
            $param_tags->{$t1} = 1;
            if ($tag->{type} eq 'country' or
                $tag->{type} eq 'org' or
                $tag->{type} eq 'people' or
                $tag->{type} eq 'religion' or
                $tag->{type} eq 'source') {
              if (defined $tags2) {
                $x->{subject_tag_ids}->{$tag->{id}} = 1;
                push @$x_subject_tag_ids, $tag->{id};
              } else {
                die "Duplicate authority tag: |$t1| [$tr->[2]]"
                    if defined $x->{authority_tag_id};
                $x->{authority_tag_id} = $tag->{id};
              }
            } elsif ($tag->{type} eq 'region') {
              if (defined $tags2) {
                $x->{subject_tag_ids}->{$tag->{id}} = 1;
                push @$x_subject_tag_ids, $tag->{id};
              } else {
                $x->{subject_tag_ids}->{$tag->{id}} = 1;
                push @$x_subject_tag_ids, $tag->{id};
              }
            } elsif ($tag->{type} eq 'person') {
              $x->{subject_tag_ids}->{$tag->{id}} = 1;
              push @$x_subject_tag_ids, $tag->{id};
            } elsif ($tag->{type} eq 'position') {
              die "Duplicate position tag: |$t1|"
                  if defined $x->{position_tag_id};
              $x->{position_tag_id} = $tag->{id};
            } elsif ($tag->{type} eq 'event' or
                     $tag->{type} eq 'law') {
              die "Duplicate event tag: |$t1|"
                  if defined $x->{event_tag_id};
              $x->{event_tag_id} = $tag->{id};
            } else {
              die "Bad parameter tag: |$t1| (type: $tag->{type})";
            }
          }
          $tags =~ s/^\s+//;
          die "Bad tags |$tags|" if length $tags;
        }
        if (defined $tags2) {
          while ($tags2 =~ s{\s*#([\w_()\x{20000}-\x{3FFFF}]+)$}{}) {
            my $t1 = $1;
            $t1 =~ s/_/ /g;
            my $tag = $TagByKey->{$t1};
            die "Tag |$t1| not found" unless defined $tag;
            $param_tags->{$t1} = 1;
            if ($tag->{type} eq 'country' or
                $tag->{type} eq 'region' or
                $tag->{type} eq 'person' or
                $tag->{type} eq 'religion' or
                $tag->{type} eq 'org') {
              $x->{object_tag_ids}->{$tag->{id}} = 1;
            } else {
              #warn perl2json_bytes $x;
              die "Bad parameter tag: |$t1| (type: $tag->{type})";
            }
          }
          $tags2 =~ s/^\s+//;
          die "Bad tags |$tags2|" if length $tags2;
        }
        for (keys %$param_tags) {
          set_object_tag $x, $_;
        }
      } else {
        last;
      }
    }

  if ($v =~ m{^\[([^,]+)\]$}) {
    my $jd1 = parse_date $tr->[2], $1, start => 1;
    my $jd2 = parse_date $tr->[2], $1, end => 1;
    $x->{day_start} = (ssday $jd1, $x->{tag_ids});
    $x->{day_end} = (ssday $jd2, $x->{tag_ids});
  } elsif ($v =~ m{^\[([^,]+),([^,]+)\]$}) {
    my $jd1 = parse_date $tr->[2], $1, start => 1;
    my $jd2 = parse_date $tr->[2], $2, end => 1;
    $x->{day_start} = (ssday $jd1, $x->{tag_ids});
    $x->{day_end} = (ssday $jd2, $x->{tag_ids});
  } else {
    my $jd = parse_date $tr->[2], $v;
    $x->{day} = (ssday $jd, $x->{tag_ids});
  }
  if (defined $x->{day_start} and
      not $x->{day_start}->{jd} < $x->{day_end}->{jd}) {
    die "Bad date range [$x->{day_start}->{jd}, $x->{day_end}->{jd}] ($tr->[2])";
  }
  } # $v

  if ($x->{tag_ids}->{1190} or # 日本改元日
      $x->{tag_ids}->{1189} or # 支那改元日
      $x->{tag_ids}->{1728} or # 支那改元詔
      $x->{tag_ids}->{1442}) { # 元号名変更
    for my $to_key (@$to_keys) {
      next if $to_key eq '干支年';
      if (defined $x->{authority_tag_id}) {
        my $tag = $Tags->{$x->{authority_tag_id}};
        if ($tag->{type} eq 'country') {
          if (not $x->{tag_ids}->{1198}) { # 異説
            $Data->{_ERA_PROPS}->{$to_key}->{country_tag_id} = $x->{authority_tag_id};
          } else {
            $Data->{_ERA_PROPS_2}->{$to_key}->{country_tag_id} = $x->{authority_tag_id};
          }
          $Data->{_ERA_TAGS}->{$to_key}->{$tag->{key}} = 1;
        }
      }
      for my $tag_id (@$x_subject_tag_ids) {
        my $tag = $Tags->{$tag_id};
        if ($tag->{type} eq 'person') {
          if (not $x->{tag_ids}->{1198}) { # 異説
            $Data->{_ERA_PROPS}->{$to_key}->{monarch_tag_id} //= 0+$tag_id;
          } else {
            $Data->{_ERA_PROPS_2}->{$to_key}->{monarch_tag_id} //= 0+$tag_id;
          }
          $Data->{_ERA_TAGS}->{$to_key}->{$tag->{key}} = 1;
        }
      }
    }
  }
  
  if ($x->{tag_ids}->{1278} and # 適用開始
      not $x->{tag_ids}->{1198} and # 異説
      defined $x->{day}) {
    my $y = {};
    my $z = {};
    my $z2 = {};
    copy_transition_tags $x => $y;
    copy_transition_tags $x => $z, tail => 1;
    copy_transition_tags $x => $z2, tail => 1;
    set_object_tag $y, '日本朝廷改元前日'
        if $x->{tag_ids}->{1325}; # 日本朝廷改元日
    set_object_tag $y, '大日本帝国改元前日'
        if $x->{tag_ids}->{1326}; # 大日本帝国改元日
    set_object_tag $y, '日本国改元前日'
        if $x->{tag_ids}->{1327}; # 日本国改元日
    set_object_tag $y, 'マイクロネーション改元前日'
        if $x->{tag_ids}->{2007}; # マイクロネーション改元日
    set_object_tag $y, 'マイクロネーション再開前日'
        if $x->{tag_ids}->{2032}; # マイクロネーション再開
    
    set_object_tag $y, '適用開始前日';
    $y->{day} = ssday $x->{day}->{jd} - 1, $y->{tag_ids};
    push @$Transitions, [$from_keys, $to_keys, $y, $tr->[2], $source_info];

    my $year = parse_ystring $y->{day}->{gregorian};
    my $jd = year_start_jd $year+1, $z->{tag_ids};
    if (defined $jd) {
      set_object_tag $z2, '末年翌日';
      $z2->{day} = ssday $jd, $z2->{tag_ids};
      push @$Transitions, [$from_keys, $to_keys, $z2, $tr->[2], $source_info];
      
      set_object_tag $z, '末年末';
      $z->{day} = ssday $jd - 1, $z->{tag_ids};
      push @$Transitions, [$from_keys, $to_keys, $z, $tr->[2], $source_info];
    }
  } elsif ($x->{tag_ids}->{1347} and # 初年始
           defined $x->{day}) {
    my $y = {};
    my $z = {};
    copy_transition_tags $x => $y;
    copy_transition_tags $x => $z;

    set_object_tag $y, '初年前日';
    $y->{day} = ssday $x->{day}->{jd} - 1, $y->{tag_ids};
    push @$Transitions, [$from_keys, $to_keys, $y, $tr->[2], $source_info];
  }
  
  push @$Transitions, [$from_keys, $to_keys, $x, $tr->[2], $source_info];
} # $tr

my $NewTransitions = [];
ERA: for my $era (sort { $a->{id} <=> $b->{id} } values %$Eras) {
  next unless defined $era->{offset};

  my $to_trs = [grep { !! grep { $era->{key} eq $_ } @{$_->[1]} } @$Transitions];

  my $prev_eras = [];
  my $w = {};
  my $has_tr = 0;
  for (@$to_trs) {
    my $x = $_->[2];
    next ERA if $x->{tag_ids}->{1347}; # 初年始

    if ($era->{tag_ids}->{1078}) { # 公年号
      if ($x->{tag_ids}->{2045}) { # マイクロネーション建元
        set_object_tag $x, '分離';
      }
    }
    
    copy_transition_tags $x => $w
        unless $x->{tag_ids}->{1338} or # 通知受領
               $x->{tag_ids}->{1337}; # 通知発出
    set_object_tag $w, '日本朝廷改元年始'
        if $x->{tag_ids}->{1325}; # 日本朝廷改元日
    push @$prev_eras, @{$_->[0]};
    $has_tr = 1;
  } # $_
  delete $w->{tag_ids}->{1344} if $era->{id} == 1; # グレゴリオ暦, 明治
  copy_transition_tags $era => $w unless $has_tr;

  my $v = json_bytes2perl perl2json_bytes $w;
  $prev_eras = [grep {
    $_ ne '干支年' and
    defined $Eras->{$_}->{offset} and
    $Eras->{$_}->{offset} <= $era->{offset};
  } @$prev_eras];

  my $jd = year_start_jd ($era->{offset} + 1, $w->{tag_ids});
  next unless defined $jd;
  
    set_object_tag $w, '初年始';
    set_object_tag $w, '即位元年年始' if $era->{tag_ids}->{1069}; # 即位紀年
    $w->{day} = ssday $jd, $w->{tag_ids};
    push @$NewTransitions, [$prev_eras, [$era->{key}], $w, undef, undef];

    set_object_tag $v, '初年前日';
    $v->{day} = ssday $jd - 1, $v->{tag_ids};
    push @$NewTransitions, [$prev_eras, [$era->{key}], $v, undef, undef];
} # ERA
unshift @$Transitions, @$NewTransitions;

$Data->{_TRANSITIONS} = [];
for (@$Transitions) {
  my ($from_keys, $to_keys, $x, $source_line_text, $source_info) = @$_;
  $from_keys = [grep { $_ ne '-' } keys %{{map { $_ => 1 } @$from_keys}}];
  $to_keys = [grep { $_ ne '-' } keys %{{map { $_ => 1 } @$to_keys}}];

  my $type;
  if ($x->{tag_ids}->{1360}) { # 適用開始予定
    $type = 'firstday';
    if ($x->{tag_ids}->{1361}) { # 適用開始 (中止)
      $type .= '/canceled';
    }
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1349}) { # 適用開始前日
    $type = 'prevfirstday';
    if ($x->{tag_ids}->{1200}) { # 旧説
      die "XX"."X";
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      die "XX"."X";
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1182} or # 制定
           $x->{tag_ids}->{1264}) { # 発表
    $type = 'proclaimed';
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1442}) { # 元号名変更
    $type = 'renamed';
  } elsif ($x->{tag_ids}->{1185}) { # 利用開始
    $type = 'commenced';
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1124}) { # 実施中止
    $type = 'canceled';
  } elsif ($x->{tag_ids}->{1843}) { # 撤回
    $type = 'canceled';
  } elsif ($x->{tag_ids}->{1191}) { # 事由
    $type = 'triggering';
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1230}) { # 戦時異動
    $type = 'wartime';
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1339}) { # 行政異動
    $type = 'administrative';
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1338}) { # 通知受領
    $type = 'received';
  } elsif ($x->{tag_ids}->{1337}) { # 通知発出
    $type = 'notified';
  } elsif ($x->{tag_ids}->{1431}) { # 建元不承認
    $type = 'rejected';
  } elsif ($x->{tag_ids}->{1347}) { # 初年始
    $type = 'firstyearstart';
  } elsif ($x->{tag_ids}->{1277}) { # 初年前日
    $type = 'prevfirstyearstart';
  } elsif ($x->{tag_ids}->{1350}) { # 末年末
    $type = 'lastyearend';
  } elsif ($x->{tag_ids}->{1351}) { # 末年翌日
    $type = 'nextlastyearend';
  } elsif ($x->{tag_ids}->{2867}) { # 異説発生
    $type = 'deviated';
  } elsif ($x->{tag_ids}->{2878}) { # 避諱改名
    $type = 'taboorenamed';
  } elsif ($x->{tag_ids}->{2877}) { # 元号名再利用
    $type = 'namesucceeded';
  } elsif ($x->{tag_ids}->{2098}) { # 改元非難
    $type = 'other';
  } else {
    if (@$from_keys and not @$to_keys) {
      $type = 'other';
    } else {
      $type = 'established';
      #XXXdie "No action tag @$from_keys @$to_keys";
    }
  }
  $x->{type} = $type;

  my $y = {%$x};
  for my $from_key (@$from_keys) {
    next if $from_key eq q{干支年};
    my $era = $Eras->{$from_key};
    die "Era key |$from_key| not defined"
        unless defined $era and defined $era->{id};
    $y->{prev_era_ids}->{$era->{id}} = 1;
    $y->{relevant_era_ids}->{$era->{id}} = {};
  }
  for my $to_key (@$to_keys) {
    next if $to_key eq q{干支年};
    my $era = $Eras->{$to_key};
    die "Era key |$to_key| not defined"
        unless defined $era and defined $era->{id};
    $y->{next_era_ids}->{$era->{id}} = 1;
    $y->{relevant_era_ids}->{$era->{id}} = {};
  }
  push @{$Data->{_TRANSITIONS}}, $y;

  if (defined $source_info and
      defined $source_info->{tag} and
      ($type eq 'firstday' or
       $type eq 'firstday/possible' or
       $type eq 'firstday/incorrect') and
      @$to_keys == 1 and $to_keys->[0] ne '干支年') {
    my $era = $Eras->{$to_keys->[0]};
    $Data->{_ERA_TAGS}->{$era->{key}}->{$source_info->{tag}} = 1;
  }

  if ($x->{tag_ids}->{2867}) { # 異説発生
    for my $to_key (@$to_keys) {
      next if $to_key eq q{干支年};
      $Data->{_ERA_TAGS}->{$to_key}->{異説} = 1;
    }
  }
  if ($x->{tag_ids}->{2870}) { # 誤伝発生
    for my $to_key (@$to_keys) {
      next if $to_key eq q{干支年};
      $Data->{_ERA_TAGS}->{$to_key}->{旧説} = 1;
    }
  }
  if ($x->{tag_ids}->{2878}) { # 避諱改名
    for my $from_key (@$from_keys) {
      next if $from_key eq q{干支年};
      $Data->{_ERA_TAGS}->{$from_key}->{避諱前元号} = 1;
    }
    for my $to_key (@$to_keys) {
      next if $to_key eq q{干支年};
      $Data->{_ERA_TAGS}->{$to_key}->{避諱後元号} = 1;
    }
  }
} # $tr

my $TypeOrder = {
  nextlastyearend => "_00",
  firstyearstart => "_01",
  
  triggering => "_10",

  "firstday-canceled" => "firstday_0",
  firstday => "firstday_1",
  commenced => 'firstday_2',

  lastyearend => "~98",
  prevfirstyearstart => "~99",
};
$Data->{transitions} = [map { $_->[0] } sort {
  $a->[1] <=> $b->[1] ||
  $a->[2] <=> $b->[2] ||
  $a->[4] cmp $b->[4] ||
  $a->[3] cmp $b->[3];
} map {
  [$_,
   ($_->{day} || $_->{day_start})->{mjd},
   ($_->{day} || $_->{day_end})->{mjd},
   (join $;, sort { $a <=> $b } keys %{$_->{relevant_era_ids}}),
   $TypeOrder->{$_->{type}} || $_->{type}];
} @{delete $Data->{_TRANSITIONS}}];

ERA: for my $era (sort { $a->{id} <=> $b->{id} } values %$Eras) {
  my $to_trs = [grep { $_->{next_era_ids}->{$era->{id}} } @{$Data->{transitions}}];

  my $first_day;
  for my $tr (@$to_trs) {
    if ($tr->{type} eq 'firstday') {
      $first_day = $tr->{day} // $tr->{day_start};
      last;
    }
  }
  if (not defined $first_day) {
    for my $tr (@$to_trs) {
      if ($tr->{type} eq 'firstday/incorrect') {
        $first_day = $tr->{day} // $tr->{day_start};
        last;
      }
    }
  }
  next ERA unless defined $first_day;

  for my $tr (@$to_trs) {
    if ({
      triggering => 1,
      'triggering/possible' => 1,
      'triggering/incorrect' => 1,
      proclaimed => 1,
      'proclaimed/possible' => 1,
      'proclaimed/incorrect' => 1,
      received => 1,
      'received/possible' => 1,
      'received/incorrect' => 1,
      notified => 1,
      'notified/possible' => 1,
      'notified/incorrect' => 1,
      commenced => 1,
      'commenced/possible' => 1,
      'commenced/incorrect' => 1,
    }->{$tr->{type}}) {
      my $day = $tr->{day} // $tr->{day_start};
      my $delta = $first_day->{mjd} - $day->{mjd};
      $tr->{relevant_era_ids}->{$era->{id}}->{until_first_day} = $delta;
    }
  }
} # ERA

print perl2json_bytes_for_record $Data;

## License: Public Domain.
