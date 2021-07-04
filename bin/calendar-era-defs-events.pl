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

my $KMaps = {};
my $GToKMapKey = {
  明 => 'zuitou',
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

  my $kmap = get_kmap ($g);

  my $gr;
  my $delta = 0;
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

  my $kanshi = jd2kanshi0 $jd;
  my $day = {jd => $jd,
             mjd => (jd2mjd $jd),
             kanshi0 => $kanshi,
             kanshi_label => (kanshi0_to_label $kanshi),
             gregorian => $g};

  if ($tag_ids->{1103}) { # 明
    $day->{nongli_tiger} = ymmd2string gymd2nymmd '明', $y, $m, $d;
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

for my $tr (@{delete $Data->{_TRANSITIONS}}) {
  my $from_key = $tr->[0];
  my $to_key = $tr->[1];
  my $v = $tr->[2];

  my $tags = {};
  while ($v =~ s{\s*#(\w+)$}{}) {
    set_object_tag $tags, $1;
  }
  my $x = {};
  $x->{tag_ids} = $tags->{tag_ids} if keys %{$tags->{tag_ids} or {}};

  my $jd;
  if ($v =~ m{^([0-9]+)-([0-9]+)-([0-9]+)$}) {
    $jd = gymd2jd $1, $2, $3;
  } elsif ($v =~ m{^(明):([0-9]+)-([0-9]+)('|)-([0-9]+)$}) {
    $jd = nymmd2jd $1, $2, $3, $4, $5;
  } elsif ($v =~ m{^(明):([0-9]+)-([0-9]+)('|)-(\w\w)$}) {
    $jd = nymmk2jd $1, $2, $3, $4, $5;
  } elsif ($v =~ m{^(明):([0-9]+)-([0-9]+)('|)-([0-9]+)\((\w\w)\)$}) {
    $jd = nymmd2jd $1, $2, $3, $4, $5;
    my $jd2 = nymmk2jd $1, $2, $3, $4, $6;
    unless ($jd == $jd2) {
      die "Date mismatch ($jd [$1 $2 $3 $4 $5] vs $jd2 [$1 $2 $3 $4 $6])";
    }
  } else {
    die "Bad transition |$v|";
  }

  push @{$Data->{eras}->{$to_key}->{starts} ||= []},
      {day => (ssday $jd, $tags->{tag_ids}),
       prev => $from_key,
       type => 'established', %$x};
  push @{$Data->{eras}->{$from_key}->{ends} ||= []},
      {day => (ssday $jd, $tags->{tag_ids}),
       next => $to_key,
       type => 'established', %$x};
} # $tr

print perl2json_bytes_for_record $Data;

## License: Public Domain.
