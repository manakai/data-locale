use strict;
use warnings;
use utf8;

my $desc = {
   543 => '[801] α', # alpha
   544 => '[802] β', # beta
   949 => '[803] γ', # gamma
   566 => '[804] δ', # delta
   531 => '[805] ε', # epsilon
  1027 => '[806] ζ', # zeta
   948 => '[807] η', # eta
   565 => '[808] θ', # theta
   542 => '[809] ι', # iota

  1028 => 'ζ1年ずれ',
   960 => 'γ11年ずれ',
   950 => 'γ1年ずれ',
   947 => 'γ2年ずれ',
   567 => 'δ1年ずれ',
   532 => 'ε1年ずれ',
   536 => 'ε5年ずれ',
   545 => 'β1年ずれ',
   554 => 'θ9年ずれ',
  
   941 => 'η7年ずれ',
};

my $ShakaNotes = {
  -1028 => '仏誕(道元 [SRC[>>659]])',
  -948 => '仏滅([CITE[周書異記]], 道元 [SRC[>>659]])',
  -623 => '仏誕(南伝 [SRC[>>659, >>661]])',
  -543 => '仏滅(南伝 [SRC[>>659, >>661]])',
  -565 => '仏誕(高楠順次郎 [SRC[>>651]])',
  -564 => '仏誕([CITE[衆聖点記]] [SRC[>>659]])',
  -563 => '仏誕(金倉圓照 [SRC[>>661]])',
  -485 => '仏滅([CITE[衆聖点記]] [SRC[>>659]], 高楠順次郎 [SRC[>>661]])',
  -484 => '仏滅([CITE[衆聖点記]] [SRC[>>661]])',
  -483 => '仏滅(金倉圓照 [SRC[>>661]])',
  -465 => '仏誕(宇井伯寿 [SRC[>>659, >>661]])',
  -385 => '仏滅(宇井伯寿 [SRC[>>659, >>661]])',
  -462 => '仏誕(中村元 [SRC[>>659, >>661]])',
  -382 => '仏滅(中村元 [SRC[>>659, >>661]])',
};


sub to_ykanshi ($) {
  my $year = shift;
  my $k = qw(庚 辛 壬 癸 甲 乙 丙 丁 戊 己)[$year % 10]
    .
    qw(申 酉 戌 亥 子 丑 寅 卯 辰 巳 午 未)[$year % 12];
  my $v0 = ($year - 4) % 60;
  my $v1 = $v0 + 1;
  return ($k, $v0, $v1);
} # to_ykanshi

sub to_year_desc ($) {
  my $ad = shift;

  my @shuu = map { [$_->[0], - $_->[1] + $ad + 1] }
      ['昭王', -1051],
      ['穆王', -1000],
      ['共王', -945];
  
  return sprintf "西暦%d年 (紀元前%d年) [WEAK[周%s%d年]] %s[WEAK[[LINES[%d[SUB[0]]][%d[SUB[1]]]]]]",
      $ad,
      1 - $ad,
      @{[grep { $_->[1] > 0 } @shuu]->[-1]},
      (to_ykanshi $ad);
} # to_year_desc

binmode STDOUT, qw(:utf8);

print qq{
[FIG(table)[
:n: 整理番号
:+: 仏暦 = 西暦 + [VAR[○]]
:0: 0年
:1: 1年
:note: 参考

};
for my $delta (sort { $b <=> $a } keys %$desc) {
  my $name = $desc->{$delta};
  print ":n:$name\n";
  printf ":0:[TIME[%s][year:%d]]\n",
      to_year_desc (-$delta), -$delta;
  printf ":1:[TIME[%s][year:%d]]\n",
      to_year_desc (-$delta + 1), -$delta + 1;
  printf ":+:[N[%d]]\n",
      $delta;
  if (defined $ShakaNotes->{-$delta} or defined $ShakaNotes->{-$delta + 1}) {
    print ":note:\n";
    if (defined $ShakaNotes->{-$delta}) {
      print "0年:" . $ShakaNotes->{-$delta} . "\n";
    }
    if (defined $ShakaNotes->{-$delta + 1}) {
      print "1年:" . $ShakaNotes->{-$delta + 1} . "\n";
    }
  }
  
  print "\n";
}
print "]FIG]\n";
