use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

my $g2k_map_path = $RootPath->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};
my $k2g_map = {reverse %$g2k_map};

sub k2g ($) {
  return $k2g_map->{$_[0]} || die "Kyuureki |$_[0]| is not defined";
} # k2g

sub g2k ($) {
  return $g2k_map->{$_[0]} || die "Gregorian |$_[0]| is not defined";
} # g2k

sub jp2g ($$$$) {
  my $d;
  if ($_[0] >= 1873) {
    return sprintf '%04d-%02d-%02d', $_[0], $_[1], $_[3];
  } elsif ($_[0] < 0) {
    $d = sprintf '-%04d-%02d%s-%02d', -$_[0], $_[1], $_[2]?"'":'', $_[3];
  } else {
    $d = sprintf '%04d-%02d%s-%02d', $_[0], $_[1], $_[2]?"'":'', $_[3];
  }
  return k2g $d;
} # jp2g

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

sub ymd2string ($$$) {
  if ($_[0] < 0) {
    return sprintf '-%04d-%02d-%02d', -$_[0], $_[1], $_[2];
  } else {
    return sprintf '%04d-%02d-%02d', $_[0], $_[1], $_[2];
  }
} # ymd2string

sub jd2jpy ($) {
  my ($y, $m, $d) = jd2g_ymd $_[0];
  if ($y >= 1873) {
    return $y;
  } else {
    my $k = g2k ymd2string $y, $m, $d;
    $k =~ /^(-?[0-9]+)/ or die;
    return 0+$1;
  }
} # jd2jpy

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

sub g2jd ($) {
  my ($y, $m, $d) = split /(?<=.)-/, $_[0];

  my $unix = timegm_nocheck (0, 0, 0, $d, $m-1, $y);
  my $jd = $unix / (24*60*60) + 2440587.5;

  return $jd;
} # g2jd

sub day ($$$) {
  my ($era_key, $era_first_year, $jd) = @_;
  my $era_offset = $era_first_year - 1;
  #my $jd = g2jd $g;
  my ($y, $m, $d) = jd2g_ymd ($jd);
  my ($j_y, $j_m, $j_d) = jd2j_ymd ($jd);
  my $g = ymd2string ($y, $m, $d);
  my $k = g2k $g;
  $k =~ /^(-?[0-9]+)-([0-9]+'?-[0-9]+)$/;
  my $k_y = $1;
  my $k_md = $2;
  die $k unless defined $k_md;
  return {jd => $jd,
          julian => ymd2string ($j_y, $j_m, $j_d),
          gregorian => $g,
          kyuureki => $k,
          julian_era => (sprintf '%s%d-%02d-%02d', $era_key, $j_y - $era_offset, $j_m, $j_d),
          gregorian_era => (sprintf '%s%d-%02d-%02d', $era_key, $y - $era_offset, $m, $d),
          kyuureki_era => (sprintf '%s%d-%s', $era_key, $k_y - $era_offset, $k_md)};
} # day

{
  my $prev;
  my $this;

  my $end_this = sub {
    return unless defined $this;
    
    die $this->{_key} if defined $Data->{eras}->{$this->{_key}};
    $Data->{eras}->{$this->{_key}} = $this;
    
    if (defined $prev and
        (not $this->{_next_key}->{north_} and
         not $this->{_next_key}->{south_})) {
      die if defined $prev->{_next_key}->{''};
      $prev->{_next_key}->{''} = $this->{_key};
    }
    
    $prev = $this->{_no_next} ? undef : $this;
  }; # $end_this
  
  my $path = $RootPath->child ('src/era-start-315.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^([0-9]+)-([0-9]+)('|)-([0-9]+)\s+(\w+)$/) {
      my ($y, $m, $lm, $d, $key) = ($1, $2, $3, $4, $5);
      my $g = jp2g ($y, $m, $lm, $d);
      $end_this->();
      $this = {_key => $key, _first_year => $y, _jd => g2jd $g};
    } elsif (s/^\s+//) {
      if (/^(not renaming year|start at day boundary|no next)$/) {
        my $k = $1;
        $k =~ s/ /_/g;
        $this->{'_'.$k} = 1;
      } elsif (/^(north|south) ->(\w+)(?: ([0-9]+)-([0-9]+)('|)-([0-9]+)|)$/) {
        $this->{_next_key}->{$1 . '_'} = $2;
        $this->{_next_jd}->{$1 . '_'} = g2jd jp2g $this->{_first_year}+$3-1, $4, $5, $6 if defined $3;
      } elsif (/\S/) {
        # XXX
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
  $end_this->();
}
{
  use utf8;
  $Data->{eras}->{嘉暦}->{_next_key}->{''} = '元徳';
}

for my $era (values %{$Data->{eras}}) {
  for my $pfx ('', 'north_', 'south_') {
    if (defined $era->{_next_jd}->{$pfx}) {
      my $next_era = $Data->{eras}->{$era->{_next_key}->{$pfx}}
          // die $era->{_next_key}->{$pfx};
      die $era->{_next_key}->{$pfx}
          if defined $next_era->{_jds}->{$pfx};
      $next_era->{_jds}->{$pfx} = $era->{_next_jd}->{$pfx};
    }
  }
}

for my $era (values %{$Data->{eras}}) {
  if (not $era->{_next_key}->{north_} and not $era->{_next_key}->{south_}) {
    $era->{jp_era} = 1;
  } elsif ($era->{_next_key}->{north_}) {
    $era->{jp_north_era} = 1;
  } elsif ($era->{_next_key}->{south_}) {
    $era->{jp_south_era} = 1;
  }

  for my $pfx ('', 'north_', 'south_') {
    next unless defined $era->{_next_key}->{$pfx} or
                ($pfx eq '' and
                 not defined $era->{_next_key}->{north_} and
                 not defined $era->{_next_key}->{south_});

    my $jd = $era->{_jds}->{$pfx} // $era->{_jd};
    $era->{$pfx.'start_year'} = jd2jpy $jd;
    $era->{$pfx.'start_day'} = day $era->{_key}, $era->{_first_year}, $jd;
    if ($era->{_not_renaming_year} or defined $era->{_jds}->{$pfx}) {
      $era->{$pfx.'official_start_day'} = $era->{$pfx.'start_day'};
    } else {
      $era->{$pfx.'official_start_day'}
          = day $era->{_key}, $era->{_first_year},
                (g2jd jp2g $era->{_first_year}, 1, 0, 1);
    }
  }

  for my $pfx ('', 'north_', 'south_') {
    next unless defined $era->{_next_key}->{$pfx};
    my $next_era = $Data->{eras}->{$era->{_next_key}->{$pfx}}
        // die $era->{_next_key}->{$pfx};
    my $jd = $next_era->{_jds}->{$pfx} // $next_era->{_jd};
    $era->{$pfx.'end_day'}
        = day $era->{_key}, $era->{_first_year}, $jd-1;
    if ($next_era->{_start_at_day_boundary}) {
      $era->{$pfx.'actual_end_day'}
          = day $era->{_key}, $era->{_first_year}, $jd-1;
      $era->{$pfx.'end_year'} = jd2jpy $jd-1;
    } else {
      $era->{$pfx.'actual_end_day'}
          = day $era->{_key}, $era->{_first_year}, $jd;
      $era->{$pfx.'end_year'} = jd2jpy $jd;
    }
  }
} # $era
{
  use utf8;
  delete $Data->{eras}->{明徳}->{$_} for qw(
    start_year start_day official_start_day
  );
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
