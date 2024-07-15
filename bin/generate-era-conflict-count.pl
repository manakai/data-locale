use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $path = path (__FILE__)->parent->parent->child ('local/view/calendar-era-defs.json');
my $json = json_bytes2perl $path->slurp;

my $Data = {};

for my $name (keys %{$json->{name_to_keys}}) {
  my $count = 0+keys %{$json->{name_to_keys}->{$name}};
  push @{$Data->{$count} ||= []}, $name if $count > 1;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
