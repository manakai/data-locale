use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $Data = {};

my @TestedZeros = (
  (map { $_ * 1000 } 1..100),
  (map { 10_0000 + $_ * 1000 } 1..100),
  1000_000,
);
my @Tested = (0..999, @TestedZeros);

my $FormNames = {};
for (
  [[] => 'never'],
  [[0] => 'is 0'],
  [[1] => 'is 1'],
  [[2] => 'is 2'],
  [[3] => 'is 3'],
  [[4] => 'is 4'],
  [[6] => 'is 6'],
  [[0, 1] => 'is 0, 1'],
  [[1, 3] => 'is 1, 3'],
  [[1..4] => 'is 1-4'],
  [[1, 5] => 'is 1, 5'],
  [[2..3] => 'is 2, 3'],
  [[2..4] => 'is 2-4'],
  [[2..10] => 'is 2-10'],
  [[3..4] => 'is 3, 4'],
  [[3..6] => 'is 3-6'],
  [[5..6] => 'is 5, 6'],
  [[0, 7..9] => 'is 0, 7-9'],
  [[7..10] => 'is 7-10'],
  [[1..9] => 'is 1-9'],
  [[1, 11] => 'is 1, 11'],
  [[8, 11] => 'is 8, 11'],
  [[2, 12] => 'is 2, 12'],
  [[3, 13] => 'is 3, 13'],
  [[3..10, 13..19] => 'is 3-10, 13-19'],
  [[0..1, 11..99] => 'is 0-1, 11-99'],
  [[0, 3..10] => 'is 0, 3-10'],
  [[1, 5, 7..10] => 'is 1, 5, 7-10'],
  [[1, 5, 7, 8, 9] => 'is 1, 5, 7-9'],
  [[8, 11, 80, 800] => 'is 8, 11, 80, 800'],
  [[map { $_ * 10 + 1 } 0..99] => 'ends in 1'],
  [[map { $_ * 10 + 2 } 0..99] => 'ends in 2'],
  [[grep { /(?:1[1-9])$/ } @Tested] => 'ends in 11-19'],
  [[grep { not $_ == 1 } map { $_ * 10 + 1, $_ * 10 + 2 } 0..99] => 'ends in 1-2 excluding 1'],
  [[grep { not /11$/ } map { $_ * 10 + 1 } 0..99] => 'ends in 1 not ends in 11'],
  [[grep { not /1[12]$/ } map { $_ * 10 + 1, $_ * 10 + 2 } 0..99] => 'ends in 1-2 not ends in 11-12'],
  [[grep { not /11$/ } map { $_ * 10 + 1 } 1..99] => 'ends in 1 not ends in 11 excluding 1, 11'],
  [[grep { not /[179]1$/ } map { $_ * 10 + 1 } 0..99] => 'ends in 1 not ends in 11, 71, 91'],
  [[grep { not /12$/ } map { $_ * 10 + 2 } 0..99] => 'ends in 2 not ends in 12'],
  [[grep { not /1[23]$/ } map { $_ * 10 + 2, $_ * 10 + 3 } 0..99] => 'ends in 2-3 not ends in 12-13'],
  [[grep { not /[179]2$/ } map { $_ * 10 + 2 } 0..99] => 'ends in 2 not ends in 12, 72, 92'],
  [[grep { not /13$/ } map { $_ * 10 + 3 } 0..99] => 'ends in 3 not ends in 13'],
  [[grep { not /14$/ } map { $_ * 10 + 4 } 0..99] => 'ends in 4 not ends in 14'],
  [[grep { /[469]$/ } @Tested] => 'ends in 4, 6, 9'],
  [[grep { /[349]$/ and not /[179][349]$/ } @Tested] => 'ends in 3, 4, 9 not ends in 13, 14, 19, 73, 74, 79, 93, 94, 99'],
  [[map { $_ * 10 + 2, $_ * 10 + 3, $_ * 10 + 4 } 0..99] => 'ends in 2-4'],
  [[map { $_ * 10 + 3, $_ * 10 + 4, $_ * 10 + 5, $_ * 10 + 6 } 0..99] => 'ends in 3-6'],
  [[grep { not /1[2-4]$/ } map { $_ * 10 + 2, $_ * 10 + 3, $_ * 10 + 4 } 0..99] => 'ends in 2-4 not ends in 12-14'],
  [[grep { not /1[78]$/ } map { $_ * 10 + 7, $_ * 10 + 8 } 0..99] => 'ends in 7-8 not ends in 17-18'],
  [[0, (map { $_ * 10 } 2..99), @TestedZeros] => 'ends in 0 excluding 10'],
  [[(map { $_ * 10 } 2..99), @TestedZeros] => 'ends in 0 excluding 0, 10'],
  [[grep { not $_ == 0 } (map { $_ * 10, $_ * 10 + 6, $_ * 10 + 9 } 0..99), @TestedZeros] => 'ends in 0, 6, 9 excluding 0'],
  [[grep { /(?:0|1[1-9])$/ } @Tested] => 'ends in 0 or ends in 11-19'],
  [[grep { /(?:0|1[2-9])$/ } @Tested] => 'ends in 0 or ends in 12-19'],
  [[0, grep { 2 <= ($_ % 100) and ($_ % 100) <= 19 } @Tested] => 'is 0, 2-19, or ends in 02-19'],
  [[grep { /(?:[12578]|[2578]0)$/ } @Tested] => 'ends in 1, 2, 5, 7, 8 or ends in 20, 50, 70, 80'],
  [[grep { /(?:[34]|00)$/ and not /000$/ } @Tested] => 'ends in 3-4 or ends in 00 not ends in 000'],
  [[0, grep { /(?:6|[469]0)$/ } @Tested] => 'is 0 or ends in 6 or ends in 40, 60, 90'],
  [[11, 8, 80..89, 800..899] => 'is 8, 11, 80-89, 800-899'],
  [[0, 2..9, grep { /(?:0[2-9]|1[0-9]|[2468]0)$/ } @Tested] => 'is 0 or ends in 02-20, 40, 60, 80'],
  [[map { $_ * 100 + 1 } 0..9] => 'ends in 01'],
  [[map { $_ * 100 + 2 } 0..9] => 'ends in 02'],
  [[map { $_ * 100 + 5 } 0..9] => 'is 5 or ends in 05'],
  [[(map { $_ * 100, $_ * 100 + 1, $_ * 100 + 2 } 1..9), @TestedZeros] => 'ends in 00-02 excluding 0-2'],
  [[map { $_ * 100 + 3, $_ * 100 + 4 } 0..9] => 'ends in 03-04'],
  [[map { $_ * 100 + 3, $_ * 100 + 4, $_ * 100 + 5, $_ * 100 + 6, $_ * 100 + 7, $_ * 100 + 8, $_ * 100 + 9, $_ * 100 + 10 } 0..9] => 'ends in 03-10'],
  [[grep { $_ == 0 or (3 <= $_ % 100 and $_ % 100 <= 10) } @Tested] => 'is 0 or ends in 03-10'],
  [[(map { $_ * 100, $_ * 100 + 20, $_ * 100 + 40, $_ * 100 + 60, $_ * 100 + 80 } 0..9), @TestedZeros] => 'is 0 or ends in 02468 0'],
  [[grep { $_ != 1 } map { $_ * 100 + 1, $_ * 100 + 21, $_ * 100 + 41, $_ * 100 + 61, $_ * 100 + 81 } 0..9] => 'ends in 02468 1'],
  [[10, grep { /[69]$/ } @Tested] => 'is 10 or ends in 6, 9'],
  [[0, 2..19, grep { /(?:0[1-9]|1[0-9])$/ } grep { length >= 3 } @Tested] => 'is 0 or ends in 01-19 excluding 1'],
  [[0, 2..19, grep { /(?:0[1-9]|10)$/ } grep { length >= 3 } @Tested] => 'is 0, 11-19 or ends in 01-10 excluding 1'],
  [[2, (map { $_ * 1000 } 1..9), grep { /(?:[02468]2|0[1-9]000|1[0-9]000|[2468]0000|100000)$/ } grep { length >= 2 } @Tested] => 'is 2, 1000-9000 or ends in 02468 2 or ends in 01-19 000, 2468 0000, or 100000'],
  [[3, grep { /(?:[02468]3)$/ } grep { length >= 2 } @Tested] => 'is 3 or ends in 02468 3'],
  [[1..4, grep { /(?:[02468][1-4])$/ } grep { length >= 2 } @Tested] => 'is 1-4 or ends in 02468 1-4'],
  [[0, grep { not ($_ == 1) } map { $_ * 100 + 1, $_ * 100 + 2, $_ * 100 + 3, $_ * 100 + 4, $_ * 100 + 5, $_ * 100 + 6, $_ * 100 + 7, $_ * 100 + 8, $_ * 100 + 9, $_ * 100 + 10 } 0..9] => 'is 0 or ends in 01-10 excluding 1'],
  [[0, map { $_ * 100 + 2, $_ * 100 + 3, $_ * 100 + 4, $_ * 100 + 5, $_ * 100 + 6, $_ * 100 + 7, $_ * 100 + 8, $_ * 100 + 9, $_ * 100 + 10 } 0..9] => 'is 0 or ends in 02-10'],
  [[map { $_ * 100 + 11, $_ * 100 + 12, $_ * 100 + 13, $_ * 100 + 14, $_ * 100 + 15, $_ * 100 + 16, $_ * 100 + 17, $_ * 100 + 18, $_ * 100 + 19 } 0..9] => 'ends in 11-19'],
  [[grep { /000000$/ } @Tested] => 'ends in 000000 excluding 0'],
) {
  $FormNames->{join ' ', sort { $a <=> $b } @{$_->[0]}} = $_->[1];
}
$Data->{forms} = {reverse %$FormNames};
die sprintf '%d != %d', scalar keys %{$Data->{forms}}, scalar keys %$FormNames
  unless (keys %{$Data->{forms}}) == (keys %{$FormNames});
for (values %{$Data->{forms}}) {
  my $v = $_;
  my @v = split / /, $v;
  $_ = {
    examples => $v,
    typical => $v[0] || $v[1] // $v[0],
  };
}
for my $name (keys %{$Data->{forms}}) {
  if ($name =~ /^is ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1";
  } elsif ($name =~ /^is ([0-9]+)-([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "$1<=n&&n<=$2";
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||n==$2";
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+)-([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||($2<=n&&n<=$3)";
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+), ([0-9]+)-([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||n==$2||($3<=n&&n<=$4)";
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+), ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||n==$2||n==$3";
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+), ([0-9]+), ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||n==$2||n==$3||n==$4";
  } elsif ($name =~ /^is ([0-9]+)-([0-9]+), ([0-9]+)-([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "($1<=n&&n<=$2)||($3<=n&&n<=$4)";
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+), ([0-9]+)-([0-9]+), ([0-9]+)-([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||n==$2||($3<=n&&n<=$4)||($5<=n&&n<=$6)";
  } elsif ($name =~ /^is ([0-9]+) or ends in ([0-9][0-9])-([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||($2<=n%100&&n%100<=$3)";
  } elsif ($name =~ /^is ([0-9]+) or ends in ([0-9][0-9])-([0-9][0-9]) excluding ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||($2<=n%100&&n%100<=$3&&n!=$4)";
  } elsif ($name =~ /^is ([0-9]+) or ends in 0([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||n%100==$2";
  } elsif ($name =~ /^is ([0-9]+), ([0-9])-([0-9]+), or ends in 0\2-\3$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||($2<=n%100&&n%100<=$3)";
  } elsif ($name =~ /^is ([0-9][0-9]) or ends in ([0-9]), ([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||n%10==$2||n%10==$3";
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+)-([0-9]+) or ends in ([0-9][0-9])-([0-9][0-9]) excluding ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||($2<=n&&n<=$3)||($4<=n%100&&n%100<=$5&&n!=$6)";
  } elsif ($name =~ /^is 0 or ends in ([0-9]) or ends in ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n==0||n%10==$1||n%100==$2||n%100==$3||n%100==$4";
  } elsif ($name =~ /^is 0 or ends in ([0-9][0-9])-([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n==0||$1<=n%100&&n%100<=$2||n%100==$3||n%100==$4||n%100==$5";
  } elsif ($name =~ /^ends in ([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1";
  } elsif ($name =~ /^ends in ([0-9])-([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "$1<=n%10&&n%10<=$2";
  } elsif ($name =~ /^ends in ([0-9]) or ends in ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1||n%100==$2";
  } elsif ($name =~ /^ends in ([0-9]) or ends in ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1||n%100==$2||n%100==$3";
  } elsif ($name =~ /^ends in ([0-9]) or ends in ([0-9][0-9])-([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1||($2<=n%100&&n%100<=$3)";
  } elsif ($name =~ /^ends in ([0-9]) excluding ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1&&n!=$2";
  } elsif ($name =~ /^ends in ([0-9]) excluding ([0-9]+), ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1&&n!=$2&&n!=$3";
  } elsif ($name =~ /^ends in ([0-9]) not ends in ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1&&n%100!=$2";
  } elsif ($name =~ /^ends in ([0-9]) not ends in ([0-9][0-9]) excluding ([0-9]+), ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1&&n%100!=$2&&n!=$3&&n!=$4";
  } elsif ($name =~ /^ends in ([0-9]) not ends in ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1&&n%100!=$2&&n%100!=$3";
  } elsif ($name =~ /^ends in ([0-9]) not ends in ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1&&n%100!=$2&&n%100!=$3&&n%100!=$4";
  } elsif ($name =~ /^ends in ([0-9])-([0-9]) excluding ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "($1<=n%10&&n%10<=$2)&&n!=$3";
  } elsif ($name =~ /^ends in ([0-9])-([0-9]) not ends in ([0-9][0-9])-([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "($1<=n%10&&n%10<=$2)&&!($3<=n%100&&n%100<=$4)";
  } elsif ($name =~ /^ends in ([0-9]), ([0-9]), ([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1||n%10==$2||n%10==$3";
  } elsif ($name =~ /^ends in ([0-9]), ([0-9]), ([0-9]) excluding ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "(n%10==$1||n%10==$2||n%10==$3)&&n!=$4";
  } elsif ($name =~ /^ends in ([0-9]), ([0-9]), ([0-9]) not ends in ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "(n%10==$1||n%10==$2||n%10==$3)&&n%100!=$4&&n%100!=$5&&n%100!=$6&&n%100!=$7&&n%100!=$8&&n%100!=$9&&n%100!=$10&&n%100!=$11&&n%100!=$12";
  } elsif ($name =~ /^ends in ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%100==$1";
  } elsif ($name =~ /^ends in ([0-9][0-9])-([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "$1<=n%100&&n%100<=$2";
  } elsif ($name =~ /^ends in ([0-9][0-9])-([0-9][0-9]) excluding ([0-9])-([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "$1<=n%100&&n%100<=$2&&!($3<=n&&n<=$4)";
  } elsif ($name =~ /^ends in ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%100==$1||n%100==$2||n%100==$3||n%100==$4||n%100==$5";
  } elsif ($name =~ /^ends in ([0-9]{6}) excluding ([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%1000000==$1&&n!=$2";
  } elsif ($name =~ /^ends in ([0-9])-([0-9]) or ends in ([0-9][0-9]) not ends in ([0-9][0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1||n%10==$2||n%100==$3&&n%1000!=$4";
  } elsif ($name =~ /^ends in ([0-9]), ([0-9]), ([0-9]), ([0-9]), ([0-9]) or ends in ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1||n%10==$2||n%10==$3||n%10==$4||n%10==$5||n%100==$6||n%100==$7||n%100==$8||n%100==$9";
  } elsif ($name =~ /^is (([0-9])-([0-9])) or ends in 02468 \1$/) {
    $Data->{forms}->{$name}->{expression} = "($2<=n%100&&n%100<=$3)||(2$2<=n%100&&n%100<=2$3)||(4$2<=n%100&&n%100<=4$3)||(6$2<=n%100&&n%100<=6$3)||(8$2<=n%100&&n%100<=8$3)";
  } elsif ($name =~ /^ends in 02468 ([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n!=$1&&(n%100==$1||n%100==2$1||n%100==4$1||n%100==6$1||n%100==8$1)";
  } elsif ($name =~ /^is ([0-9]) or ends in 02468 \1$/) {
    $Data->{forms}->{$name}->{expression} = "n%100==$1||n%100==2$1||n%100==4$1||n%100==6$1||n%100==8$1";
  } elsif ($name =~ /^is 2, 1000-9000 or ends in 02468 2 or ends in 01-19 000, 2468 0000, or 100000$/) {
    $Data->{forms}->{$name}->{expression} = "(n%100==2||n%100==22||n%100==42||n%100==62||n%100==82)||(n%1000==0)&&(1000<=n%100000&&n%100000<=20000||n%100000==40000||n%100000==60000||n%100000==80000)||(n%1000000==100000)";
  } elsif ($name eq 'never') {
    $Data->{forms}->{$name}->{expression} = "1==0";
  } else {
    die "Unknown form name |$name|";
  }
  $Data->{forms}->{$name}->{expression} =~ s/(?<![0-9])0+([0-9]+)/$1/g;

  my $expr = $Data->{forms}->{$name}->{expression};
  $expr =~ s/n/\$n/g;
  my @num;
  for my $n (@Tested) {
    my $r = eval $expr;
    die "|$expr|: $@" if $@;
    push @num, $n if $r;
  }
  my $nums = join ' ', @num;
  unless ($nums eq $Data->{forms}->{$name}->{examples}) {
    die "Form |$name|'s expression {$expr} is incorrect\n  Got     : $nums\n  Expected: $Data->{forms}->{$name}->{examples}";
  }
}

my $NormalizedExprs = [];

sub expr ($$;%) {
  my ($n, $expr_orig, %args) = @_;
  my $data = {};
  my $expr = $expr_orig;
  $expr =~ s/([nivwftce])/\$$1/g;
  $data->{forms}->[$n-1] ||= [];
  for my $n (@Tested) {
    ## <https://unicode.org/reports/tr35/tr35-numbers.html#Operands>
    ## XXX fractions (ivwftce) are not supported in fact...
    my $c = my $e = $n =~ /e([0-9]+)$/ ? $1 : 0;
    my $i = int $n;
    my $v = $n =~ /\.([0-9]+)$/ ? length $1 : 0;
    my $w = $n =~ /\.([0-9]*?)0*$/ ? length $1 : 0;
    my $f = $n =~ /\.([0-9]+)$/ ? $1 : 0;
    my $t = $n =~ /\.([0-9]*?)0*$/ ? $1 : 0;
    my $r = eval qq{ use warnings 'FATAL' => 'all'; $expr };
    die "expr: |$expr|: $@" if $@;
    push @{$data->{forms}->[$r] ||= []}, $n;
  }

  my $replaced = {};
  my $replaced_count = 0;
  for (@{$data->{forms}}) {
    $_ = defined $_ ? (join ' ', @$_) : '';
    if (defined $FormNames->{$_}) {
      $_ = $FormNames->{$_};
      $replaced->{$_} = 1;
      $replaced_count++;
    }
  }
  if (@{$data->{forms}} == 1 + $replaced_count) {
    for (@{$data->{forms}}) {
      $_ = 'everything else', $replaced->{$_}++, $replaced_count++
          unless $replaced->{$_};
    }
  }
  if (@{$data->{forms}} != $replaced_count) {
    warn sprintf "%d - %d\n", 0+ @{$data->{forms}}, $replaced_count;
    for (@{$data->{forms}}) {
      warn "New form found: [$_]\n" unless $replaced->{$_};
    }
    die "An unknown form found from expression |$expr_orig|";
  }
  my @sorted_key = sort {
    $Data->{forms}->{$a}->{typical} <=>
        $Data->{forms}->{$b}->{typical};
  } grep { $_ ne 'never' and $_ ne 'everything else' } @{$data->{forms}};
  my $sorted_key = (@sorted_key + 1) . ':' . join '/', @sorted_key, 'everything else';
  $Data->{rules}->{$sorted_key}->{forms} = [@sorted_key, 'everything else'];
  my $name_to_field = {never => "-"};
  {
    my $i = 0;
    for (@sorted_key) {
      $name_to_field->{$_} = $i++;
    }
    $name_to_field->{'everything else'} = $i++;
  }
  $Data->{rules}->{$sorted_key}->{expression} = join '', (map { $Data->{forms}->{$_}->{expression} . '?' . $name_to_field->{$_} . ':' } @sorted_key), $name_to_field->{'everything else'};
  $NormalizedExprs->[@sorted_key + 1]->{$Data->{rules}->{$sorted_key}->{expression}} = 1;
  my $key = $n . ':' . join '/', @{$data->{forms}};
  unless ($args{dont_add}) {
    $Data->{rules}->{$sorted_key}->{serializations}->{$key}->{expressions}->{$expr_orig} = 1;
    $Data->{rules}->{$sorted_key}->{serializations}->{$key}->{fields} = join '/', map { $name_to_field->{$_} } @{$data->{forms}};
  }
  for (@{$args{cldr_locales} or []}) {
    $Data->{rules}->{$sorted_key}->{cldr_locales}->{$args{cldr_type}}->{$_} = 1;
  }
  return ($sorted_key, $key);
} # expr

{
  warn "Expr...\n";
  my $path = path (__FILE__)->parent->parent->child ('src/plural-exprs.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^nplurals=([0-9]+);plural=(.+?);?$/) {
      expr $1, $2;
    } elsif (/\S/) {
      warn "Broken line: |$_|";
    }
  }
}

{
  warn "Additional...\n";
  my $path = path (__FILE__)->parent->parent->child ('src/plural-additional.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^nplurals=([0-9]+);plural=(.+?);?$/) {
      expr $1, $2, dont_add => 1;
    } elsif (/\S/) {
      warn "Broken line: |$_|";
    }
  }
}

{
  warn "CLDR...\n";
  my $path = path (__FILE__)->parent->parent->child ('local/cldr-plurals.json');
  my $json = json_bytes2perl $path->slurp;
  for my $type (keys %$json) {
    for my $locales (keys %{$json->{$type}}) {
      my $forms = $json->{$type}->{$locales};
      my $expr = '';
      my $i = 0;
      for my $label (keys %$forms) {
        my $x = $forms->{$label};
        next unless length $x;
        $x =~ s/\s+/ /g;
        $x =~ s/and/&&/g;
        $x =~ s/or/||/g;
        $x =~ s/\s*%\s*/ % /g;
        $x =~ s/\s*([!<>]?=)\s*/ $1 /g;
        $x =~ s/\s*\.\.\s*/../g;
        $x =~ s/([a-z](?: % [0-9]+|)) != ([0-9]+)\.\.([0-9]+),([0-9]+)\.\.([0-9]+),([0-9]+)\.\.([0-9]+)/!(($2 <= $1 && $1 <= $3) || ($4 <= $1 && $1 <= $5) || ($6 <= $1 && $1 <= $7))/g;
        $x =~ s/([a-z](?: % [0-9]+|)) != ([0-9]+)\.\.([0-9]+)/!($2 <= $1 && $1 <= $3)/g;
        $x =~ s{([a-z](?: % [0-9]+|)) = ([0-9]+(?:\.\.[0-9]+|)(?:,[0-9]+(?:\.\.[0-9]+|))*)}{
          my $left = $1;
          my $right = [split /,/, $2];
          '(' . (join '||', map {
            if (/^([0-9]+)\.\.([0-9]+)$/) {
              qq{$1 <= $left && $left <= $2};
            } else {
              qq{$left == $_};
            }
          } @$right) . ')';
        }ge;
        $x =~ s/([a-z](?: % [0-9]+|)) != ([0-9]+),([0-9]+),([0-9]+)/$1 != $2 && $1 != $3 && $1 != $4/g;
        $x =~ s/([a-z](?: % [0-9]+|)) != ([0-9]+),([0-9]+)/$1 != $2 && $1 != $3/g;
        $x =~ s/([a-z](?: % [0-9]+|)) != ([0-9]+)/$1 != $2/g;
        $expr .= $x . '?' . $i++ . ':';
      }
      $expr .= $i++;
      expr $i, $expr, dont_add => 1,
          cldr_type => $type,
          cldr_locales => [split /\s+/, $locales];
    }
  }
}

for my $x (
  [0 => 1, q{0}],
  [1 => 2, q{n!=1?1:0}],
  [2 => 2, q{n>1?1:0}],
  [3 => 3, q{n%10==1&&n%100!=11?1:n!=0?2:0}],
  [4 => 4, q{n==1||n==11?0:n==2||n==12?1:n>0&&n<20?2:3}],
  [5 => 3, q{n==1?0:n==0||n%100>0&&n%100<20?1:2}],
  [6 => 3, q{n%10==1&&n%100!=11?0:n%10>=2&&(n%100<10||n%100>=20)?2:1}],
  [7 => 3, q{n%10==1&&n%100!=11?0:n%10>=2&&n%10<=4&&(n%100<10||n%100>=20)?1:2}],
  [8 => 3, q{n==1?0:n>=2&&n<=4?1:2}],
  [9 => 3, q{n==1?0:n%10>=2&&n%10<=4&&(n%100<10||n%100>=20)?1:2}],
  [10 => 4, q{n%100==1?0:n%100==2?1:n%100==3||n%100==4?2:3}],
  [11 => 5, q{n==1?0:n==2?1:n>=3&&n<=6?2:n>=7&&n<=10?3:4}],
  [12 => 6, q{n==0?5:n==1?0:n==2?1:n%100>=3&&n%100<=10?2:n%100>=11&&n%100<=99?3:4}],
  [13 => 4, q{n==1?0:n==0||n%100>0&&n%100<=10?1:n%100>10&&n%100<20?2:3}],
  [14 => 3, q{n%10==1?0:n%10==2?1:2}],
  [15 => 2, q{n%10==1&&n%100!=11?0:1}],
  [16 => 5, q{n%10==1&&n%100!=11&&n%100!=71&&n%100!=91?0:n%10==2&&n%100!=12&&n%100!=72&&n%100!=92?1:(n%10==3||n%10==4||n%10==9)&&n%100!=13&&n%100!=14&&n%100!=19&&n%100!=73&&n%100!=74&&n%100!=79&&n%100!=93&&n%100!=94&&n%100!=99?2:n%1000000==0&&n!=0?3:4}],
) {
  my ($key1, $key2) = expr $x->[1], $x->[2];
  $Data->{rules}->{$key1}->{serializations}->{$key2}->{mozilla_rule} = $x->[0];
}

for my $num (0..$#$NormalizedExprs) {
  for my $expr (keys %{$NormalizedExprs->[$num]}) {
    expr $num, $expr;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
