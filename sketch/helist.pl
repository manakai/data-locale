use strict;
use warnings;
use utf8;

my $desc = {
  2711 => '[801] [TIME[y~1724]]',
  2491 => '[802] [TIME[y~1723]]',
  2698 => '[803] [TIME[y~510]]',
  2697 => '[804] [TIME[y~1736]]',
  2637 => '[805] [TIME[y~3796]]',
  #2638 => '[806] [TIME[y~????]]',
  ##2650 => '[807] [TIME[y~????]]',
  #2649 => '[808] [TIME[y~????]]',
  #2701 => '[809] [TIME[y~????]]',
  #2779 => '[810] [TIME[y~????]]',
  2492 => '[811] [TIME[y~3800]]',
  2997 => '[812] [TIME[y~3799]]',
  #2696 => '[813] [TIME[y~????]]',
  #2398 => '[814] [TIME[y~????]]',
  #2818 => '[815] [TIME[y~????]]',
  2699 => '[816] [TIME[y~3798]]',
  2993 => '[817] [TIME[y~3797]]',
  #2704 => '[818] [TIME[y~????]]',
};

my $ShakaNotes = {
  -1028 => '仏誕(道元 [SRC[>>659]])',
  -1026 => '仏誕(沙門法上 [SRC[>>1043]])',
  -948 => '仏滅([CITE[周書異記]], 道元 [SRC[>>659]])',
  -947 => '仏滅(沙門法上 [SRC[>>1043]], 恵恩 [SRC[>>724]])',
  -686 => '仏誕(六朝 [SRC[>>1043]])',
  -623 => '仏誕(南伝 [SRC[>>659, >>661]])',
  -607 => '仏滅(六朝 [SRC[>>1043]])',
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

  return sprintf "西暦%d年 (紀元前%d年) %s[WEAK[[LINES[%d[SUB[0]]][%d[SUB[1]]]]]]",
      $ad,
      1 - $ad,
      (to_ykanshi $ad);
} # to_year_desc

binmode STDOUT, qw(:utf8);

print qq{
[FIG(table)[
:n: 整理番号
:+: 黄帝紀元 = 西暦 + [VAR[○]]
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
