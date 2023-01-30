use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $Data;
{
  my $path = $RootPath->child ('local/tags-0.json');
  $Data = json_bytes2perl $path->slurp;
}

{
  my $path = $RootPath->child ('local/tag-labels-0.json');
  my $json = json_bytes2perl $path->slurp;
  for my $tag_id (keys %{$json->{tags}}) {
    $Data->{tags}->{$tag_id}->{_SHORTHANDS} = $json->{tags}->{$tag_id}->{_SHORTHANDS};
  }
}

for my $data (values %{$Data->{tags}}) {
  for my $key (keys %{$data->{_SHORTHANDS} or {}}) {
    $data->{$key} = $data->{_SHORTHANDS}->{$key};
  }
  delete $data->{_SHORTHANDS};
  
  $data->{label} //= $data->{name} // $data->{key};
  
  for my $key (grep { /^_/ } keys %$data) {
    delete $data->{$key};
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
