use strict;
use warnings;
use utf8;
use JSON::PS;
use Path::Tiny;

my $root_path = path (__FILE__)->parent->parent;

my $g2k_map_path = $root_path->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};
my $k2g_map = {reverse %$g2k_map};

sub k2g ($) {
  return $k2g_map->{$_[0]} or die "Kyuureki |$_[0]| is not defined";
} # k2g

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

my $Data = {};

my $Defs = {};
my $Vars = {};
for my $path ($root_path->child ('src/eras')->children (qr{\.txt$})) {
  my $var_name;
  my $def_name;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\$([\w-]+):$/) {
      $var_name = $1;
      $def_name = undef;
    } elsif (/^\*([\w-]+):$/) {
      $def_name = $1;
      $var_name = undef;
    } elsif (defined $var_name and /^g:([0-9-]+)\s+(\w+)$/) {
      push @{$Vars->{$var_name} ||= []}, ['jd', (g2jd $1), $2];
    } elsif (defined $def_name and /^g:([0-9-]+)\s+(\w+)$/) {
      push @{$Defs->{$def_name} ||= []}, ['jd', (g2jd $1), $2];
    } elsif (defined $var_name and /^k:([0-9'-]+)\s+(\w+)$/) {
      push @{$Vars->{$var_name} ||= []}, ['jd', (g2jd k2g $1), $2];
    } elsif (defined $def_name and /^k:([0-9'-]+)\s+(\w+)$/) {
      push @{$Defs->{$def_name} ||= []}, ['jd', (g2jd k2g $1), $2];
    } elsif (defined $var_name and /^y:(-?[0-9]+)\s+(\w+)$/) {
      push @{$Vars->{$var_name} ||= []}, ['y', 0+$1, $2];
    } elsif (defined $def_name and /^y:(-?[0-9]+)\s+(\w+)$/) {
      push @{$Defs->{$def_name} ||= []}, ['y', 0+$1, $2];
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
        $_->[2] = undef if defined $_->[2] and $_->[2] eq 'null';
        $_->[3] = $_->[0] eq 'jd' ? $_->[1] : g2jd "$_->[1]-01-01";
        push @$def, $_;
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
        $_->[2] = undef if defined $_->[2] and $_->[2] eq 'null';
        $_->[3] = $_->[0] eq 'jd' ? $_->[1] : g2jd "$_->[1]-01-01";
        push @$def, $_;
      }
    } else {
      push @$def, @{expand_var $_};
    }
  }
  $Data->{systems}->{$def_name}->{points} = [map { delete $_->[3]; $_ } sort { $a->[3] <=> $b->[3] } @$def];
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
