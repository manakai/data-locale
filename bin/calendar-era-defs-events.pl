use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $DataPath = $RootPath->child ('local/calendar-era-defs-0.json');
my $Data = json_bytes2perl $DataPath->slurp;

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
  明 => 'zuitou',
  清 => 'shin',
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

  if ($g eq '明' and (1663 <= $y and $y <= 1683+1)) {
    ## No calendar available
    $g = '清';
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
        die "Bad date ($g, $y, $m, $lm, $d)";
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

  if ($tag_ids->{1008} or # 中国
      $tag_ids->{1009}) { # 漢土
    if ($y >= 1645+1) {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '清', $y, $m, $d;
    } else {
      $day->{nongli_tiger} = ymmd2string gymd2nymmd '明', $y, $m, $d;
    }
  }
  
  return $day;
} # ssday

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

sub parse_date ($$;%) {
  my ($all, $v, %args) = @_;

  my @jd;
  while (length $v) {
    if ($v =~ s{^([0-9]+)-([0-9]+)-([0-9]+)\s*}{}) {
      push @jd, gymd2jd $1, $2, $3; # XXX
    } elsif ($v =~ s{^g:([0-9]+)-([0-9]+)-([0-9]+)\s*}{}) {
      push @jd, gymd2jd $1, $2, $3;
    } elsif ($v =~ s{^(明|清):([0-9]+)(?:\((\w\w)\)|)-([0-9]+)('|)-([0-9]+)\((\w\w)\)\s*}{}) {
      push @jd, nymmd2jd $1, $2, $4, $5, $6;
      push @jd, nymmk2jd $1, $2, $4, $5, $7;
      if (defined $3) {
        my $ky2 = label_to_kanshi0 $3;
        my $ky1 = year2kanshi0 $2;
        unless ($ky1 == $ky2) {
          die "Year mismatch ($ky1 vs $ky2) |$all|";
        }
      }
    } elsif ($v =~ s{^(明|清):([0-9]+)-([0-9]+)('|)-([0-9]+)\s*}{}) {
      push @jd, nymmd2jd $1, $2, $3, $4, $5;
    } elsif ($v =~ s{^(明|清):([0-9]+)-([0-9]+)('|)-(\w\w)\s*}{}) {
      push @jd, nymmk2jd $1, $2, $3, $4, $5;
    } elsif ($v =~ s{^(明|清):([0-9]+)-([0-9]+)('|)\s*}{}) {
      if ($args{start}) {
        push @jd, nymmd2jd $1, $2, $3, $4, 1;
      } elsif ($args{end}) {
        push @jd, nymmd2jd $1, $2, $3, $4, '末';
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
    } elsif ($v =~ s{^(明|清):([0-9]+)\s*}{}) {
      if ($args{start}) {
        push @jd, nymmd2jd $1, $2, 1, '', 1;
      } elsif ($args{end}) {
        push @jd, -1 + nymmd2jd $1, $2+1, 1, '', 1;
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

$Data->{eras}->{干支年}->{id} = 0;
my $Transitions = [];
for my $tr (@{delete $Data->{_TRANSITIONS}}) {
  my $from_keys = [defined $tr->[0] ? split /,/, $tr->[0] : ()];
  my $to_keys = [defined $tr->[1] ? split /,/, $tr->[1] : ()];
  my $v = $tr->[2];
  my $x = {};

  my $tags = {};
  while ($v =~ s{\s*#(\w+)$}{}) {
    set_object_tag $tags, $1;
  }
  $x->{tag_ids} = $tags->{tag_ids} if keys %{$tags->{tag_ids} or {}};

  if ($v =~ m{^\[([^,]+)\]$}) {
    my $jd1 = parse_date $tr->[2], $1, start => 1;
    my $jd2 = parse_date $tr->[2], $1, end => 1;
    $x->{day_start} = (ssday $jd1, $tags->{tag_ids});
    $x->{day_end} = (ssday $jd2, $tags->{tag_ids});
  } elsif ($v =~ m{^\[([^,]+),([^,]+)\]$}) {
    my $jd1 = parse_date $tr->[2], $1, start => 1;
    my $jd2 = parse_date $tr->[2], $2, end => 1;
    $x->{day_start} = (ssday $jd1, $tags->{tag_ids});
    $x->{day_end} = (ssday $jd2, $tags->{tag_ids});
  } else {
    my $jd = parse_date $tr->[2], $v;
    $x->{day} = (ssday $jd, $tags->{tag_ids});
  }
  if (defined $x->{day_start} and
      not $x->{day_start}->{jd} < $x->{day_end}->{jd}) {
    die "Bad date range [$x->{day_start}->{jd}, $x->{day_end}->{jd}] ($tr->[2])";
  }

  if ($x->{tag_ids}->{1186} and # 適用開始日
      defined $x->{day}) {
    my $y = json_bytes2perl perl2json_bytes $x;

    delete $y->{tag_ids}->{1278}; # 適用開始
    delete $y->{tag_ids}->{1186}; # 適用開始日
    delete $y->{tag_ids}->{1188}; # 年始改元実施
    delete $y->{tag_ids}->{1215}; # 年始改元実施予定
    delete $y->{tag_ids}->{1221}; # 月始改元実施
    set_object_tag $y, '適用開始前日';

    $y->{day} = ssday $x->{day}->{jd} - 1, $y->{tag_ids};
    
    push @$Transitions, [$from_keys, $to_keys, $y, $tr->[2]];
  }
  
  push @$Transitions, [$from_keys, $to_keys, $x, $tr->[2]];
} # $tr
for (@$Transitions) {
  my ($from_keys, $to_keys, $x, $source) = @$_;

  my $type;
  if ($x->{tag_ids}->{1278}) { # 適用開始
    $type = 'firstday';
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1277}) { # 適用開始前日
    $type = 'prevfirstday';
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1182} or # 制定
           $x->{tag_ids}->{1264}) { # 発表
    $type = 'proclaimed';
  } elsif ($x->{tag_ids}->{1185}) { # 利用開始
    $type = 'established';
    if ($x->{tag_ids}->{1200}) { # 旧説
      $type .= '/incorrect';
    } elsif ($x->{tag_ids}->{1198}) { # 異説
      $type .= '/possible';
    }
  } elsif ($x->{tag_ids}->{1124}) { # 実施中止
    $type = 'canceled';
  } elsif ($x->{tag_ids}->{1191}) { # 事由
    $type = 'triggering';
  } elsif ($x->{tag_ids}->{1230}) { # 戦時異動
    $type = 'wartime';
  } else {
    if (@$from_keys and not @$to_keys) {
      $type = 'other';
    } else {
      $type = 'established';
      #XXXdie "No action tag |$v|";
    }
  }
  $x->{type} = $type;

  if (@$from_keys and not @$to_keys) {
    die "Bad transition type |$x->{type}| ($source)"
        unless $x->{type} eq 'other';
    for my $from_key (@$from_keys) {
      push @{$Data->{eras}->{$from_key}->{transitions} ||= []},
          {direction => 'other', %$x};
    }
  } else {
    for my $to_key (@$to_keys) {
      my $w = {direction => 'incoming', %$x};
      for my $from_key (@$from_keys) {
        next if $from_key eq '干支年';
        my $def = $Data->{eras}->{$from_key}
            // die "Bad era key |$from_key| ($source)";
        $w->{prev_era_ids}->{$def->{id}} = $from_key;
      }
      push @{$Data->{eras}->{$to_key}->{transitions} ||= []}, $w;
    }
    for my $from_key (@$from_keys) {
      my $w = {direction => 'outgoing', %$x};
      for my $to_key (@$to_keys) {
        next if $to_key eq '干支年';
        my $def = $Data->{eras}->{$to_key}
            // die "Bad era key |$to_key| ($source)";
        $w->{next_era_ids}->{$def->{id}} = $to_key;
      }
      push @{$Data->{eras}->{$from_key}->{transitions} ||= []}, $w;
    }
  }
} # $tr
delete $Data->{eras}->{干支年};

for (values %{$Data->{eras}}) {
  $_->{table_oldest_year} //= $_->{known_oldest_year}
      if defined $_->{known_oldest_year};
  $_->{table_latest_year} //= $_->{known_latest_year}
      if defined $_->{known_latest_year};
  
  $_->{transitions} = [map { $_->[0] } sort {
    $a->[1] <=> $b->[1] ||
    $a->[2] <=> $b->[2];
  } map {
    [$_,
     ($_->{day} || $_->{day_start} || {})->{mjd},
     ($_->{day} || $_->{day_end} || {})->{mjd}];
  } @{$_->{transitions} ||= []}];

  for my $tr (@{$_->{transitions}}) {
    for my $dk (grep { defined $tr->{$_} } qw(day day_start day_end)) {
      for my $key (qw(gregorian julian kyuureki nongli_tiger)) {
        next unless defined $tr->{$dk}->{$key};
        if ($tr->{$dk}->{$key} =~ m{^(-?[0-9]+)}) {
          my $year = $1;
          if ({
            dayretroactivated => 1,
            decreed => 1,
            firstday => 1,
            'firstday/possible' => 1,
            'firstday/incorrect' => 1,
            prevfirstday => $tr->{direction} eq 'outgoing',
            'prevfirstday/possible' => $tr->{direction} eq 'outgoing',
            'prevfirstday/incorrect' => $tr->{direction} eq 'outgoing',
            'established' => 1,
            'established/possible' => 1,
            'established/incorrect' => 1,
            received => 1,
            retroactivated => 1,
            'shogunate-enforced' => 1,
            'wartime' => 1,
            'year-end' => 1,
            'year-start' => 1,
          }->{$tr->{type}}) {
            $_->{known_oldest_year} //= $year;
            $_->{known_oldest_year} = $year if $year < $_->{known_oldest_year};
            $_->{known_latest_year} //= $year;
            $_->{known_latest_year} = $year if $_->{known_latest_year} < $year;
          }

          $_->{table_oldest_year} //= $year;
          $_->{table_oldest_year} = $year if $year < $_->{table_oldest_year};
          $_->{table_latest_year} //= $year;
          $_->{table_latest_year} = $year if $_->{table_latest_year} < $year;
        }
      }
    }
  } # $tr
} # era

print perl2json_bytes_for_record $Data;

## License: Public Domain.
