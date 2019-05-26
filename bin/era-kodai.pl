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
  $EraOffset->{孝徳} = 645-1;
  $EraOffset->{天智} = 662-1;
  $EraOffset->{天武} = 672-1;
  $EraOffset->{持統} = 687-1;
  $EraOffset->{文武} = 697-1;
}
sub year ($) {
  my $v = $_[0];
  if ($v =~ /^[0-9]+$/) {
    return 0+$v;
  } elsif ($v =~ /^BC([0-9]+)$/) {
    return 1-$1;
  } elsif ($v =~ /^(\p{Hani}+)([0-9]+)$/ and defined $EraOffset->{$1}) {
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
    } elsif (/^([\w\x{25A1},]+)\s+([\w,?]+)\s+([0-9,+]+)(?:\s+#[0-9]+|)$/) {
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
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}


print perl2json_bytes_for_record $Data;

## License: Public Domain.
