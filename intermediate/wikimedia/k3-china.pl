use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

binmode STDOUT, qw(:encoding(utf-8));

my $ThisPath = path (__FILE__)->parent;

my $Num = qr{[一二三四亖五六七八九]十[一二三四亖五六七八九]?|十[一二三四亖五六七八九]|[一二三四亖五六七八九十]};
my $MonthNum = qr{[正一二三四亖五六七八九十]|十[一二]};
my $Kanshi = qr{(?!初)\p{sc=Han}{2}};
my $ToNumber = {
  一 => 1, 二 => 2, 三 => 3, 四 => 4, 五 => 5, 亖 => 4,
  六 => 6, 七 => 7, 八 => 8, 九 => 9, 十 => 10,
  '' => 0,
  正 => 1,
  元 => 1,
};
sub parse_number ($) {
  my $s = shift;
  if ($s =~ m{^([一二三四亖五六七八九])十([一二三四亖五六七八九]?)$}) {
    return $ToNumber->{$1} * 10 + $ToNumber->{$2};
  } elsif ($s =~ m{^十([一二三四亖五六七八九])$}) {
    return 10 + $ToNumber->{$1};
  } elsif ($s =~ m{^([正元一二三四亖五六七八九十])$}) {
    return $ToNumber->{$1};
  } else {
    die $s;
  }
} # parse_number

my $CurrentYear = 1 - 57;
sub read_table ($) {
  my $path = shift;
  my $json = json_bytes2perl $path->slurp;

  shift @{$json->{rows}}; # header
  for my $row (@{$json->{rows}}) {
    for (@{$row->[1]}) {
      if (/^(\p{sc=Han}+)(元)[年手載]$/) {
        printf "%s\t%d\n",
            $1, $CurrentYear;
      } elsif (/^改元(\p{sc=Han}+?)又改元(\p{sc=Han}+)$/) {
        printf "%s\t%d\n",
            $1, $CurrentYear;
        printf "%s\t%d\n",
            $2, $CurrentYear;
      } elsif (/^(?:[吳蜀]|西秦|)[改建]元(\p{sc=Han}+)$/) {
        printf "%s\t%d\n",
            $1, $CurrentYear;
      } elsif (/^(太始)元年世祖孝宗$/) {
        printf "%s\t%d\n",
            $1, $CurrentYear;
      } elsif (/^隋(開皇)(十)年$/) {
        printf "%s\t%d\n",
            $1, $CurrentYear - (parse_number $2) + 1;
      } elsif (/^(前漢孝宣帝詢)(十七)年$/) {
        printf "%s\t%d\n",
            $1, $CurrentYear - (parse_number $2) + 1;
      } elsif (/^($Num)[年載]?$/o) {
        #
      } elsif (/[帝王公]|孺子嬰|新室|自北三國分矣|立$|遷都建業|十月降於魏|蜀二主四十三年|魏禪于晉|吳主降於晉吳四主五十九年|諱德宗|禪於宋東晉十二主百四年|正陽侯|覇先|楊堅|後主叔寳|陳氏滅|則天順聖皇后武瞾|^\s*[周溫]$|唐中宗|^後唐$|晉高祖石敬瑭/) {
        #
      } elsif (/\S/) {
        die "Bad line |$_|";
      }
    }
    $CurrentYear++;
  }

} # read_table

print "tag 三國史記 年表 中國\n";

for (qw(k3table1.json k3table2.json k3table3.json)) {
  my $path = $ThisPath->child ($_);
  read_table $path;
}

## License: Public Domain.
