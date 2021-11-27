use strict;
use warnings;
use utf8;
use JSON::PS;
use Path::Tiny;

my $root_path = path (__FILE__)->parent->parent;

my $g2k_map_path = $root_path->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};
my $k2g_map = {reverse %$g2k_map};

my $g2rk_map_path = $root_path->child ('data/calendar/kyuureki-ryuukyuu-map.txt');
my $g2rk_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2rk_map_path->slurp};
my $rk2g_map = {reverse %$g2rk_map};

sub k2g ($) {
  return $k2g_map->{$_[0]} || die "Kyuureki |$_[0]| is not defined";
} # k2g

sub rk2g ($) {
  my $v = $_[0];
  if ($v =~ /^(\d+)-(\d+)$/) {
    $v = "$v-01";
  } elsif ($v =~ /^(\d+)$/) {
    $v = "$v-01-01";
  }
  return $rk2g_map->{$v} || die "Ryuukyuu kyuureki |$v| is not defined";
} # rk2g

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

sub mjd2jd ($) {
  return $_[0] + 2400000.5;
} # mjd2jd

my $Data = {};

my $Defs = {};
my $Vars = {};
for my $path (($root_path->child ('src/eras')->children (qr{\.txt$})),
              ($root_path->child ('local/eras')->children (qr{\.txt$}))) {
  my $var_name;
  my $def_name;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\$([\w-]+):$/) {
      $var_name = $1;
      $def_name = undef;
    } elsif (/^\*([\w-]+):$/) {
      $def_name = $1;
      $var_name = undef;
    } elsif (defined $var_name and /^jd:(-?[0-9.]+)\s+([\w()]+)$/) {
      push @{$Vars->{$var_name} ||= []}, ['jd', 0+$1, $2];
    } elsif (defined $var_name and /^mjd:(-?[0-9.]+)\s+([\w()]+)$/) {
      push @{$Vars->{$var_name} ||= []}, ['jd', mjd2jd $1, $2];
    } elsif (defined $var_name and /^g:([0-9-]+)\s+([\w()]+)$/) {
      push @{$Vars->{$var_name} ||= []}, ['jd', (g2jd $1), $2];
    } elsif (defined $def_name and /^g:([0-9-]+)\s+([\w()]+)$/) {
      push @{$Defs->{$def_name} ||= []}, ['jd', (g2jd $1), $2];
    } elsif (defined $var_name and /^k:([0-9'-]+)\s+([\w()]+)$/) {
      push @{$Vars->{$var_name} ||= []}, ['jd', (g2jd k2g $1), $2];
    } elsif (defined $def_name and /^k:([0-9'-]+)\s+([\w()]+)$/) {
      push @{$Defs->{$def_name} ||= []}, ['jd', (g2jd k2g $1), $2];
    } elsif (defined $var_name and /^rk:([0-9'-]+)\s+([\w()]+)$/) {
      push @{$Vars->{$var_name} ||= []}, ['jd', (g2jd rk2g $1), $2];
    } elsif (defined $def_name and /^rk:([0-9'-]+)\s+([\w()]+)$/) {
      push @{$Defs->{$def_name} ||= []}, ['jd', (g2jd rk2g $1), $2];
    } elsif (defined $var_name and /^\+\$([\w-]+)$/) {
      push @{$Vars->{$var_name} ||= []}, $1;
    } elsif (defined $def_name and /^\+\$([\w-]+)$/) {
      push @{$Defs->{$def_name} ||= []}, $1;
    } elsif (defined $var_name and /^-(\d+)\s+(\d+)$/) {
      push @{$Vars->{$var_name} ||= []},
          {type => 'remove',
           start_jd => (g2jd k2g "$1-01-01"),
           end_jd => (g2jd k2g sprintf '%04d-01-01', $2 + 1),
           start_y => $1, end_y => $2};
    } elsif (defined $def_name and /^-(\d+)\s+(\d+)$/) {
      push @{$Defs->{$def_name} ||= []},
          {type => 'remove',
           start_jd => (g2jd k2g "$1-01-01"),
           end_jd => (g2jd k2g sprintf '%04d-01-01', $2 + 1),
           start_y => $1, end_y => $2};
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

sub apply_op ($$) {
  my ($def, $op) = @_;
  if ($op->{type} eq 'remove') {
    @$def = grep {
      not ($_->[0] eq 'jd' and $op->{start_jd} <= $_->[1] and $_->[1] <= $op->{end_jd}) and
      not ($_->[0] eq 'y' and $op->{start_y} <= $_->[1] and $_->[1] <= $op->{end_y});
    } @$def;
  } else {
    die "Unknown operation type |$op->{type}|";
  }
} # apply_op

sub expand_var ($);
sub expand_var ($) {
  my $def = [];
  for (@{$Vars->{$_[0]} or die "Variable |$_[0]| not defined"}) {
    if (ref $_) {
      if (ref $_ eq 'HASH') {
        apply_op $def, $_;
      } else {
        my $v = [@$_];
        $v->[2] = undef if defined $v->[2] and $v->[2] eq 'null';
        $v->[3] = $v->[0] eq 'jd' ? $v->[1] : g2jd "$v->[1]-01-01";
        push @$def, $v;
      }
    } else {
      push @$def, @{expand_var $_};
    }
  }
  return $def;
} # expand_var

for my $def_name (keys %$Defs) {
  my $def = [];
  for (@{$Defs->{$def_name}}) {
    if (ref $_) {
      if (ref $_ eq 'HASH') {
        apply_op $def, $_;
      } else {
        my $v = [@$_];
        $v->[2] = undef if defined $v->[2] and $v->[2] eq 'null';
        $v->[3] = $v->[0] eq 'jd' ? $v->[1] : g2jd "$v->[1]-01-01";
        push @$def, $v;
      }
    } else {
      push @$def, @{expand_var $_};
    }
  }
  $Data->{systems}->{$def_name}->{points} = [map { delete $_->[3]; $_ } sort { $a->[3] <=> $b->[3] } @$def];
}

if (0) {
  my $path = $root_path->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  for my $sys_name (keys %{$Data->{systems}}) {
    for my $point (@{$Data->{systems}->{$sys_name}->{points}}) {
      my $key = $point->[2];
      my $era_def = $json->{eras}->{$key};
      die "Era |$key| not defined" unless defined $era_def;
      $point->[3] = $era_def->{offset};
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
