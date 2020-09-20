use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::Encoding;

my $RootPath = path (__FILE__)->parent->parent;

my $Data = {};

{
  my $genten_path = $RootPath->child ('data/calendar/kyuureki-genten.json');
  my $genten = json_bytes2perl $genten_path->slurp;
  for my $month (keys %{$genten->{notes}}) {
    my $n = $genten->{notes}->{$month};
    $Data->{months}->{$month}->{j459} = 1 if $n->{use_computed_value};
    $Data->{months}->{$month}->{j462} = 1 if $n->{vary_by_algorithm};
    $Data->{months}->{$month}->{j464} = 1 if $n->{misc_note};
    $Data->{months}->{$month}->{j463} = 1 if $n->{might_be_advanced};
    $Data->{months}->{$month}->{j460} = 1 if $n->{use_fixed_value};
  }
  for (keys %{$genten->{mapping}}) {
    $Data->{maps}->{j504}->{$genten->{mapping}->{$_}} = $_;
  }
}

use POSIX;
sub j2jd (@) {
  my $y = $_[0] + floor (($_[1] - 3) / 12);
  my $m = ($_[1] - 3) % 12;
  my $d = $_[2] - 1;
  my $n = $d + floor ((153 * $m + 2) / 5) + 365 * $y + floor ($y / 4);
  my $mjd = $n - 678883;
  my $jd = $mjd + 2400000.5;
  return $jd;
} # j2jd

sub jd2gymd ($) {
  my @time = gmtime (($_[0] - 2440587.5) * 24 * 60 * 60);
  return undef unless defined $time[5];
  return ($time[5]+1900, $time[4]+1, $time[3]);
} # jd2gymd

sub ymd2string (@) {
  if ($_[0] < 0) {
    return sprintf "-%04d-%02d-%02d", -$_[0], $_[1], $_[2];
  } else {
    return sprintf "%04d-%02d-%02d", @_;
  }
} # ymd2string

sub ymmd2string (@) {
  if ($_[0] < 0) {
    return sprintf "-%04d-%02d%s-%02d", -$_[0], $_[1], $_[2]?"'":'', $_[3];
  } else {
    return sprintf "%04d-%02d%s-%02d", $_[0], $_[1], $_[2]?"'":'', $_[3];
  }
} # ymmd2string

{
  my $data_path = $RootPath->child ('src/kyuureki-annotations.txt');
  my $name;
  my $prev_data;
  for (split /\n/, decode_web_utf8 $data_path->slurp) {
    if (/^\*\s*(\S+)\s*$/) {
      $name = $1;
    } elsif (/^(title|url)\s+(\S.*)$/) {
      my $key = $1;
      my $value = $2;
      $value =~ s/\s*$//g;
      $Data->{props}->{$name}->{$key} = $value;
    } elsif (/^(data|broken|old|qreki)$/) {
      $Data->{props}->{$name}->{$1} = 1;
      $Data->{props}->{$name}->{broken} = 1 if $1 eq 'qreki';
    } elsif (/^(data)\s+(partial)$/) {
      $Data->{props}->{$name}->{$1.'_'.$2} = 1;
    } elsif (/^m\s+(.+)$/) {
      for my $m (split /\s+/, $1) {
        $Data->{months}->{$m}->{$name} = 1;
      }
    } elsif (/^(?:(j:)(-?[0-9]+)-([0-9]+)-([0-9]+)\s+|)(?:([01]{13})\s+([0-9]+)|([01]{12}))\s*$/) {
      my $jg = $1;
      my $ymd = [$2, $3, $4];
      my $leap = $6 || 100;
      my $sizes = [split //, $5 || $7];
      my $jd;
      if (not defined $ymd->[0]) {
        $jd = $prev_data->[1];
        $ymd = [$prev_data->[0] + 1, undef, undef];
      } else {
        $jd = j2jd @$ymd;
      }
      for (0..$#$sizes) {
        my $m = $_ + ($_ < $leap ? 1 : 0);
        my $l = $leap == $m && $m == $_;
        my $k = ymmd2string $ymd->[0], $m, $l, 1;
        my $g = ymd2string jd2gymd $jd;
        if (defined $Data->{maps}->{$name}->{$k} and
            not $Data->{maps}->{$name}->{$k} eq $g) {
          die "Conflict |$k|: |$g| (was: |$Data->{maps}->{$name}->{$k}|)";
        }
        $Data->{maps}->{$name}->{$k} = $g;
        $jd += $sizes->[$_] ? 30 : 29;
      }
      {
        my $k = ymmd2string $ymd->[0]+1, 1, '', 1;
        my $g = ymd2string jd2gymd $jd;
        if (defined $Data->{maps}->{$name}->{$k} and
            not $Data->{maps}->{$name}->{$k} eq $g) {
          die "Conflict |$k|: |$g| (was: |$Data->{maps}->{$name}->{$k}|)";
        }
        $Data->{maps}->{$name}->{$k} = $g;
      }
      $prev_data = [$ymd->[0], $jd];
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
