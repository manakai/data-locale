use strict;
use warnings;

{
  use utf8;
  my $IndexToKanshi = {map { my $x = $_; $x =~ s/\s+//g; $x =~ s/(\d+)/' '.($1-1).' '/ge;
                           grep { length } split /\s+/, $x } q{
1甲子2乙丑3丙寅4丁卯5戊辰6己巳7庚午8辛未9壬申10癸酉11甲戌12乙亥13丙子
14丁丑15戊寅16己卯17庚辰18辛巳19壬午20癸未21甲申22乙酉23丙戌24丁亥25戊子
26己丑27庚寅28辛卯29壬辰30癸巳31甲午32乙未33丙申34丁酉35戊戌36己亥
37庚子38辛丑39壬寅40癸卯41甲辰42乙巳43丙午44丁未45戊申46己酉47庚戌48辛亥
49壬子50癸丑51甲寅52乙卯53丙辰54丁巳55戊午56己未57庚申58辛酉59壬戌60癸亥
}};
  sub kanshi_string ($) { return $IndexToKanshi->{$_[0]} }
}

sub year2kanshi_year ($) { return (($_[0] - 4) % 60) }
sub jd2kanshi_day ($) { return (($_[0]+0.5+49) % 60); }

sub unix2jd ($) {
  return $_[0] / (24*60*60) + 2440587.5;
} # unix2jd

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

sub g_ymd2jd ($$$) {
  my ($y, $m, $d) = @_;

  my $unix = timegm_nocheck (0, 0, 0, $d, $m-1, $y);
  my $jd = unix2jd $unix;

  return $jd;
} # g_ymd2jd

sub jd2g_ymd ($) {
  my @time = gmtime (($_[0] - 2440587.5) * 24 * 60 * 60);
  return undef unless defined $time[5];
  return ($time[5]+1900, $time[4]+1, $time[3]);
} # jd2g_ymd

{
  my $in = shift || time;
  my $jd;
  if ($in =~ /^(-?[0-9]+)-([0-9]+)-([0-9]+)$/) {
    $jd = g_ymd2jd $1, $2, $3;
  } elsif ($in =~ /^[0-9]+(?:\.[0-9]+|)$/) {
    $jd = unix2jd 0+$in;
  } else {
    die "Bad input |$in|";
  }

  binmode STDOUT, qw(:utf8);
  printf "JD: %s\n", $jd;
  my ($y, $m, $d) = jd2g_ymd $jd;
  printf "G: %04d-%02d-%02d\n", $y, $m, $d;
  my $ky = year2kanshi_year $y;
  printf "Year: %s (%d)\n", kanshi_string $ky, $ky;
  my $kd = jd2kanshi_day $jd;
  printf "Day: %s (%d)\n", kanshi_string $kd, $kd;
}
