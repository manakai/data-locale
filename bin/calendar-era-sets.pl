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

  sub _daygm {

    # This is written in such a byzantine way in order to avoid
    # lexical variables and sub calls, for speed
    return $_[3] + (
        $Cheat{ pack( 'ss', @_[ 4, 5 ] ) } ||= do {
            my $month = ( $_[4] + 10 ) % 12;
            my $year  = $_[5] + 1900 - int($month / 10);

            ( ( 365 * $year )
              + int( $year / 4 )
              - int( $year / 100 )
              + int( $year / 400 )
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
  my ($y, $m, $d) = split /-/, $_[0];

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
      push @{$Vars->{$var_name} ||= []}, [(int g2jd $1), $2];
    } elsif (defined $def_name and /^g:([0-9-]+)\s+(\w+)$/) {
      push @{$Defs->{$def_name} ||= []}, [(int g2jd $1), $2];
    } elsif (defined $var_name and /^k:([0-9'-]+)\s+(\w+)$/) {
      push @{$Vars->{$var_name} ||= []}, [(int g2jd k2g $1), $2];
    } elsif (defined $def_name and /^k:([0-9'-]+)\s+(\w+)$/) {
      push @{$Defs->{$def_name} ||= []}, [(int g2jd k2g $1), $2];
    } elsif (defined $var_name and /^\+\$([\w-]+)$/) {
      push @{$Vars->{$var_name} ||= []}, $1;
    } elsif (defined $def_name and /^\+\$([\w-]+)$/) {
      push @{$Defs->{$def_name} ||= []}, $1;
    } elsif (defined $var_name and /^-(\d+)\s+(\d+)$/) {
      push @{$Vars->{$var_name} ||= []},
          {type => 'remove',
           start => (int g2jd k2g "$1-01-01"),
           end => (int g2jd k2g sprintf '%04d-01-01', $2 + 1)};
    } elsif (defined $def_name and /^-(\d+)\s+(\d+)$/) {
      push @{$Defs->{$def_name} ||= []},
          {type => 'remove',
           start => (int g2jd k2g "$1-01-01"),
           end => (int g2jd k2g sprintf '%04d-01-01', $2 + 1)};
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
      not ($op->{start} <= $_->[0] and $_->[0] <= $op->{end});
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
        $_->[1] = undef if defined $_->[1] and $_->[1] eq 'null';
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
        $_->[1] = undef if defined $_->[1] and $_->[1] eq 'null';
        push @$def, $_;
      }
    } else {
      push @$def, @{expand_var $_};
    }
  }
  $Data->{sets}->{$def_name}->{points} = [sort { $a->[0] <=> $b->[0] } @$def];
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
