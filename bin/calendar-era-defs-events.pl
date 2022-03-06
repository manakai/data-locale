use strict;
use warnings;
use utf8;
use Path::Tiny;
use Carp;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $DataPath = $RootPath->child ('local/calendar-era-defs-0.json');
my $Data = json_bytes2perl $DataPath->slurp;
my $ThisYear = [gmtime]->[5] + 1900;
my $RecentYears = 10;

my $EraTransitions;
my $EraTags;
my $EraLabels;
{
  my $path = $RootPath->child ('local/era-transitions-0.json');
  my $json = json_bytes2perl $path->slurp;
  $EraTransitions = $json->{transitions};
  $EraTags = $json->{_ERA_TAGS};
}
{
  my $path = $RootPath->child ('local/calendar-era-relations-0.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{_ERA_TAGS}}) {
    for my $tag_name (keys %{$json->{_ERA_TAGS}->{$key}}) {
      $EraTags->{$key}->{$tag_name} = 1;
    }
  }
}
{
  my $path = $RootPath->child ('local/calendar-era-labels-0.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{_SHORTHANDS}}) {
    $Data->{$key} = $json->{_SHORTHANDS}->{$key};
  }
  for my $in_era (values %{$json->{eras}}) {
    my $era = $Data->{eras}->{$in_era->{key}};
    for my $key (keys %{$in_era->{_SHORTHANDS}}) {
      $era->{$key} = $in_era->{_SHORTHANDS}->{$key};
    }
    delete $era->{_LABELS};
    delete $era->{_LPROPS};
  }
}

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
  my $kanshi = $KanshiToIndex->{$_[0]}
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

  if ($g eq '魏' and 452 <= $y) {
    $g = '隋';
  } elsif ($g eq '明' and (1663 <= $y and $y <= 1683+1)) {
    ## No calendar available
    $g = '清';
  } elsif ($g eq '清' and $y <= 1644) {
    ## No calendar available
    $g = '明';
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
      $tag_ids->{1009}) { # 漢土
    if ($y >= 1912) {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '中華民国', $y, $m, $d;
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
      die "($y, $m, $d) $1, $day->{year}; ", perl2json_bytes $tag_ids
          if defined $day->{year} and $day->{year} != $1;
      $day->{year} = 0+$1;
    }
  }

  $day->{year} //= $y;
  
  return $day;
} # ssday

sub set_day_era_dates ($$) {
  my ($day, $era) = @_;

  $day->{gregorian_era} = $day->{gregorian};
  $day->{julian_era} = $day->{julian};
  $day->{kyuureki_era} = $day->{kyuureki};
  die "No kyuureki date for era |$era->{key}|, |$day->{gregorian}|"
      unless defined $day->{kyuureki};

  for (qw(gregorian_era julian_era kyuureki_era)) {
    $day->{$_} =~ s{^(-?[0-9]+)}{
      $era->{key} . ($1 - $era->{offset});
    }e;
  }
} # set_day_era_dates

sub extract_day_year ($$) {
  my ($day, $tag_ids) = @_;

  if (($tag_ids->{1008} or # 中国
       $tag_ids->{1084} or # 後金
       $tag_ids->{1009}) and # 漢土
      not $tag_ids->{1344}) { # グレゴリオ暦
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
  die "Tag |$tkey| not defined", Carp::longmess unless defined $item;

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


for my $era (values %{$Data->{eras}}) {
  $era->{table_oldest_year} //= $era->{known_oldest_year}
      if defined $era->{known_oldest_year};
  $era->{table_latest_year} //= $era->{known_latest_year}
      if defined $era->{known_latest_year};

  my $era_trs = [grep {
    $_->{relevant_era_ids}->{$era->{id}};
  } @$EraTransitions];
  my $has_prevfirstday = 0;
  my $not_end_before_year;
  my $not_end_before_day;
  for my $tr (@$era_trs) {
    for my $dk (grep { defined $tr->{$_} } qw(day day_start day_end)) {
      for my $key (qw(gregorian julian kyuureki nongli_tiger)) {
        next unless defined $tr->{$dk}->{$key};
        my $year = parse_ystring $tr->{$dk}->{$key};
          if ({
            firstday => 1,
            'firstday/possible' => 1,
            'firstday/incorrect' => 1,
            prevfirstday => $tr->{prev_era_ids}->{$era->{id}},
            received => 1,
            'administrative' => 1,
            'wartime' => 1,
            commenced => 1,
          }->{$tr->{type}}) {
            $era->{known_oldest_year} //= $year;
            $era->{known_oldest_year} = $year if $year < $era->{known_oldest_year};
            $era->{known_latest_year} //= $year;
            $era->{known_latest_year} = $year if $era->{known_latest_year} < $year;
          }

          $era->{table_oldest_year} //= $year;
          $era->{table_oldest_year} = $year if $year < $era->{table_oldest_year};
          $era->{table_latest_year} //= $year;
          $era->{table_latest_year} = $year if $era->{table_latest_year} < $year;
      }
    }
    
    if ($tr->{next_era_ids}->{$era->{id}} and
        ($tr->{type} eq 'firstday' or
         $tr->{type} eq 'administrative' or
         $tr->{type} eq 'wartime')) { # has day or day_start
      my $y = extract_day_year $tr->{day} // $tr->{day_start}, $tr->{tag_ids};
      if (not $tr->{type} eq 'wartime') {
        $era->{start_year} //= $y;
        $era->{start_year} = $y if $y < $era->{start_year};
        if (not $tr->{tag_ids}->{2298} and # 一部勢力再開
            not $tr->{type} eq 'administrative') {
          if (defined $era->{end_year} and $era->{end_year} <= $y) {
            delete $era->{end_year};
            delete $era->{end_day};
          }
          $not_end_before_year //= $y;
          $not_end_before_year = $y if $not_end_before_year < $y;
        }
        if (defined $tr->{day}) {
          $era->{start_day} //= $tr->{day};
          $era->{start_day} = $tr->{day}
              if $tr->{day}->{mjd} < $era->{start_day}->{mjd};
          if (not $tr->{tag_ids}->{2107}) { # 分離
            $not_end_before_day //= $tr->{day}->{mjd};
            $not_end_before_day = $tr->{day}->{mjd}
                if $not_end_before_day < $tr->{day}->{mjd};
            if (defined $era->{end_day} and
                    $era->{end_day}->{mjd} < $tr->{day}->{mjd}) {
              delete $era->{end_day};
            }
          }
          $era->{official_start_day} = $era->{start_day}
              if $tr->{tag_ids}->{1326} or # 大日本帝国改元日
                 $tr->{tag_ids}->{1327}; # 日本国改元日
        }
      }
      if ($tr->{tag_ids}->{1065}) { # 日本北朝
        $era->{north_start_year} //= $y;
        $era->{north_start_year} = $y if $y < $era->{north_start_year};
        if (defined $tr->{day}) {
          $era->{north_start_day} //= $tr->{day};
          $era->{north_start_day} = $tr->{day}
              if $tr->{day}->{mjd} < $era->{north_start_day}->{mjd};
        }
      }
      if ($tr->{tag_ids}->{1066}) { # 日本南朝
        $era->{south_start_year} //= $y;
        $era->{south_start_year} = $y if $y < $era->{south_start_year};
        if (defined $tr->{day}) {
          $era->{south_start_day} //= $tr->{day};
          $era->{south_start_day} = $tr->{day}
              if $tr->{day}->{mjd} < $era->{south_start_day}->{mjd};
        }
      }
    }
    if ($tr->{next_era_ids}->{$era->{id}} and
        $tr->{type} eq 'firstyearstart') { # has day
      if ($tr->{tag_ids}->{1352} or # 日本朝廷改元年始
          $era->{key} eq '文武天皇') {
        $era->{official_start_day} //= $tr->{day};
        $era->{official_start_day} = $tr->{day}
            if $tr->{day}->{mjd} < $era->{official_start_day}->{mjd};
      }
      if ($tr->{tag_ids}->{1065}) { # 日本北朝
        $era->{north_official_start_day} //= $tr->{day};
        $era->{north_official_start_day} = $tr->{day}
            if $tr->{day}->{mjd} < $era->{north_official_start_day}->{mjd};
      }
      if ($tr->{tag_ids}->{1066}) { # 日本南朝
        $era->{south_official_start_day} //= $tr->{day};
        $era->{south_official_start_day} = $tr->{day}
            if $tr->{day}->{mjd} < $era->{south_official_start_day}->{mjd};
      }
    }
    if ($tr->{prev_era_ids}->{$era->{id}} and
        ($tr->{type} eq 'prevfirstday' or
         $tr->{type} eq 'administrative' or
         $tr->{type} eq 'wartime')) { # has day or day_end
      $has_prevfirstday = 1 if $tr->{type} eq 'prevfirstday';
      my $day = $tr->{day};
      if (defined $day and
          ($tr->{type} eq 'wartime' or
           $tr->{type} eq 'administrative')) {
        $day = ssday $day->{jd} - 1, $tr->{tag_ids};
      }
      $day //= $tr->{day_start};
      my $y = extract_day_year $day, $tr->{tag_ids};
      if (not $tr->{type} eq 'wartime' and
          not $tr->{type} eq 'administrative' and
          not $tr->{tag_ids}->{2107} and # 分離
          not ($era->{tag_ids}->{1078} and # 公年号
               ($tr->{tag_ids}->{2031} or # マイクロネーション再開前日
                $tr->{tag_ids}->{2008}))) { # マイクロネーション改元前日
        $era->{end_year} //= $y;
        $era->{end_year} = $y if $era->{end_year} < $y;
        if (defined $day) {
          $era->{end_day} //= $day;
          $era->{end_day} = $day
              if $era->{end_day}->{mjd} < $day->{mjd};
          $era->{actual_end_day} = $era->{end_day}
              if $tr->{tag_ids}->{1355}; # 日本国改元前日
        }
      }
      if ($tr->{tag_ids}->{1065}) { # 日本北朝
        $era->{north_end_year} //= $y;
        $era->{north_end_year} = $y if $era->{north_end_year} < $y;
        if (defined $day) {
          $era->{north_end_day} //= $day;
          $era->{north_end_day} = $day
              if $era->{north_end_day}->{mjd} < $day->{mjd};
        }
      }
      if ($tr->{tag_ids}->{1066}) { # 日本南朝
        $era->{south_end_year} //= $y;
        $era->{south_end_year} = $y if $era->{south_end_year} < $y;
        if (defined $day) {
          $era->{south_end_day} //= $day;
          $era->{south_end_day} = $day
              if $era->{south_end_day}->{mjd} < $day->{mjd};
        }
      }
    }
    if ($tr->{prev_era_ids}->{$era->{id}} and
        ($tr->{type} eq 'firstday' or
         $tr->{type} eq 'administrative' or
         $tr->{type} eq 'wartime') and
        defined $tr->{day}) {
      if ($tr->{tag_ids}->{1325}) { # 日本朝廷改元日
        $era->{actual_end_day} //= $tr->{day};
        $era->{actual_end_day} = $tr->{day}
            if $era->{actual_end_day}->{mjd} < $tr->{day}->{mjd};
      }
      if ($tr->{tag_ids}->{1326}) { # 大日本帝国改元日
        $era->{actual_end_day} //= $tr->{day};
        $era->{actual_end_day} = $tr->{day}
            if $era->{actual_end_day}->{mjd} < $tr->{day}->{mjd};
      }
      if ($tr->{tag_ids}->{1065}) { # 日本北朝
        $era->{north_actual_end_day} //= $tr->{day};
        $era->{north_actual_end_day} = $tr->{day}
            if $era->{north_actual_end_day}->{mjd} < $tr->{day}->{mjd};
      }
      if ($tr->{tag_ids}->{1066}) { # 日本南朝
        $era->{south_actual_end_day} //= $tr->{day};
        $era->{south_actual_end_day} = $tr->{day}
            if $era->{south_actual_end_day}->{mjd} < $tr->{day}->{mjd};
      }
    }
    if ($tr->{prev_era_ids}->{$era->{id}} and
        $tr->{type} eq 'prevfirstyearstart') { # has day
      if ($era->{key} eq '朱鳥') {
        $era->{actual_end_day} //= $tr->{day};
        $era->{actual_end_day} = $tr->{day}
            if $era->{actual_end_day}->{mjd} < $tr->{day}->{mjd};
      }
    }

    #use Data::Dumper;
    #warn Dumper [
    #  $tr->{day} // $tr->{day_start},
    #  $era->{end_year}
    #] if $era->{id} == 1112;
  } # $tr
  my $has_end_year = defined $era->{end_year};
  for my $tr (@$era_trs) {
    if (not defined $era->{start_year} and
        $tr->{type} eq 'firstday/incorrect') {
      my $y = extract_day_year $tr->{day} // $tr->{day_start}, $tr->{tag_ids};
      $era->{start_year} //= $y;
      $era->{start_day} //= $tr->{day} // $tr->{day_start};
    }
    if (not defined $era->{start_year} and
        $tr->{next_era_ids}->{$era->{id}} and
        $tr->{type} eq 'firstyearstart') { # has day
      my $y = extract_day_year $tr->{day}, $tr->{tag_ids};
      $era->{start_year} //= $y;
      $era->{start_year} = $y if $y < $era->{start_year};

      $era->{start_day} //= $tr->{day};
      $era->{start_day} = $tr->{day}
          if $tr->{day}->{mjd} < $era->{start_day}->{mjd};
      $era->{official_start_day} = $era->{start_day}
          if $era->{jp_emperor_era};
    }
    if ((not $has_end_year and
         $tr->{prev_era_ids}->{$era->{id}} and 
         ($tr->{type} eq 'administrative' or $tr->{type} eq 'wartime') and # has day or day_end
         not $tr->{tag_ids}->{2107}) or # 分離
        (not $has_prevfirstday and
         ($tr->{type} eq 'firstday' or $tr->{type} eq 'commenced') and
         $tr->{prev_era_ids}->{$era->{id}} and
         not $tr->{tag_ids}->{2107})) { # 分離
      my $day = $tr->{day};
      if (defined $day) {
        $day = ssday $day->{jd} - 1, $tr->{tag_ids};
      }
      $day //= $tr->{day_end};
      my $y = extract_day_year $day, $tr->{tag_ids};
      if ((not defined $not_end_before_year or
           $not_end_before_year <= $y) and
          (not defined $not_end_before_day or
           $not_end_before_day <= $day->{mjd})) {
        $era->{end_year} //= $y;
        $era->{end_year} = $y if $era->{end_year} < $y;

        $era->{end_day} //= $day;
        $era->{end_day} = $day
            if $era->{end_day}->{mjd} < $day->{mjd};
      }
    }
    if (not defined $era->{end_year} and
        $tr->{prev_era_ids}->{$era->{id}} and
        $tr->{type} eq 'prevfirstyearstart' and # has day
        not $tr->{tag_ids}->{2107}) { # 分離
      my $y = extract_day_year $tr->{day}, $tr->{tag_ids};
      if ((not defined $not_end_before_year or
           $not_end_before_year <= $y) and
          (not defined $not_end_before_day or
           $not_end_before_day <= $tr->{day}->{mjd})) {
        $era->{end_year} //= $y;
        $era->{end_year} = $y if $era->{end_year} < $y;

        $era->{end_day} //= $tr->{day};
        $era->{end_day} = $tr->{day}
            if $era->{end_day}->{mjd} < $tr->{day}->{mjd};
        $era->{actual_end_day} = $era->{end_day}
            if $era->{jp_emperor_era};
      }
    }
  } # $tr

  $era->{start_year} = $era->{offset} + 1
      if not defined $era->{start_year} and
         defined $era->{end_year} and
         defined $era->{offset};
  delete $era->{end_year}
      if defined $era->{end_year} and
         defined $era->{start_year} and
         $era->{end_year} < $era->{start_year};
  if (defined $era->{start_year} and
      not defined $era->{end_year}) {
    if ($era->{tag_ids}->{1124}) { # 実施中止
      $era->{end_year} = $era->{start_year};
    }
  }
  if (defined $era->{start_year} and
      not defined $era->{end_year} and
      defined $era->{known_latest_year} and
      $era->{known_latest_year} + $RecentYears < $ThisYear) {
    $era->{end_year} = $era->{known_latest_year};
  }
  delete $era->{end_year}
      if not defined $era->{start_year};
  die "Bad year range for era |$era->{key}| ($era->{start_year}, $era->{end_year})"
      if defined $era->{end_year} and
         (not defined $era->{start_year} or
          not $era->{start_year} <= $era->{end_year});

  if (defined $era->{end_year} and
      defined $era->{end_day} and
      $era->{end_year} != $era->{end_day}->{year}) {
    delete $era->{end_day};
  }
  
  $era->{known_oldest_year} //= $era->{start_year}
      if defined $era->{start_year};
  $era->{known_oldest_year} = $era->{start_year}
      if defined $era->{start_year} and
         $era->{start_year} < $era->{known_oldest_year};
  $era->{known_latest_year} //= $era->{end_year}
      if defined $era->{end_year};
  $era->{known_latest_year} = $era->{end_year}
      if defined $era->{end_year} and
         $era->{known_latest_year} < $era->{end_year};
  die "Bad known year range ($era->{known_oldest_year}, $era->{known_latest_year})"
      if defined $era->{known_oldest_year} and
         defined $era->{known_latest_year} and
         not $era->{known_oldest_year} <= $era->{known_latest_year};
  
  $era->{north_start_year} //= $era->{start_year}
      if defined $era->{north_end_year};
  $era->{south_start_year} //= $era->{start_year}
      if defined $era->{south_end_year};
  $era->{north_end_year} //= $era->{end_year}
      if defined $era->{north_start_year};
  $era->{south_end_year} //= $era->{end_year}
      if defined $era->{south_start_year};
  $era->{north_start_day} //= $era->{start_day}
      if defined $era->{north_end_day};
  $era->{south_start_day} //= $era->{start_day}
      if defined $era->{south_end_day};
  $era->{north_end_day} //= $era->{end_day}
      if defined $era->{north_start_day};
  $era->{south_end_day} //= $era->{end_day}
      if defined $era->{south_start_day};
  $era->{north_official_start_day} //= $era->{official_start_day}
      if defined $era->{north_end_day};
  $era->{south_official_start_day} //= $era->{official_start_day}
      if defined $era->{south_end_day};
  $era->{north_actual_end_day} //= $era->{actual_end_day}
      if defined $era->{north_start_day};
  $era->{south_actual_end_day} //= $era->{actual_end_day}
      if defined $era->{south_start_day};
  if (defined $era->{north_official_start_day} and
      not grep {
        $_->{next_era_ids}->{$era->{id}} and 
        $_->{type} eq 'firstday' and
        $_->{tag_ids}->{1065}; # 日本北朝
      } @$era_trs and
      grep {
        $_->{next_era_ids}->{$era->{id}} and 
        $_->{type} eq 'firstday' and
        $_->{tag_ids}->{1066}; # 日本南朝
      } @$era_trs) {
    $era->{north_official_start_day} = $era->{north_start_day};
  }
  if (defined $era->{south_official_start_day} and
      not grep {
        $_->{next_era_ids}->{$era->{id}} and 
        $_->{type} eq 'firstday' and
        $_->{tag_ids}->{1066}; # 日本南朝
      } @$era_trs and
      grep {
        $_->{next_era_ids}->{$era->{id}} and 
        $_->{type} eq 'firstday' and
        $_->{tag_ids}->{1065}; # 日本北朝
      } @$era_trs) {
    $era->{south_official_start_day} = $era->{south_start_day};
  }
  if (defined $era->{south_actual_end_day} and
      not grep {
        $_->{prev_era_ids}->{$era->{id}} and 
        $_->{type} eq 'firstday' and
        $_->{tag_ids}->{1066}; # 日本南朝
      } @$era_trs) {
    $era->{south_actual_end_day} = ssday $era->{south_end_day}->{jd} + 1, $era->{tag_ids};
  }
  if ($era->{key} eq '持統天皇') {
    $era->{actual_end_day} = ssday $era->{end_day}->{jd} + 1, $era->{tag_ids};
  } elsif ($era->{key} eq '白雉') {
    $era->{actual_end_day} = $era->{end_day};
  } elsif ($era->{key} eq '天平宝字') {
    $era->{official_start_day} = $era->{start_day};
  }

  if (($era->{jp_north_era} or $era->{jp_south_era}) and
      not ($era->{jp_north_era} and $era->{jp_south_era})) {
    delete $era->{$_} for qw(official_start_day actual_end_day);
  }
  unless ($era->{jp_north_era}) {
    delete $era->{$_} for qw(north_start_year north_end_year
                             north_start_day north_end_day
                             north_official_start_day 
                             north_actual_end_day);
  }
  unless ($era->{jp_south_era}) {
    delete $era->{$_} for qw(south_start_year south_end_year
                             south_start_day south_end_day
                             south_official_start_day 
                             south_actual_end_day);
  }

  if ($era->{jp_era} or
      $era->{jp_north_era} or
      $era->{jp_south_era} or
      $era->{jp_emperor_era}) {
    for (qw(start_day end_day
            north_start_day north_end_day
            south_start_day south_end_day
            official_start_day
            north_official_start_day south_official_start_day
            actual_end_day
            north_actual_end_day south_actual_end_day)) {
      next unless defined $era->{$_};
      $era->{$_} = {%{$era->{$_}}};
      set_day_era_dates $era->{$_}, $era;
    }
  }

  if ($era->{jp_era} and
      defined $era->{end_year} and
      $era->{end_year} > 1475 and
      $era->{start_year} < 1868) {
    set_object_tag $era, '樺太';
  }

  if (defined $era->{start_year} and
      not defined $era->{end_year}) {
    set_object_tag $era, '継続中';
    my $duration = $ThisYear - $era->{start_year} + 1;
    if ($duration > 60) {
      set_object_tag $era, '継続60年超';
    }
  } elsif (defined $era->{known_latest_year} and
           $era->{known_latest_year} + $RecentYears >= $ThisYear) {
    set_object_tag $era, '利用中';
    if (defined $era->{start_year}) {
      my $duration = $era->{end_year} - $era->{start_year} + 1;
      if ($duration > 60) {
        set_object_tag $era, '継続60年超';
      }
    }
    my $duration = $ThisYear - $era->{known_oldest_year} + 1;
    if ($duration > 60) {
      set_object_tag $era, '利用60年超';
    }
  } else {
    if (defined $era->{start_year}) {
      my $duration = $era->{end_year} - $era->{start_year} + 1;
      if ($duration > 60) {
        set_object_tag $era, '継続60年超';
      }
    }
    if (defined $era->{known_oldest_year}) {
      my $duration = $era->{known_latest_year} - $era->{known_oldest_year} + 1;
      if ($duration > 60) {
        set_object_tag $era, '利用60年超';
      }
    }
  }

  if (not defined $era->{offset}) {
    set_object_tag $era, '年不詳';
  }

  delete $era->{_FORM_GROUP_ONS};
  delete $era->{_TEMP};
} # era

for my $key (sort { $a cmp $b } keys %$EraTags) {
  my $era = $Data->{eras}->{$key};
  for my $tag_key (sort { $a cmp $b } keys %{$EraTags->{$key}}) {
    set_object_tag $era, $tag_key;
  }
}

delete $Data->{_ONS};
delete $Data->{_TRANSITIONS};

print perl2json_bytes_for_record $Data;

## License: Public Domain.
