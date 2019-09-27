use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $Defs;
{
  my $json_path = $RootPath->child ('data/calendar/dts.json');
  $Defs = json_bytes2perl $json_path->slurp;
}

my $Key = shift or die;
my $DTSDef = $Defs->{dts}->{$Key} or die;

sub jd2g_ymdw ($) {
  my @time = gmtime (($_[0] - 2440587.5) * 24 * 60 * 60);
  return undef unless defined $time[5];
  return ($time[5]+1900, $time[4]+1, $time[3], $time[6]);
} # jd2g_ymdw

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
  sub year2kanshi ($) { $IndexToKanshi->{($_[0]-4)%60} }
}

sub to_dts ($$) {
  my $rules = shift;
  my $jd = shift;
  my ($y, $m, $d, $wd) = jd2g_ymdw $jd;

  use utf8;
  my $year = '';
  for my $rule (@$rules) {
    if (ref $rule) {
      if ($rule->[0] eq 'k') {
        $year .= year2kanshi $y;
      } elsif ($rule->[0] eq 'Y') {
        my $v = $y - $rule->[1];
        $v = '元' if $v == 1;
        $year .= $v;
      } elsif ($rule->[0] eq 'y') {
        my $v = $y - $rule->[1];
        $year .= $v;
      } else {
        die $rule->[0];
      }
    } else {
      $year .= $rule;
    }
  }

  $wd = (qw(日 月 火 水 木 金 土))[$wd];

  if ($Key eq 'dtsjp2') {
    return sprintf '%s.%s.%s', $year, $m, $d;
  } else {
    return sprintf '%s年%s月%s日(%s)', $year, $m, $d, $wd;
  }
} # to_dts

{
  binmode STDOUT, qw(:utf8);
  my $points = $DTSDef->{patterns};
  my $rules = shift (@$points)->[1];
  my $jd = 1000000.5;
  while ($jd <= 2525000.5) {
    while (@$points and $points->[0]->[0] <= $jd) {
      $rules = shift (@$points)->[1];
    }
    my $s = to_dts $rules, $jd;
    printf "%s\t%s\n",
        $jd,
        $s;
    $jd += 1;
  }
}

## License: Public Domain.
