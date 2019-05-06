use strict;
use warnings;
use utf8;
use JSON::PS;
use Path::Tiny;

my $root_path = path (__FILE__)->parent->parent;

my $json_path = $root_path->child ('src/wp-jp-eras.json');
my $json = json_bytes2perl $json_path->slurp;

my $Data = {};

for (values %$json) {
  my $data = $Data->{eras}->{$_->{name}} ||= {};
  $data->{name} = $_->{name};
  $data->{name_ja} = $_->{name};
  $data->{key} = $_->{name};
  for my $key (qw(wref_ja)) { # name_kana name_kanas
    if (defined $_->{$key}) {
      $data->{$key} = $_->{$key};
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
