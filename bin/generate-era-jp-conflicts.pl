use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $path = path (__FILE__)->parent->parent->child ('local/view/calendar-era-defs.json');
my $json = json_bytes2perl $path->slurp;

my $Data = {};

for my $name (keys %{$json->{name_to_keys}}) {
  my $is_jp;
  my $is_jp_emp;
  my $is_jp_priv;
  my $is_other;
  my $jp_key;
  my $other_keys = {};
  for my $key (keys %{$json->{name_to_keys}->{$name}}) {
    my $data = $json->{eras}->{$key};
    if ($data->{jp_era} or $data->{jp_north_era} or $data->{jp_south_era}) {
      $is_jp = 1;
      $jp_key = $data->{key};
    } elsif ($data->{jp_emperor_era}) {
      $is_jp_emp = 1;
      $jp_key = $data->{key};
    } elsif ($data->{jp_private_era}) {
      $is_jp_priv = 1;
      $jp_key ||= $data->{key};
    } else {
      $is_other = 1;
      $other_keys->{$data->{key}} = 1;
    }
  }
  for my $other_key (keys %$other_keys) {
    $Data->{jp__other}->{$jp_key}->{$other_key} = 1 if $is_jp;
    $Data->{jp_emp__other}->{$jp_key}->{$other_key} = 1 if $is_jp_emp;
    $Data->{jp_priv__other}->{$jp_key}->{$other_key} = 1 if $is_jp_priv;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
