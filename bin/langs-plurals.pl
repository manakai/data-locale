use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $Data = {};

my $FormNames = {};
for (
  [[] => 'never'],
  [[0] => 'is 0'],
  [[1] => 'is 1'],
  [[2] => 'is 2'],
  [[3] => 'is 3'],
  [[0, 1] => 'is 0, 1'],
  [[2..4] => 'is 2-4'],
  [[3..6] => 'is 3-6'],
  [[7..10] => 'is 7-10'],
  [[1..9] => 'is 1-9'],
  [[1, 11] => 'is 1, 11'],
  [[8, 11] => 'is 8, 11'],
  [[2, 12] => 'is 2, 12'],
  [[3..10, 13..19] => 'is 3-10, 13-19'],
  [[0, 3..10] => 'is 0, 3-10'],
  [[map { $_ * 10 + 1 } 0..99] => 'ends in 1'],
  [[map { $_ * 10 + 2 } 0..99] => 'ends in 2'],
  [[grep { not $_ == 1 } map { $_ * 10 + 1, $_ * 10 + 2 } 0..99] => 'ends in 1-2 excluding 1'],
  [[grep { not /11$/ } map { $_ * 10 + 1 } 0..99] => 'ends in 1 not ends in 11'],
  [[grep { not /11$/ } map { $_ * 10 + 1 } 1..99] => 'ends in 1 not ends in 11 excluding 1, 11'],
  [[grep { not /[179]1$/ } map { $_ * 10 + 1 } 0..99] => 'ends in 1 not ends in 11, 71, 91'],
  [[grep { not /[179]2$/ } map { $_ * 10 + 2 } 0..99] => 'ends in 2 not ends in 12, 72, 92'],
  [[grep { /[349]$/ and not /[179][349]$/ } 0..999] => 'ends in 3, 4, 9 not ends in 13, 14, 19, 73, 74, 79, 93, 94, 99'],
  [[map { $_ * 10 + 2, $_ * 10 + 3, $_ * 10 + 4 } 0..99] => 'ends in 2-4'],
  [[map { $_ * 10 + 3, $_ * 10 + 4, $_ * 10 + 5, $_ * 10 + 6 } 0..99] => 'ends in 3-6'],
  [[grep { not /1[2-4]$/ } map { $_ * 10 + 2, $_ * 10 + 3, $_ * 10 + 4 } 0..99] => 'ends in 2-4 not ends in 12-14'],
  [[0, map { $_ * 10 } 2..99, 100000] => 'ends in 0 excluding 10'],
  [[grep { /(?:0|1[1-9])$/ } 0..999, 1000000] => 'ends in 0 or ends in 11-19'],
  [[grep { /(?:0|1[2-9])$/ } 0..999, 1000000] => 'ends in 0 or ends in 12-19'],
  [[map { $_ * 100 + 1 } 0..9] => 'ends in 01'],
  [[map { $_ * 100 + 2 } 0..9] => 'ends in 02'],
  [[(map { $_ * 100, $_ * 100 + 1, $_ * 100 + 2 } 1..9), 1000000] => 'ends in 00-02 excluding 0-2'],
  [[map { $_ * 100 + 3, $_ * 100 + 4 } 0..9] => 'ends in 03-04'],
  [[map { $_ * 100 + 3, $_ * 100 + 4, $_ * 100 + 5, $_ * 100 + 6, $_ * 100 + 7, $_ * 100 + 8, $_ * 100 + 9, $_ * 100 + 10 } 0..9] => 'ends in 03-10'],
  [[0, 2..19, grep { /(?:0[1-9]|1[0-9])$/ } 100..999] => 'is 0 or ends in 01-19 excluding 1'],
  [[0, 2..19, grep { /(?:0[1-9]|10)$/ } 100..999] => 'is 0, 11-19 or ends in 01-10 excluding 1'],
  [[0, grep { not ($_ == 1) } map { $_ * 100 + 1, $_ * 100 + 2, $_ * 100 + 3, $_ * 100 + 4, $_ * 100 + 5, $_ * 100 + 6, $_ * 100 + 7, $_ * 100 + 8, $_ * 100 + 9, $_ * 100 + 10 } 0..9] => 'is 0 or ends in 01-10 excluding 1'],
  [[0, map { $_ * 100 + 2, $_ * 100 + 3, $_ * 100 + 4, $_ * 100 + 5, $_ * 100 + 6, $_ * 100 + 7, $_ * 100 + 8, $_ * 100 + 9, $_ * 100 + 10 } 0..9] => 'is 0 or ends in 02-10'],
  [[map { $_ * 100 + 11, $_ * 100 + 12, $_ * 100 + 13, $_ * 100 + 14, $_ * 100 + 15, $_ * 100 + 16, $_ * 100 + 17, $_ * 100 + 18, $_ * 100 + 19 } 0..9] => 'ends in 11-19'],
  [[1000000] => 'ends in 000000 excluding 0'],
) {
  $FormNames->{join ' ', @{$_->[0]}} = $_->[1];
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
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+), ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||n==$2||n==$3";
  } elsif ($name =~ /^is ([0-9]+)-([0-9]+), ([0-9]+)-([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "($1<=n&&n<=$2)||($3<=n&&n<=$4)";
  } elsif ($name =~ /^is ([0-9]+) or ends in ([0-9][0-9])-([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||($2<=n%100&&n%100<=$3)";
  } elsif ($name =~ /^is ([0-9]+) or ends in ([0-9][0-9])-([0-9][0-9]) excluding ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||($2<=n%100&&n%100<=$3&&n!=$4)";
  } elsif ($name =~ /^is ([0-9]+), ([0-9]+)-([0-9]+) or ends in ([0-9][0-9])-([0-9][0-9]) excluding ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n==$1||($2<=n&&n<=$3)||($4<=n%100&&n%100<=$5&&n!=$6)";
  } elsif ($name =~ /^ends in ([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1";
  } elsif ($name =~ /^ends in ([0-9])-([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "$1<=n%10&&n%10<=$2";
  } elsif ($name =~ /^ends in ([0-9]) or ends in ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1||n%100==$2";
  } elsif ($name =~ /^ends in ([0-9]) or ends in ([0-9][0-9])-([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1||($2<=n%100&&n%100<=$3)";
  } elsif ($name =~ /^ends in ([0-9]) excluding ([0-9]+)$/) {
    $Data->{forms}->{$name}->{expression} = "n%10==$1&&n!=$2";
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
  } elsif ($name =~ /^ends in ([0-9]), ([0-9]), ([0-9]) not ends in ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9]), ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "(n%10==$1||n%10==$2||n%10==$3)&&n%100!=$4&&n%100!=$5&&n%100!=$6&&n%100!=$7&&n%100!=$8&&n%100!=$9&&n%100!=$10&&n%100!=$11&&n%100!=$12";
  } elsif ($name =~ /^ends in ([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%100==$1";
  } elsif ($name =~ /^ends in ([0-9][0-9])-([0-9][0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "$1<=n%100&&n%100<=$2";
  } elsif ($name =~ /^ends in ([0-9][0-9])-([0-9][0-9]) excluding ([0-9])-([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "$1<=n%100&&n%100<=$2&&!($3<=n&&n<=$4)";
  } elsif ($name =~ /^ends in ([0-9]{6}) excluding ([0-9])$/) {
    $Data->{forms}->{$name}->{expression} = "n%1000000==$1&&n!=$2";
  } elsif ($name eq 'never') {
    $Data->{forms}->{$name}->{expression} = "1==0";
  } else {
    die "Unknown form name |$name|";
  }
  $Data->{forms}->{$name}->{expression} =~ s/(?<![0-9])0([0-9]+)/$1/g;

  my $expr = $Data->{forms}->{$name}->{expression};
  $expr =~ s/n/\$n/g;
  my @num;
  for my $n (0..999, 1000000) {
    eval $expr;
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
  $expr =~ s/n/\$n/g;
  $data->{forms}->[$n-1] ||= [];
      for my $n (0..999, 1000000) {
        my $r = eval $expr;
        die "|$expr|: $@" if $@;
        push @{$data->{forms}->[$r] ||= []}, $n;
      }

      my $replaced = {};
      for (@{$data->{forms}}) {
        $_ = defined $_ ? (join ' ', @$_) : '';
        if (defined $FormNames->{$_}) {
          $_ = $FormNames->{$_};
          $replaced->{$_} = 1;
        }
      }
      if (@{$data->{forms}} == 1 + keys %$replaced) {
        for (@{$data->{forms}}) {
          $_ = 'everything else', $replaced->{$_}++ if not $replaced->{$_};
        }
      }
      if (@{$data->{forms}} != keys %$replaced) {
        for (@{$data->{forms}}) {
          warn $_ unless $replaced->{$_};
        }
        die "An unknown form found ($expr_orig)";
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
  return ($sorted_key, $key);
} # expr

{
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
  my $path = path (__FILE__)->parent->parent->child ('src/plural-additional.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^nplurals=([0-9]+);plural=(.+?);?$/) {
      expr $1, $2, dont_add => 1;
    } elsif (/\S/) {
      warn "Broken line: |$_|";
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
