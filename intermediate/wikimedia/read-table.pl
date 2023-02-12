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
my $MonthNum = qr{[正一二三四五六七八九十]|十[一二]};
my $Kanshi = qr{(?!初)\p{sc=Han}{2}};
my $ToNumber = {
  一 => 1, 二 => 2, 三 => 3, 四 => 4, 五 => 5,
  六 => 6, 七 => 7, 八 => 8, 九 => 9, 十 => 10,
  '' => 0,
  正 => 1,
};
sub parse_number ($) {
  my $s = shift;
  if ($s =~ m{^([一二三四五六七八九])十([一二三四五六七八九]?)$}) {
    return $ToNumber->{$1} * 10 + $ToNumber->{$2};
  } elsif ($s =~ m{^十([一二三四五六七八九])$}) {
    return 10 + $ToNumber->{$1};
  } elsif ($s =~ m{^([正一二三四五六七八九十])$}) {
    return $ToNumber->{$1};
  } else {
    die $s;
  }
} # parse_number

my $Current = [];
my $Header;
if ($Data->{source_type} eq 'table5') {
  $Header->[0] = '漢';
} else {
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
      /^(.)/ ? $1 : die "Bad header |$_|";
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
        die "Conflicting |$key| ($i) |$cell| ($n) [current: $Data->{eras}->{$key}->{years}->[$n], new: $year]";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      $Data->{eras}->{$key}->{dead_year} = $n2;
      next;
    } elsif ($cell =~ m{^(二十)。(代王義)徙清河年。是為剛王。$}) {
      my $n = parse_number $1;
      my $key = $2;
      if (defined $Data->{eras}->{$key}->{years}->[$n]) {
        die "Conflicting |$key| ($i) |$cell| ($n [$1]) [current: $Data->{eras}->{$key}->{years}->[$n], new: $year]";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      push @{$Data->{eras}->{$key}->{new_countries} ||= []}, {
        prev_country => '代',
        country => $Header->[$i],
        name => $Header->[$i] . '王義',
        year => $year,
        prev => $Current->[$i],
      };
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      $Current->[$i] = $key;
      next;
    } elsif ($cell =~ m{^三。(太原王參更號為代王三年，實居太原，是為孝王。)$}) {
      $cell = $1;
      my $key = '太原王參';
      push @{$Data->{eras}->{$key}->{names} ||= []},
          {country => '代', king_name => '孝王'};
    } elsif ($cell =~ m{^十一。反，誅。(濟北王志徙菑川十一年。是為懿王。)$}) {
      $cell = $1;
      my $key = '濟北王志';
      push @{$Data->{eras}->{$key}->{names} ||= []},
          {country => '菑川', king_name => '懿王'};
      push @{$Data->{eras}->{$key}->{new_countries} ||= []}, {
        prev_country => $Data->{eras}->{$key}->{country},
        country => '菑川',
        name => '菑川',
        year => $year,
        prev => $Current->[$i],
      };
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      $Current->[$i] = $key;
      next;
    } elsif ($cell =~ s{^($Num)(?!月|世|(?<=十)一月|(?<=十)二月)[\p{sc=Han}，、：「」⒧]*(?:。|$)}{}o) {
      my $n = parse_number $1;
      my $key = $Current->[$i];
      die "No key for $i ($cell)" unless defined $key;
      if ($key eq '廣川王彭祖' and $n == 4) {
        next;
      }
      if (defined $Data->{eras}->{$key}->{years}->[$n]) {
        die "Conflicting |$key| ($i) |$cell| ($n [$1]) [current: $Data->{eras}->{$key}->{years}->[$n], new: $year]";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key| (|$Header->[$i]| expected, |$Data->{eras}->{$key}->{country}|)";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      next unless $cell =~ /元年|為郡|國除|廢|國為\p{sc=Han}+郡/;
    } elsif ($cell =~ s{^更為(\p{sc=Han}+)國。}{}) {
      $Header->[$i] = $1;
      undef $Current->[$i];
    } elsif ($cell =~ s{^置(六安)國，以故陳為都。}{}) {
      $Header->[$i] = $1;
      undef $Current->[$i];
    } elsif ($Data->{source_type} eq 'table5' and
             $cell =~ s/^(?:[初復]置|分為)(\p{sc=Han}+)(?:。|，)//) {
      $Header->[$i] = $1;
      $Header->[$i] =~ s/[國郡]$//;
      $Current->[$i] = undef;
      $Data->{countries}->{$Header->[$i]} = 1;
    } elsif ($cell =~ s/^(哀王安世)元年。即//) {
      my $key = $Header->[$i] . $1;
      $Data->{eras}->{$key}->{years}->[1] = $year;
      $Data->{eras}->{$key}->{era_name} = $1;
      if (defined $Data->{eras}->{$key}->{country} and
          not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
        die "Bad country for |$key|";
      }
      $Data->{eras}->{$key}->{country} = $Header->[$i];
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
    }
    if ($cell =~ m{^(惠王|莊侯|始皇帝|代王嘉|二世)元年(?:。|十月|$)}) {
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
    } elsif ($cell =~ m{。(晉侯湣|衛戴公|初更|王呂產)元年。?$}) {
      my $key = $1;
      if ($key eq '王呂產') {
        $key = $Header->[$i] . $key;
        $Data->{eras}->{$key}->{era_name} = '王呂產';
        #$Data->{eras}->{$key}->{prev_other} = '呂產';
        $Data->{eras}->{$key}->{person} = '呂產';
      }
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
    } elsif ($cell =~ s{^(?:鄭立幽公子，為|(?!$MonthNum)\p{sc=Han}+(?<!元年)。|)(?!$MonthNum)(\p{sc=Han}+?)，?元年(?:。(\p{sc=Han}+)元年|)}{}o) {
      my $key = $1;
      my $x = $2;
      if ($Data->{source_type} eq 'table5') {
        if ($key =~ s/^初王(\p{sc=Han}+)王//) {
          my $k = '初王' . $1 . '王' . $key;
          $key = $Header->[$i] . $1 . '王' . $key;
          $Data->{eras}->{$key}->{first} = 1;
          $Data->{eras}->{$key}->{first_country} = $Header->[$i];
          $Data->{eras}->{$key}->{era_name} = $k;
        } elsif ($key =~ s/^初王//) {
          my $k = '初王' . $key;
          $key = $Header->[$i] . '王' . $key;
          $Data->{eras}->{$key}->{first} = 1;
          $Data->{eras}->{$key}->{first_country} = $Header->[$i];
          $Data->{eras}->{$key}->{era_name} = $k;
        } elsif ($key =~ /^(\p{sc=Han}+)王(\p{sc=Han}+)徙為(\p{sc=Han}+)王$/) {
          $key = $3 . '王' . $2;
          $Data->{eras}->{$key}->{prev_country} = $1;
          $Data->{eras}->{$key}->{prev_key} = $1 . '王' . $2;
          $Data->{eras}->{$key}->{person} = $1 . '王' . $2;
          $Data->{eras}->{$key}->{era_name} = $3 . '王';
        } elsif ($key eq '城陽王喜徙淮南') {
          $key = '淮南王喜';
          $Data->{eras}->{$key}->{person} = '城陽共王喜';
          $Data->{eras}->{$key}->{era_name} = '王喜';
          $Data->{eras}->{$key}->{prev_country} = '淮南';
          $Data->{eras}->{$key}->{prev_key} = '城陽共王喜';
          $Data->{eras}->{$key}->{country} = $Header->[$i];
        } elsif ($key eq '廬江王賜徙衡山') {
          $key = '衡山王賜';
          $Data->{eras}->{$key}->{person} = '廬江王賜';
          $Data->{eras}->{$key}->{era_name} = '衡山';
          $Data->{eras}->{$key}->{prev_country} = '廬江';
          $Data->{eras}->{$key}->{prev_key} = '廬江王賜';
          $Data->{eras}->{$key}->{country} = $Header->[$i];
        } elsif ($key =~ /^(\p{sc=Han}+)王(\p{sc=Han}+)$/) {
          my $k = $key;
          $key = $Header->[$i] . $1 . '王' . $2;
          $Data->{eras}->{$key}->{era_name} = $k;
        } elsif ($key =~ /^王(\p{sc=Han}+)$/) {
          my $k = $key;
          $key = $Header->[$i] . '王' . $1;
          $Data->{eras}->{$key}->{era_name} = $k;
        } elsif ($key =~ /^[中後]$/) {
          $key = $Current->[$i] . $key;
          $key =~ s/中(.)$/$1/;
        } elsif ($key =~ /^(\p{sc=Han})王$/) {
          my $k = $key;
          $key = $Header->[$i] . $1 . '王';
          $Data->{eras}->{$key}->{era_name} = $k;
        } else {
          my $k = $key;
          $key = $Header->[$i] . '王' . $key;
          $Data->{eras}->{$key}->{era_name} = $k;
        }
        $Data->{eras}->{$key}->{_branch} = 1;
      }
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell| ($key)";
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
      } elsif ($Data->{source_type} eq 'table3') {
        if ($key eq '繻公') {
          $Data->{eras}->{$key}->{country} = '鄭';
        } else {
          $Data->{eras}->{$key}->{country} = substr $key, 0, 1;
        }
      } else {
        if (defined $Current->[$i]) {
          $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
        }
        $Data->{eras}->{$key}->{country} = $Header->[$i];
        $Current->[$i] = $key;
      }
      if (defined $x) {
        my $key = $x;
        if (defined $Data->{eras}->{$key}->{years}->[1]) {
          die "Conflicting |$cell|";
        }
        $Data->{eras}->{$key}->{years}->[1] = $year;
        $Data->{eras}->{$key}->{country} = substr $key, 0, 1;
      }
      if ($cell =~ /國除/) {
        if (defined $Data->{eras}->{$key}->{end_year}) {
          die "Multiple end_year for $key, $year";
        }
        $Data->{eras}->{$key}->{end_year} = $year;
        undef $Current->[$i];
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
    } elsif ($cell =~ m{^(\p{sc=Han}+?)($Num)[年。](?:(\p{sc=Han}+?)元年|)}o) {
      my $key = $1;
      my $n = parse_number $2;
      if ($key eq '代王武徙淮陽') {
        $key = '代王武';
        push @{$Data->{eras}->{$key}->{new_countries} ||= []}, {
          prev_country => $Data->{eras}->{$key}->{country},
          country => '淮陽',
          name => '淮陽王武',
          year => $year,
          prev => $Current->[$i],
        };
        $Data->{eras}->{$key}->{country} = '淮陽';
      } elsif ($key eq '太原王參更號為代王') {
        $key = '太原王參';
        push @{$Data->{eras}->{$key}->{new_countries} ||= []}, {
          prev_country => $Data->{eras}->{$key}->{country},
          country => '代',
          name => '代王參',
          year => $year,
          prev => $Current->[$i],
        };
        $Data->{eras}->{$key}->{country} = '代';
      } elsif ($key eq '廣川王彭祖徙趙') {
        $key = '廣川王彭祖';
        push @{$Data->{eras}->{$key}->{new_countries} ||= []}, {
          prev_country => $Data->{eras}->{$key}->{country},
          country => $Header->[$i],
          name => '敬肅王',
          year => $year,
          prev => $Current->[$i],
        };
        $Data->{eras}->{$key}->{country} = $Header->[$i];
      } elsif ($key eq '衡山王勃徙濟北') {
        $key = '衡山王勃';
        push @{$Data->{eras}->{$key}->{new_countries} ||= []}, {
          prev_country => $Data->{eras}->{$key}->{country},
          country => $Header->[$i],
          name => '貞王',
          year => $year,
          prev => $Current->[$i],
        };
        $Data->{eras}->{$key}->{country} = $Header->[$i];
      } elsif ($key eq '淮南王喜徙城陽') {
        $key = '城陽共王喜';
        $Current->[$i] = $key;
        next;
      } else {
        if (defined $Data->{eras}->{$key}->{country} and
            not $Data->{eras}->{$key}->{country} eq $Header->[$i]) {
          die "Bad country for |$key|";
        }
        $Data->{eras}->{$key}->{country} = $Header->[$i];
        if (defined $Current->[$i]) {
          $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
        }
      }
      if (defined $Data->{eras}->{$key}->{years}->[$n] and
          not $key eq '太原王參' and
          not $key eq '衡山王勃') {
        die "Conflicting |$cell| ($n, |$key|, $Data->{eras}->{$key}->{years}->[$n])";
      }
      $Data->{eras}->{$key}->{years}->[$n] = $year;
      $Current->[$i] = $key;
      if (defined $3) {
        my $key = $3;
        if (defined $Data->{eras}->{$key}->{years}->[1]) {
          die "Conflicting |$cell|";
        }
        $Data->{eras}->{$key}->{years}->[1] = $year;
        $Data->{eras}->{$key}->{country} = substr $key, 0, 1;
      }
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

    } elsif ($cell =~ /^(?:嘉廢。|呂產徙王梁。|反，誅。|)(後|)($MonthNum)月($Kanshi|)[，。]?(\p{sc=Han}+)元年[。，]/o) {
      my $m = parse_number $2;
      my $lm = !! $1;
      my $dk = $3 || undef;
      my $key = $4;
      if (defined $Data->{eras}->{$key} and
          defined $Data->{eras}->{$key}->{years}->[1] and
          $key eq '初王武') {
        $key = $Header->[$i] . $key;
      }
      if ($key =~ s/^初王(\p{sc=Han}+)王//) {
        my $k = '初王' . $1 . '王' . $key;
        $key = $Header->[$i] . $1 . '王' . $key;
        $Data->{eras}->{$key}->{first} = 1;
        $Data->{eras}->{$key}->{first_country} = $Header->[$i];
        $Data->{eras}->{$key}->{era_name} = $k;
      } elsif ($key eq '初王' and $m == 1) {
        $key = '代王劉恒';
        $Data->{eras}->{$key}->{first} = 1;
        $Data->{eras}->{$key}->{first_country} = $Header->[$i];
        #$Data->{eras}->{$key}->{start_day} = [1, '', '丙子'];
        $Data->{eras}->{$key}->{era_name} = '初王';
      } elsif ($key eq '初王' and $Header->[$i] eq '膠東') {
        $key = '膠東王劉徹';
        $Data->{eras}->{$key}->{first} = 1;
        $Data->{eras}->{$key}->{first_country} = $Header->[$i];
        $Data->{eras}->{$key}->{era_name} = '初王';
        $Data->{eras}->{$key}->{person} = '漢武帝';
      } elsif ($key =~ s/^初王//) {
        my $k = '初王' . $key;
        $key = $Header->[$i] . '王' . $key;
        $Data->{eras}->{$key}->{first} = 1;
        $Data->{eras}->{$key}->{first_country} = $Header->[$i];
        $Data->{eras}->{$key}->{era_name} = $k;
      } elsif ($key eq '琅邪王澤徙燕') {
        $key = '燕敬王澤';
        $Data->{eras}->{$key}->{person} = '琅邪王澤';
        $Data->{eras}->{$key}->{era_name} = '敬王';
        $Data->{eras}->{$key}->{prev_country} = '琅邪';
        $Data->{eras}->{$key}->{prev_key} = '琅邪王澤';
        $Data->{eras}->{$key}->{country} = $Header->[$i];
      } elsif ($key eq '汝南王非為江都王') {
        $key = '江都王非';
        $Data->{eras}->{$key}->{person} = '汝南王非';
        push @{$Data->{eras}->{$key}->{names} ||= []},
            {country => '江都', king_name => '易王'};
        $Data->{eras}->{$key}->{era_name} = '江都王';
        $Data->{eras}->{$key}->{prev_country} = '汝南';
        $Data->{eras}->{$key}->{prev_key} = '汝南王非';
        $Data->{eras}->{$key}->{country} = $Header->[$i];
      } elsif ($key eq '淮陽王徙魯') {
        $key = '魯恭王餘';
        $Data->{eras}->{$key}->{prev_country} = '淮陽';
        $Data->{eras}->{$key}->{prev_key} = '淮陽王餘';
        $Data->{eras}->{$key}->{person} = '淮陽王餘';
      } elsif ($key =~ /^(\p{sc=Han}+)王(\p{sc=Han}+)$/ and
               not $1 eq $Header->[$i]) {
        $key = $Header->[$i] . $1 . '王' . $2;
        $Data->{eras}->{$key}->{era_name} = $1 . '王' . $2;
      } elsif (not $key =~ /^王?\Q$Header->[$i]\E/) {
        my $k = $key;
        $key = $Header->[$i] . $key;
        $Data->{eras}->{$key}->{era_name} = $k;
      }
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell| ($key)";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      $Data->{eras}->{$key}->{first_country} =
      $Data->{eras}->{$key}->{country} = $Header->[$i] // die "Bad $i ($cell)";
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;
      $Data->{eras}->{$key}->{start_day} = [$m, $lm, $dk];
    } elsif ($cell =~ /^(淮陽)王徙於(趙)，名(友)，元年。是為(幽王)。/o) {
      my $key = $2.$4.$3;
      if (defined $Data->{eras}->{$key}->{years}->[1]) {
        die "Conflicting |$cell|";
      }
      $Data->{eras}->{$key}->{years}->[1] = $year;
      $Data->{eras}->{$key}->{country} = $Header->[$i] // die;
      $Data->{eras}->{$key}->{person} = $1 . '王' . $3;
      $Data->{eras}->{$key}->{era_name} = $3;
      $Data->{eras}->{$key}->{prev_country} = $1;
      $Data->{eras}->{$key}->{prev_key} = $1 . '王' . $3;
      if (defined $Current->[$i]) {
        $Data->{eras}->{$key}->{prev}->{$year} = $Current->[$i];
      }
      $Current->[$i] = $key;

    } elsif ($Data->{source_type} eq 'table5' and
             not defined $Header->[$i] and
             $cell =~ /^(\p{sc=Han}+)。$/) {
      $Header->[$i] = $1;
    } elsif ($cell =~ /為郡|廢為侯|國除|國為\p{sc=Han}+郡/) {
      if (defined $Current->[$i]) {
        my $key = $Current->[$i];
        if (defined $Data->{eras}->{$key}->{end_year}) {
          die "Multiple end_year for $key, $year";
        }
        $Data->{eras}->{$key}->{end_year} = $year;
        undef $Current->[$i];
      }
    } elsif ($cell =~ /^(?:韓宣子|晉定公卒。|鄭聲公卒。|衛出公飲|知伯伐鄭|魏桓子敗|韓康子敗|都\p{sc=Han}+。$|更為廣陵國。|知伯謂簡子|分為|分楚復置|。$|明殺中傅。廢遷房陵。|十一月乙丑太子廢$|廢。$)/) {
      #
    } elsif ($cell =~ /\S/) {
      die $cell;
    }
  } continue {
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
            $key eq '衛惠公朔' or $key eq '初王獻王德' or
            $key eq '城陽共王喜' or $key eq '河閒獻王德') {
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

for (@$Header) {
  $Data->{countries}->{$_} = 1;
}
for (values %{$Data->{eras}}) {
  $Data->{countries}->{$_->{country}} = 1;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
