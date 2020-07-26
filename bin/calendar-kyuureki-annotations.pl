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
}

{
  my $data_path = $RootPath->child ('src/kyuureki-annotations.txt');
  my $name;
  for (split /\n/, decode_web_utf8 $data_path->slurp) {
    if (/^\*\s*(\S+)\s*$/) {
      $name = $1;
    } elsif (/^(title|url)\s+(\S.*)$/) {
      my $key = $1;
      my $value = $2;
      $value =~ s/\s*$//g;
      $Data->{props}->{$name}->{$key} = $value;
    } elsif (/^(data|broken)$/) {
      $Data->{props}->{$name}->{$1} = 1;
    } elsif (/^(data)\s+(partial)$/) {
      $Data->{props}->{$name}->{$1.'_'.$2} = 1;
    } elsif (/^m\s+(.+)$/) {
      for my $m (split /\s+/, $1) {
        $Data->{months}->{$m}->{$name} = 1;
      }
    } elsif (/^\s*#/) {
      #
    } elsif (/\S/) {
      die $_;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
