use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $Data = {};

my $In;
{
  local $/ = undef;
  $In = json_bytes2perl scalar <>;
  $Data->{source_type} = $In->{source_type};
}

my $Num = qr{[一二三四五六七八九]十[一二三四五六七八九]?|十[一二三四五六七八九]|[一二三四五六七八九十]};
my $ToNumber = {
  一 => 1, 二 => 2, 三 => 3, 四 => 4, 五 => 5,
  六 => 6, 七 => 7, 八 => 8, 九 => 9, 十 => 10,
  '' => 0,
};
sub parse_number ($) {
  my $s = shift;
  if ($s =~ m{^([一二三四五六七八九])十([一二三四五六七八九]?)$}) {
    return $ToNumber->{$1} * 10 + $ToNumber->{$2};
  } elsif ($s =~ m{^十([一二三四五六七八九])$}) {
    return 10 + $ToNumber->{$1};
  } elsif ($s =~ m{^([一二三四五六七八九十])$}) {
    return $ToNumber->{$1};
  } else {
    die $s;
  }
} # parse_number

my $Current = [];
my $Header;
{
  my $row = [@{$In->{rows}->[0]}];
  shift @{$In->{rows}} if $Data->{source_type} eq 'table2';
  shift @$row;
  shift @$row if $Data->{source_type} eq 'table2';
  if ($Data->{source_type} eq 'table2') {
    $Header = [map {
      my $s = $_;
      $s =~ s/^!//;
      $s;
    } @$row];
  } else {
    $Header = [map {
      /^(.)/ ? $1 : die;
    } @$row];
  }
}
for my $row (@{$In->{rows}}) {
  next unless @$row;
  my $yy = shift @$row;
  my $year;
  if ($yy =~ m{前([0-9]+)}) {
    $year = 1 - $1;
  } else {
    die "Bad year |$yy|";
  }
  shift @$row if $Data->{source_type} eq 'table2'; # kanshi

  my $i = 0;
  for my $cell (@$row) {
    if ($cell =~ m{^($Num)(?!十四)($Num)卒。?$}o) {
      my $n = parse_number $1;
      my $n2 = parse_number $2;
      my $key = $Current->[$i];
      if (defined $Data->{eras}->{$key}->{years}->[$n]) {
        die "Conflicting |$key| |$cell| ($n) [current: $Data->{eras}->{$key}->{years}->[$n], new: $year]";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      $Data->{eras}->{$key}->{dead_year} = $n2;
    } elsif ($cell =~ m{^($Num)(?!月|世)(?:。(\p{sc=Han}+)元年|)}o) {
      my $n = parse_number $1;
      my $key = $Current->[$i];
      if (defined $Data->{eras}->{$key}->{years}->[$n]) {
        die "Conflicting |$key| |$cell| ($n) [current: $Data->{eras}->{$key}->{years}->[$n], new: $year]";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $2) {
        my $key = $2;
        if (defined $Data->{eras}->{$key}->{years}->[1]) {
          die "Conflicting |$cell|";
        }
        $Data->{eras}->{$key}->{years}->[1] = $year;
        $Data->{eras}->{$key}->{country} = substr $key, 0, 1;
      }
    } elsif ($cell =~ m{^(惠王|莊侯|始皇帝|代王嘉|二世)元年(?:。|十月|$)}) {
      my $key = $1;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    } elsif ($cell =~ m{。(晉侯湣|衛戴公|初更)元年。?$}) {
      my $key = $1;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{name} = '秦惠文王' if $key eq '初更';
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    } elsif ($cell =~ m{^(\p{sc=Han}+?)元年}) {
      my $key = $1;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      if ($Data->{source_type} eq 'table2' or
          $i == 0 or $Header->[$i] eq substr $key, 0, 1) {
        $Data->{eras}->{$key}->{country} = $Header->[$i];
        if (defined $Current->[$i]) {
          $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
        }
        $Current->[$i] = $key;
      } else {
        $Data->{eras}->{$key}->{country} = substr $key, 0, 1;
      }
    } elsif ($cell =~ m{^(\p{sc=Han}+?)。+元年}) {
      my $key = $1;
      $key =~ s/立$//;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    } elsif ($cell =~ m{(宋公馮)元年華督為相。$}) {
      my $key = $1;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    } elsif ($cell =~ m{(昭侯子)立，是為孝侯。}) {
      my $key = $1;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    } elsif ($cell =~ m{^(武王)立。$}) {
      my $key = $1;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    } elsif ($cell =~ m{^(\p{sc=Han}+?)($Num)[年。](?:(\p{sc=Han}+?)元年|)}o) {
      my $key = $1;
      my $n = parse_number $2;
      if (defined $Data->{eras}->{$key}->{years}->[$n]) {
        die "Conflicting |$cell| ($n $Data->{eras}->{$key}->{years}->[$n])";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
      if (defined $3) {
        my $key = $3;
        if (defined $Data->{eras}->{$key}->{years}->[1]) {
          die "Conflicting |$cell|";
        }
        $Data->{eras}->{$key}->{years}->[$n] = $year;
        $Data->{eras}->{$key}->{country} = substr $key, 0, 1;
      }
    } elsif ($cell =~ m{^(\p{sc=Han}+?)。($Num)。$}o) {
      my $key = $1;
      my $n = parse_number $2;
      if (defined $Data->{eras}->{$key}->{years}->[$n]) {
        die "Conflicting |$cell| ($n $Data->{eras}->{$key}->{years}->[$n])";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    } elsif ($cell =~ m{^(衛惠公朔)復入。(十四)年$}) {
      my $key = $1;
      my $n = parse_number $2;
      if (defined $Data->{eras}->{$key}->{years}->[$n]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    } elsif ($cell =~ m{^(晉武公)稱并晉，已立(三十八)年，不更元，因其元年。$}) {
      my $key = $1;
      my $n = parse_number $2;
      if (defined $Data->{eras}->{$key}->{years}->[$n]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
      
    } elsif ($cell =~ m{^魏獻子。(((衛)出公輒)後)元年。$}) {
      my $key = $1;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $3;
      $Data->{eras}->{$key}->{name} = $2;
      $Current->[$i] = $key;
    } elsif ($cell =~ /^(?:韓宣子|晉定公卒。|鄭聲公卒。|衛出公飲|知伯伐鄭|魏桓子敗|韓康子敗)/) {
      #
    } elsif ($cell =~ /\S/) {
      die $cell;
    }
    $i++;
  }
}

for my $key (keys %{$Data->{eras}}) {
  my $data = $Data->{eras}->{$key};
  my $offset;
  for my $y (1..$#{$data->{years}}) {
    my $yy = $data->{years}->[$y];
    if (not defined $yy) {
      if (defined $offset) {
        if ($key eq '燕宣侯' or $key eq '燕宣公' or
            $key eq '衛惠公朔') {
          #
        } else {
          warn "Year not defined: |$key| |$y|";
        }
      }
      next;
    }
    $data->{min_year} = $y if not defined $offset;
    my $o = $yy - $y;
    $offset //= $o;
    if ($offset != $o) {
      warn "Year mismatch: |$key| |$y| $offset $o";
    }
  }
  $data->{offset} = $offset;
}

$Data->{countries} = $Header;

print perl2json_bytes_for_record $Data;

## License: Public Domain.
