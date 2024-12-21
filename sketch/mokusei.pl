use strict;
use warnings;
use utf8;
#use JSON::PS;

my $Data = [];

my $Ji = [qw(
星紀 玄枵 娵訾 降娄 大鿄 実沈 鶉首 鶉火 鶉尾 寿星 大火 析木
)];
my $Ji2Index = {};
$Ji2Index->{$Ji->[$_]} = $_ for 0..$#$Ji;

my $YearName = [qw(
困敦 赤奮若 摂提格 単閼 執除 大荒落 敦牂 協洽 涒灘 作噩 閹茂 大淵献
)];
my $YearName2Index = {};
$YearName2Index->{$YearName->[$_]} = $_ for 0..$#$YearName;

my $Shi = [qw(子 丑 寅 卯 辰 巳 午 未 申 酉 戌 亥)];
$YearName2Index->{$Shi->[$_]} = $_ for 0..$#$Shi;

my $IndexToKanshi = {map { my $x = $_; $x =~ s/\s+//g; $x =~ s/(\d+)/' '.($1-1).' '/ge;
                           grep { length } split /\s+/, $x } q{
1甲子2乙丑3丙寅4丁卯5戊辰6己巳7庚午8辛未9壬申10癸酉11甲戌12乙亥13丙子
14丁丑15戊寅16己卯17庚辰18辛巳19壬午20癸未21甲申22乙酉23丙戌24丁亥25戊子
26己丑27庚寅28辛卯29壬辰30癸巳31甲午32乙未33丙申34丁酉35戊戌36己亥
37庚子38辛丑39壬寅40癸卯41甲辰42乙巳43丙午44丁未45戊申46己酉47庚戌48辛亥
49壬子50癸丑51甲寅52乙卯53丙辰54丁巳55戊午56己未57庚申58辛酉59壬戌60癸亥
}};
my $KanshiToIndex = {reverse %$IndexToKanshi};

sub year2kanshi0 ($) {
  return (($_[0]-4)%60);
} # year2kanshi0

{
  ## Source:  <https://wiki.suikawiki.org/n/%E6%9C%A8%E6%98%9F%E7%B4%80%E5%B9%B4%E6%B3%95>
  my $in = q{

    1 655 魯僖公5 大火 3.35 国語
    2 644 魯僖公16 寿星 3.32 国語
    3 637 魯僖公23 大鿄 3.08 国語
    4 636 魯僖公24 実沈 3.17 国語
    5 633 魯僖公27 鶉尾 3.23 国語
    6 632 魯僖公28 寿星 3.15 国語
    7 554 魯㐮公19 降娄 2.07 春秋左氏伝
    8 545 魯㐮公28 星紀 1.77 春秋左氏伝
    9 543 魯㐮公30 娵訾 1.87 春秋左氏伝
   10 542 魯㐮公31 降娄 1.97 春秋左氏伝
   11 534 魯昭公8  析木 1.65 春秋左氏伝
   12 532 魯昭公10 玄枵 1.67 春秋左氏伝
   13 531 魯昭公11 娵訾 1.73 春秋左氏伝
   14 529 魯昭公13 大鿄 1.90 春秋左氏伝
   15 526 魯昭公16 鶉火 1.93 春秋左氏伝
   16 514 魯昭公28 (鶉火) 1.78 春秋左氏伝
   17 510 魯昭公32 越得歳(析木) 1.33 春秋左氏伝
   18 502 魯定公8 (鶉火) 1.62 春秋左氏伝
   19 490 魯哀公5 (鶉火) 1.45 春秋左氏伝
   20 478 魯哀公17 (鶉火) 1.32 春秋左氏伝
   21 246 秦始皇1 (娵訾) 1.38 五星占
   22 239 秦始皇8 涒灘 -1.82 呂氏春秋
   23 206 漢高祖1 鶉首 1.07 漢書
   24 173 漢文帝7 単閼 0.65 漢書
   25 164 漢文帝16 太一丙子(星紀) 0.25 淮南子
   26 104 漢太初1 星紀(玄枵) -0.42/0.58 漢書
   27 101 漢太初4 執除(大鿄) -0.82 漢書
   28  47 漢初元2 閹茂(大火) -0.27 漢書
   29  33 漢竟寧1 太歳戊子(星紀) -0.25 西漢瓦銘
   30 +13 新始建国5 寿星 -0.98 漢書
   31 +16 新始建国8 星紀 -0.82 漢書
   32 +20 新天鳳7 大鿄 -0.63 漢書
   33 +21 新地皇2 実沈 -0.72 漢書

  };
  for (split /\x0D?\x0A/, $in) {
    my @line = split /\s+/, $_, -1;
    shift @line;
    next unless @line > 1;
    my $out = {};
    $out->{n20} = 0+$line[0];
    $out->{ad} = $line[1] =~ /^\+/ ? 0+$line[1] : 1-$line[1];
    $out->{era} = $line[2];
    $out->{year_name} = $line[3];
    if (defined $Ji2Index->{$out->{year_name}}) {
      $out->{ji} = $Ji2Index->{$out->{year_name}};
    } else {
      if ($out->{year_name} =~ m{^(\w+)\(\w+\)$} and
          defined $Ji2Index->{$1}) {
        $out->{ji} = $Ji2Index->{$1};
      } elsif ($out->{year_name} =~ m{^\w*\((\w+)\)$} and
          defined $Ji2Index->{$1}) {
        $out->{ji} = $Ji2Index->{$1};
      }
    }
    if (defined $YearName2Index->{$out->{year_name}}) {
      $out->{shin} = $YearName2Index->{$out->{year_name}};
    } else {
      if ($out->{year_name} =~ m{^(\w+)\(\w+\)$} and
          defined $YearName2Index->{$1}) {
        $out->{shin} = $YearName2Index->{$1};
      } elsif ($out->{year_name} =~ m{^\w+(\w)\(\w+\)$} and
               defined $YearName2Index->{$1}) {
        $out->{shin} = $YearName2Index->{$1};
      }
    }
    $out->{delta} = $line[4];
    $out->{source} = $line[5];
    push @$Data, $out;
  }
}

binmode STDOUT, qw(:encoding(utf-8));

for my $data (@$Data) {
  my $kanshi = year2kanshi0 $data->{ad};
  my $kanshi_se = ($kanshi-1) % 60;
  my $jishin2 = (defined $data->{ji} ? ($data->{ji} + 2) % 12 : '');
  my $jishin1 = (defined $data->{ji} ? ($data->{ji} + 0) % 12 : '');
  my $jishin0 = (defined $data->{ji} ? ($data->{ji} + 10) % 12 : '');
  my $jishin_1 = (defined $data->{ji} ? ($data->{ji} + 8) % 12 : '');
  my $shin2 = ($kanshi-2) % 12;
  my $shin1 = $kanshi_se % 12;
  my $shin0 = $kanshi % 12;
  my $shin_1 = ($kanshi+1) % 12;
  my $x;
  if (length $jishin2 and $jishin2 == $shin2) {
    $x = -2;
  } elsif (length $jishin1 and $jishin1 == $shin1) {
    $x = -1;
  } elsif (length $jishin0 and $jishin0 == $shin0) {
    $x = 0;
  } elsif (length $jishin_1 and $jishin_1 == $shin_1) {
    $x = +1;
  } elsif (defined $data->{shin} and $data->{shin} == $shin2) {
    $x = -2;
  } elsif (defined $data->{shin} and $data->{shin} == $shin1) {
    $x = -1;
  } elsif (defined $data->{shin} and $data->{shin} == $shin0) {
    $x = 0;
  } elsif (defined $data->{ji} and $data->{ji} == $shin0) {
    $x = 0;
  }

  printf q{
%s
:ad:%s
:k:%s
:y:%s
:ji:%s
:ji2shin2:%s
:ji2shin1:%s
:ji2shin0:%s
:ji2shin-1:%s
:shin:%s
:yshin2:%d
:kanshi_se:%s (%d)
:yshin1:%d
:kanshi:%s (%d)
:yshin0:%d
:yshin-1:%d
:s:%s
:x:%s
:src:%s
},
    defined $data->{n20} ? ':n:' . $data->{n20} : '',
    ($data->{ad} < 1 ? sprintf '[TIME[%d (前%d)][%d]]', $data->{ad}, 1-$data->{ad}, $data->{ad} : sprintf '[TIME[%d]]', $data->{ad}),
    $data->{era},
    $data->{year_name},
    $data->{ji} // '',
    $jishin2,
    $jishin1,
    $jishin0,
    $jishin_1,
    $data->{shin} // '',
    $shin2,
    $IndexToKanshi->{$kanshi_se}, $kanshi_se, $shin1,
    $IndexToKanshi->{$kanshi}, $kanshi, $shin0,
    $shin_1,
    $data->{delta},
    $x // '?',
    $data->{source} =~ /銘/ ? $data->{source} : '[CITE['.$data->{source}.']]';
}


## License: Public Domain.

