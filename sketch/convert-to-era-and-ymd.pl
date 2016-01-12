use strict;
use warnings;
use Encode;
use Path::Tiny;
use JSON::PS;
binmode STDOUT, qw(:encoding(utf-8));

my $date = shift;
die "Usage: perl $0 year-month-day\n" unless defined $date;

my $root_path = path (__FILE__)->parent->parent;

my $json_path = $root_path->child ('data/calendar/era-defs.json');
my $json = json_bytes2perl $json_path->slurp;

my $json2_path = $root_path->child ('data/calendar/era-sets.json');
my $json2 = json_bytes2perl $json2_path->slurp;

#use Time::Local qw(timegm_nocheck);
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

my $g2k_map_path = $root_path->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};
my $k2g_map = {reverse %$g2k_map};

my ($year, $month, $day);
if ($date =~ /^kyuureki:(-?\d+)-(\d+)('|)-(\d+)$/) {
  my $d = sprintf '%04d-%02d%s-%02d', $1, $2, $3, $4;
  my $e = $k2g_map->{$d} or die "Kyuureki |$d| is not defined";
  ($year, $month, $day) = split /(?<=.)-/, $e;
  #warn "Kyuureki |$d| is Gregorian |$e|\n";
} else {
  ($year, $month, $day) = split /(?<=.)-/, $date;
}

## "get era and era year"
sub get_era_and_era_year ($$$) {
  my ($def, $unix, $year) = @_;
  my $jd = $unix / (24*60*60) + 2440587.5;

  my $era;
  E: {
    for (reverse @{$def}) {
      $era = $_->[2];
      last E if $_->[0] eq 'jd' and $_->[1] <= $jd;
      last E if $_->[0] eq 'y' and $_->[1] <= $year;
    }
    $era = undef;
  } # E

  my $era_year;
  my $data;
  if (defined $era) {
    $data = $json->{eras}->{$era};
    die "Era |$era| not found" unless defined $data;
    $era_year = $year - $data->{offset};
  } else {
    $data = {offset => 0};
    $era = 'AD';
    $era_year = $year;
  }
  return ($era, $era_year);
} # get_era_and_era_year

my $unix = timegm_nocheck 0, 0, 0, $day, $month-1, $year;
print "Gregorian (AD, $year, $month, $day)\n";
for my $map_name (sort { $a cmp $b } keys %{$json2->{sets}}) {
  my ($g_era, $g_era_year) = get_era_and_era_year $json2->{sets}->{$map_name}->{points}, $unix, $year;
  print "$map_name: Gregorian ($g_era, $g_era_year, $month, $day)\n";
}

my $g = sprintf '%04d-%02d-%02d', $year, $month, $day;
my $k = $g2k_map->{$g};
if (defined $k) {
  my ($k_y, $k_m, $k_d) = split /-/, $k;
  print "Kyuureki (AD, $k_y, $k_m, $k_d)\n";
  for my $map_name (sort { $a cmp $b } keys %{$json2->{sets}}) {
    my ($k_era, $k_era_year) = get_era_and_era_year $json2->{sets}->{$map_name}->{points}, $unix, $k_y;
    print "$map_name: Kyuureki ($k_era, $k_era_year, $k_m, $k_d)\n";
  }
} else {
  print "Kyuureki for Gregorian (AD, $year, $month, $day) is not defined\n";
}

## License: Public Domain.
