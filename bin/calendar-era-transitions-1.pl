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

delete $Data->{_ERA_TAGS};

print perl2json_bytes_for_record $Data;

## License: Public Domain.
