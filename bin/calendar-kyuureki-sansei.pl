use strict;
use warnings;
use JSON::PS;

my $Data = {};

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

  use POSIX qw(floor);
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

my $map = q{

-214-2-4+0 121212121212
1121212121212 6

-212-2-11+0 121211212121
212121211212
1212121212121 2
121212121212
1212112121212 10
121212121121
212121212121
1212121212121 7
212112121212
121212121121

-202-1-23+0 2121212121211 4
212121212121
212112121212
1212121211212 1
121212121211
2121212121212 9
121121212121
212121211212
1212121212112 5
121212121212

-192-2-1+0 121121212121
2121212112121 2
212121212112
1212121212121 11
211212121212
121212112121
2121212121121 7
212121212121
211212121212
1212121121212 3


-2-2-2+0 121211212121
2121212121121 2
212121212121
2112121212121 11
212112121212
121212121121
2121212121212 8
112121212121
212112121212
1212121211212 4

9-2-11+0 121212121212
1121212121212 12
121121212121
212121211212
1212121212121 9
121212121212
121211212121
2121212112121 6
212121212121
121212121212

};

sub gdate ($$$) {
  my ($y, $m, $d) = @_;
  my $dv = timegm_nocheck 0, 0, 0, $d, $m-1, $y;
  my @result = gmtime $dv;
  my $x = sprintf '%04d-%02d-%02d',
      $result[5]+1900, $result[4]+1, $result[3];
  $x =~ s/^-(\d{3})-/-0$1-/;
  return $x;
} # gdate

my $next_ymd;
for (split /\x0D?\x0A/, $map) {
  if (/^(-?\d+)-(\d+)-(\d+)\+(\d+)\s+([012]{12,13})(?:\s+(\d+))?$/) {
    my ($y, $m, $d) = ($1, $2, $3);
    $y++ if $y < 0;
    my $delta = $4;
    my $mt = $5;
    $mt =~ tr/2/0/;
    my $leap_month = $6;

    my @month = map { sprintf '%02d', $_ } 1..12;
    splice @month, $leap_month, 0, (sprintf "%02d'", $leap_month)
        if defined $leap_month;

    my $month_index = 0;
    for (split //, $mt) {
      my $new = gdate $y, $m, $d + $delta;
      my $old = sprintf '%04d-%s-01', $y, $month[$month_index];
      $old =~ s/^-(\d{3})-/-0$1-/g;
      $Data->{mapping}->{$new} = $old;
      $month_index++;
      $delta += 29 + $_;
    }
    my $is_leap_year = (($y % 4) == 0 and
                        not (($y % 100 == 0) and not ($y % 400 == 0)));
    my $ld = $is_leap_year ? 1 : 0;
    $next_ymd = [$y + 1, $y, $m, $d + $delta];
  } elsif (/^([012]{12,13})(?:\s+(\d+))?$/) {
    my ($y, $b_y, $m, $d) = @$next_ymd;
    my $delta = 0;
    my $mt = $1;
    $mt =~ tr/2/0/;
    my $leap_month = $2;

    my @month = map { sprintf '%02d', $_ } 1..12;
    splice @month, $leap_month, 0, (sprintf "%02d'", $leap_month)
        if defined $leap_month;

    my $month_index = 0;
    for (split //, $mt) {
      my $new = gdate $b_y, $m, $d + $delta;
      my $old = sprintf '%04d-%s-01', $y, $month[$month_index];
      $old =~ s/^-(\d{3})-/-0$1-/;
      $Data->{mapping}->{$new} = $old;
      $month_index++;
      $delta += 29 + $_;
    }
    my $is_leap_year = (($y % 4) == 0 and
                        not (($y % 100 == 0) and not ($y % 400 == 0)));
    my $ld = $is_leap_year ? 1 : 0;
    $next_ymd = [$y + 1, $b_y, $m, $d + $delta];
  } elsif (/^\s*#/) {
    #
  } elsif (/\S/) {
    die "Bad line: $_";
  }
}

my $list = q{
0576-02-17	0576-01-01
0576-03-18	0576-02-01
0576-04-16	0576-03-01
0576-05-16	0576-04-01
0576-06-14	0576-05-01
0576-07-14	0576-06-01
0576-08-12	0576-07-01
0576-09-11	0576-08-01
0576-10-10	0576-09-01
0576-11-09	0576-10-01
0576-12-09	0576-11-01
0577-01-07	0576-12-01
0577-02-06	0577-01-01
0577-03-07	0577-02-01
0577-04-06	0577-03-01
0577-05-05	0577-04-01
0577-06-04	0577-05-01
0577-07-03	0577-06-01
0577-08-02	0577-07-01
0577-08-31	0577-08-01
0577-09-30	0577-09-01
0577-10-29	0577-10-01
0577-11-28	0577-11-01
0577-12-27	0577-12-01
0791-02-12	0791-01-01
0791-03-13	0791-02-01
0791-04-12	0791-03-01
0791-05-12	0791-04-01
0791-06-11	0791-05-01
0791-07-11	0791-06-01
0791-08-09	0791-07-01
0791-09-07	0791-08-01
0791-10-06	0791-09-01
0791-11-05	0791-10-01
0791-12-04	0791-11-01
0792-01-03	0791-12-01
};
for (split /\n/, $list) {
  my ($new, $old) = split /\t/, $_;
  $Data->{mapping}->{$new} = $old if defined $old;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.

