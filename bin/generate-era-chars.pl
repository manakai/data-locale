use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $json_path = $root_path->child ('data/calendar/era-defs.json');
my $json = json_bytes2perl $json_path->slurp;

my $chars = {};
for (values %{$json->{eras}}) {
  $chars->{$_} = 1 for split //, $_->{name}
}

my $Data = {};
$Data->{chars} = $chars;

print perl2json_bytes_for_record $Data;

## License: Public Domain.
