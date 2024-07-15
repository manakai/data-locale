use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $in_name = shift;
my $out_name = shift;

my $in_path = path ($in_name);
my $in_json = json_bytes2perl $in_path->slurp;

my $part_size = 2000;
$part_size = 1500 if $in_name =~ /tag/;
$part_size = 500 if $in_name =~ /era-labels|era-relations/;

my $out_parts = [];
my $out_parts_x = [];
{
  for my $key (qw(eras tags)) {
    next unless defined $in_json->{$key};
    for my $k (keys %{$in_json->{$key}}) {
      my $i = $in_json->{$key}->{$k}->{id} // $k;
      my $part = int ($i / $part_size);
      $out_parts->[$part]->{$key}->{$k} = $in_json->{$key}->{$k};
    }
    push @{$out_parts->[0]->{_parts}->{keys} ||= []}, $key;
  }
  {
    my $part = 0;
    my $last_year = -"Inf";
    for (@{$in_json->{transitions} or []}) {
      my $year = ($_->{day} || $_->{day_start})->{year};
      if (@{$out_parts->[$part]->{transitions} or []} > $part_size) {
        if ($year == $last_year) {
          #
        } else {
          $part++;
        }
      }
      push @{$out_parts->[$part]->{transitions} ||= []}, $_;
      $last_year = $year;
    }
  }
  for (keys %$in_json) {
    next if {qw(eras 1 tags 1 transitions 1)}->{$_};
    if ({qw(name_conflicts 1 name_to_key 1)}->{$_}) {
      $out_parts_x->[0]->{$_} = $in_json->{$_};
    } elsif ({qw(numbers_in_era_names 1 name_to_keys 1)}->{$_}) {
      $out_parts_x->[1]->{$_} = $in_json->{$_};
    } else {
      $out_parts->[0]->{$_} = $in_json->{$_};
    }
  }
  $out_parts->[0]->{_parts}->{max} = $#$out_parts;
  $out_parts->[0]->{_parts}->{extra_max} = $#$out_parts_x;
}

for my $i (0..$#$out_parts) {
  my $out_path = path ("$out_name-$i.json");
  $out_path = path ("$out_name.json") if $i == 0;
  $out_path->spew (perl2json_bytes_for_record $out_parts->[$i]);
}
for my $i (0..$#$out_parts_x) {
  my $out_path = path ("$out_name-x$i.json");
  $out_path->spew (perl2json_bytes_for_record $out_parts_x->[$i]);
}

## License: Public Domain.
