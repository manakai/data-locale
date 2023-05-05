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

my $Printed = {};
sub xprintf ($@) {
  my $x = sprintf shift, @_;
  unless ($Printed->{$x}++) {
    print $x;
  }
} # xprintf

sub read_table ($) {
  my $path = shift;
  my $json = json_bytes2perl $path->slurp;

  shift @{$json->{rows}}; # header
  for my $row (@{$json->{rows}}) {
    $row->[0] =~ s{^(\s*1276 \|\| 丙子)}{$1||};
    if ($row->[0] =~ m{^\s*([0-9]+)\s*\|\|\s*\w+\s*\|\|\s*(\S.+\S)\s*\|\|\s*(\S.+\S)\s*$}) {
      my $CurrentYear = 0+$1;
      my $cys = $2;
      my $kys = $3;

      $cys =~ s/。$//;
      $kys =~ s/。$//;
      my @cy = grep { length } split /<p>|[。.]|\s+/, $cys;
      my @ky = grep { length } split /<p>|[。.]|\s+/, $kys;

      for my $cy (@cy) {
        if ($cy =~ m{^\p{sc=Han}+[宗帝]仍稱?\p{sc=Han}+${Num}年$}) {
          #
        } elsif ($cy =~ m{^金改(開興)又改(天興)元年$}) {
          {
            my $name = $1;
            my $year = 1;
            xprintf "%s\t%d\n",
                $name, $CurrentYear - $year + 1;
          }
          {
            my $name = $2;
            my $year = 1;
            xprintf "%s\t%d\n",
                $name, $CurrentYear - $year + 1;
          }
        } elsif ($cy =~ m{^(\p{sc=Han}+?)($Num|元)年(?:，?[改復]國號\w+|)$}) {
          my $name = $1;
          my $year = parse_number $2;
          xprintf "%s\t%d\n",
              $name, $CurrentYear - $year + 1;
        } elsif ($cy =~ m{^元泰定五年二月改(致和)$}) {
          my $name = $1;
          my $year = 1;
          xprintf "%s\t%d\n",
              $name, $CurrentYear - $year + 1;
        } elsif ({
          '太宗崩，皇后臨朝五年' => 1,
          '定宗崩，皇后臨朝' => 1,
          宋 => 1,
          蒙古建國號曰元 => 1,
          八月靈宗卽位十二月崩 => 1,
        }->{$cy}) {
          #
        } elsif ($cy =~ /\S/) {
          die "Bad line component |$cy|";
        }
      }
    } elsif ($row->[0] =~ /\S/) {
      die "Bad line |$row->[0]|";
    }
  }

} # read_table

print "tag 高麗史 年表 上國\n";

for (qw(kouraitable1.json kouraitable2.json)) {
  my $path = $ThisPath->child ($_);
  read_table $path;
}

## License: Public Domain.
