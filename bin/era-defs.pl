use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $Data = {};

for my $file_name (qw(
  era-defs-jp.json era-defs-jp-emperor.json
)) {
  my $path = $root_path->child ('local')->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    if (defined $Data->{eras}->{$key}) {
      die "Duplicate era key |$key|";
    }
    $Data->{eras}->{$key} = $json->{eras}->{$key};
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
