use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

my $EraOffset = {};
{
  use utf8;
  $EraOffset->{皇極} = 642-1;
  $EraOffset->{孝徳} = 645-1;
  $EraOffset->{大化} = 645-1;
  $EraOffset->{斉明} = 655-1;
  $EraOffset->{天智} = 662-1;
  $EraOffset->{天武} = 672-1;
  $EraOffset->{持統} = 687-1;
  $EraOffset->{文武} = 697-1;
}
sub year ($) {
  my $v = $_[0];
  if ($v =~ /^-?[0-9]{3,}$/) {
    return 0+$v;
  } elsif ($v =~ /^BC([0-9]+)$/) {
    return 1-$1;
  } elsif ($v =~ /^([\p{Hani}]+)([0-9]+)$/ and defined $EraOffset->{$1}) {
    return $EraOffset->{$1} + $2;
  } elsif ($v eq '?') {
    return undef;
  } else {
    die "Bad year |$v|";
  }
} # year

sub start_years ($) {
  my $w = [];
  for (split /,/, $_[0]) {
    push @$w, year $_;
  }
  return $w;
} # start_years

sub era_length ($$) {
  my $v = $_[1];
  my $w = 1;
  for (split /,/, $_[0]) {
    if (/^([0-9]+)\+?$/) {
      $w = 0+$1 if $w < $1;
    } else {
      die "Bad length |$_|";
    }
  }
  $v->{length} = $w;
} # era_length

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

{
  my $path = $RootPath->child ('src/era-kodai.txt');
  my $ref;
  my $data;
  my $fill_prev_length;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^\*\s*\[([1-9][0-9]*)\]\s*$/) {
      $ref = $1;
      $data = $Data->{$ref} = {eras => []};
    } elsif (not defined $ref and /\S/) {
      die "Bad line |$_|";
    } elsif (/^([\w\x{25A1}\x{2FF0}-\x{2FFF},]+)\s+([\w,?-]+)\s+([0-9,+]+)(?:\s+#[0-9]+|)$/) {
      my $names = $1;
      my $v = {};
      era_length $3 => $v;
      my $years = start_years $2;
      $v->{names} = [split /,/, $names];
      my $prev = $data->{eras}->[-1];
      if (@$years) {
        for (@$years) {
          if (defined $_) {
            push @{$data->{eras}}, {%$v, start_year => $_};
            use utf8;
            if ($ref == 6000 and $v->{names}->[0] =~ /^(\w+)天皇$/) {
              $EraOffset->{$1} //= $years->[0] - 1;
            }
          } else {
            push @{$data->{eras}}, $v;
          }
        }
      } else {
        push @{$data->{eras}}, $v;
      }
      if ($fill_prev_length) {
        $prev->{length} = $years->[0] - $prev->{start_year};
      }
      $fill_prev_length = 0;
    } elsif (/^([\w]+)\s+([0-9]+)=([0-9]+)(?:\s+([0-9]+)|)$/) {
      my $names = $1;
      my $ey = 0+$2;
      my $gy = 0+$3;
      my $max = defined $4 ? 0+$4 : $ey;
      my $v = {};
      era_length $max => $v;
      my $years = start_years $gy-$ey+1;
      $v->{names} = [split /,/, $names];
      if (@$years) {
        for (@$years) {
          if (defined $_) {
            push @{$data->{eras}}, {%$v, start_year => $_};
          } else {
            push @{$data->{eras}}, $v;
          }
        }
      } else {
        push @{$data->{eras}}, $v;
      }
    } elsif (/^([0-9]+|BC[0-9]+)\s+([\w,]+)(?:\s+([\p{Hiragana},]+)|)$/) {
      my $names = $2;
      my $yomis = $3 // '';
      my $v = {start_year => year ($1)};
      era_length '1+' => $v;
      delete $v->{start_year} unless defined $v->{start_year};
      $v->{names} = [split /,/, $names];
      $v->{yomis} = [split /,/, $yomis];
      delete $v->{yomis} unless @{$v->{yomis}};
      use utf8;
      if ($ref == 6000 and $v->{names}->[0] =~ /^(\w+)天皇$/) {
        $EraOffset->{$1} = $v->{start_year} - 1;
      }
      push @{$data->{eras}}, $v;
      if ($fill_prev_length) {
        $data->{eras}->[-2]->{length} = $data->{eras}->[-1]->{start_year} - $data->{eras}->[-2]->{start_year};
      }
      $fill_prev_length = 1 if $ref == 6000;
    } elsif (m{^(\w+)/(\w\w)\s+(\w+)(?:\s+([0-9]+)|)$}) {
      my $fy = $EraOffset->{$1} // die "Bad era |$1|";
      for (0..59) {
        if (year2kanshi ($fy+$_) eq $2) {
          $fy += $_;
          last;
        }
      }
      my $v = {start_year => $fy, names => [$3]};
      era_length $4 // '1+', $v;
      push @{$data->{eras}}, $v;
    } elsif (/^p\s+([0-9]+)?-([0-9]+)$/) {
      $data->{published_year_start} = 0+$1 if defined $1;
      $data->{published_year_end} = 0+$2;
    } elsif (/^p\s+([0-9]+)$/) {
      $data->{published_year_start} = 0+$1;
      $data->{published_year_end} = 0+$1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for my $ref (
  6100,
  6150,
) {
  my $path = $RootPath->child ("src/era-kodai-$ref.txt");
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^(\w+)\s+([_x]+)$/) {
      my $name = $1;
      my $v = [split //, $2];
      for (0..$#$v) {
        if ($v->[$_] eq 'x') {
          push @{$Data->{$ref+21+$_}->{eras} ||= []}, {
            names => [$name],
          };
          $Data->{$ref+21+$_}->{published_year_end} //= $Data->{$ref}->{published_year_end};
        }
      }
    }
  }
} # $ref

print perl2json_bytes_for_record $Data;

## License: Public Domain.
