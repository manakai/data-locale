use strict;
use warnings;
use utf8;
use JSON::PS;
use Path::Tiny;

my $root_path = path (__FILE__)->parent->parent;

my $systems_path = $root_path->child ('data/calendar/era-systems.json');
my $systems = json_bytes2perl $systems_path->slurp;

my $defs_path = $root_path->child ('local/era-defs-jp.json');
my $defs = json_bytes2perl $defs_path->slurp;

my $defs_e_path = $root_path->child ('local/era-defs-jp-emperor.json');
my $defs_e = json_bytes2perl $defs_e_path->slurp;

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

my $g2k_map_path = $root_path->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};
my $k2g_map = {reverse %$g2k_map};

sub k2g ($) {
  return $k2g_map->{$_[0]} or die "Kyuureki |$_[0]| is not defined";
} # k2g

sub g2k ($) {
  return $g2k_map->{$_[0]} or die "Gregorian |$_[0]| is not defined";
} # g2k

use POSIX;
sub j_ymd2g_ymd ($$$) {
  my ($jy, $jm, $jd) = @_;
  my $y = $jy + floor (($jm - 3) / 12);
  my $m = ($jm - 3) % 12;
  my $d = $jd - 1;
  my $n = $d + floor ((153 * $m + 2) / 5) + 365 * $y + floor ($y / 4);
  my $mjd = $n - 678883;
  my $time = ($mjd + 2400000.5 - 2440587.5) * 24 * 60 * 60;
  my @time = gmtime $time;
  return ($time[5]+1900, $time[4]+1, $time[3]);
} # j_ymd2g_ymd

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

sub day ($$) {
  my ($jd, $era_def) = @_;
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
          julian_era => (sprintf '%s%d-%02d-%02d', $era_def->{key}, $j_y - $era_def->{offset}, $j_m, $j_d),
          gregorian_era => (sprintf '%s%d-%02d-%02d', $era_def->{key}, $y - $era_def->{offset}, $m, $d),
          kyuureki_era => (sprintf '%s%d-%s', $era_def->{key}, $k_y - $era_def->{offset}, $k_md)};
} # day

my $Data = {};

sub process ($$$) {
  my ($system_name, $key_name, $prefix_name) = @_;

my $year = -99999;
my $current_era_data = undef;
my $current_era_def = undef;
for my $point (@{$systems->{systems}->{$system_name}->{points}}) {
  if ($point->[0] eq 'jd') {
    my ($y, $m, $d) = jd2g_ymd ($point->[1]);
    if (defined $current_era_data) {
      my $prefix = $current_era_def->{$key_name} ? $prefix_name : '';
      if ($y < 1900) {
        $current_era_data->{$prefix.'end_day'} = day ($point->[1] - 1, $current_era_def);
        $current_era_data->{$prefix.'actual_end_day'} = day ($point->[1], $current_era_def);
        $current_era_data->{$prefix.'end_day'}->{kyuureki} =~ /^(-?[0-9]+)/ or die;
        $current_era_data->{$prefix.'end_year'} = 0+$1;
      } else {
        if ($y > 1980) {
          $current_era_data->{$prefix.'end_day'} =
          $current_era_data->{$prefix.'actual_end_day'} = day ($point->[1] - 1, $current_era_def);
        } else {
          $current_era_data->{$prefix.'end_day'} = day ($point->[1] - 1, $current_era_def);
          $current_era_data->{$prefix.'actual_end_day'} = day ($point->[1], $current_era_def);
        }
        $current_era_data->{$prefix.'end_day'}->{gregorian} =~ /^(-?[0-9]+)/ or die;
        $current_era_data->{$prefix.'end_year'} = 0+$1;
      }
    }
    if (defined $point->[2]) {
      if ($system_name eq 'jp-north' and $point->[2] eq '正平') {
        $current_era_data = {key => $point->[2]};
      } else {
        $current_era_data = $Data->{eras}->{$point->[2]} ||= {key => $point->[2]};
      }
      $current_era_def = $defs->{eras}->{$current_era_data->{key}} ||
                         $defs_e->{eras}->{$current_era_data->{key}}
          || die "Era |$current_era_data->{key}| not defined";
      my $prefix = $current_era_def->{$key_name} ? $prefix_name : '';
      $current_era_data->{$prefix.'start_day'} ||= day ($point->[1], $current_era_def);
      if ($y < 1900) {
        $current_era_data->{$prefix.'start_day'}->{kyuureki} =~ /^(-?[0-9]+)/ or die;
        $current_era_data->{$prefix.'start_year'} = $year = 0+$1;
        $current_era_data->{$prefix.'official_start_day'} = day g2jd (k2g ymd2string $current_era_def->{offset} + 1, 1, 1), $current_era_def
            if $defs->{eras}->{$current_era_data->{key}};
      } else {
        $current_era_data->{$prefix.'start_day'}->{gregorian} =~ /^(-?[0-9]+)/ or die;
        $current_era_data->{$prefix.'start_year'} = $year = 0+$1;
        $current_era_data->{$prefix.'official_start_day'} = $current_era_data->{$prefix.'start_day'};
      }
    } else {
      $current_era_data = undef;
      $current_era_def = undef;
    }
  } elsif ($point->[0] eq 'y') {
    if (defined $current_era_data) {
      if ($current_era_data->{start_year} < $point->[1] - 1) {
        $current_era_data->{end_year} = $point->[1] - 1;
      } else {
        $current_era_data->{end_year} = $current_era_data->{start_year};
      }
      $current_era_data->{end_kyuureki_day} = day g2jd (k2g ymd2string $current_era_data->{end_year} + 1, 1, 1) - 1, $current_era_def;
      $current_era_data->{end_gregorian_day} = day g2jd (ymd2string $current_era_data->{end_year} + 1, 1, 1) - 1, $current_era_def;
      $current_era_data->{end_julian_day} = day g2jd (&ymd2string (j_ymd2g_ymd $current_era_data->{end_year} + 1, 1, 1)) - 1, $current_era_def;
    }
    if (defined $point->[2]) {
      $current_era_data = $Data->{eras}->{$point->[2]} ||= {key => $point->[2]};
      $current_era_def = $defs->{eras}->{$current_era_data->{key}} ||
                         $defs_e->{eras}->{$current_era_data->{key}}
              || die "Era |$current_era_data->{key}| not defined";
      $current_era_data->{start_year} = $year = $point->[1];
      $current_era_data->{start_kyuureki_day} = day g2jd (k2g ymd2string $current_era_data->{start_year}, 1, 1), $current_era_def;
      $current_era_data->{start_gregorian_day} = day g2jd (ymd2string $current_era_data->{start_year}, 1, 1), $current_era_def;
      $current_era_data->{start_julian_day} = day g2jd (&ymd2string (j_ymd2g_ymd $current_era_data->{start_year}, 1, 1)), $current_era_def;
    } else {
      $current_era_data = undef;
    }
  } else {
    die "Unknown point type |$point->[0]|";
  }
}
} # process

process 'jp-north', 'jp_north_era', 'north_';
process 'jp-south', 'jp_south_era', 'south_';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
