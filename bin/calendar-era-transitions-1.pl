use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $Data;
{
  my $path = $RootPath->child ('local/era-transitions-0.json');
  my $json = json_bytes2perl $path->slurp;
  $Data = $json;
}

for (grep { /^_/ } keys %$Data) {
  delete $Data->{$_};
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
