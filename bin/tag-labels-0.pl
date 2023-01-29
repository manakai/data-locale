use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Carp;
use JSON::PS;

require (path (__FILE__)->parent->child ("names.pl")->absolute);

my $Data = {};
my $RootPath = path (__FILE__)->parent->parent;

print STDERR "Loading...";
{
  my $path = $RootPath->child ('local/tags-0.json');
  my $json = json_bytes2perl $path->slurp;
  for my $in_data (values %{$json->{tags}}) {
    $Data->{tags}->{$in_data->{id}}->{id} = $in_data->{id};
    $Data->{tags}->{$in_data->{id}}->{key} = $in_data->{key};
    $Data->{tags}->{$in_data->{id}}->{_LABELS} = $in_data->{_LABELS};
  }
}
print STDERR "done\n";

names::process_object_labels
    ([values %{$Data->{tags}}], {}, sub { }, $Data);

print perl2json_bytes_for_record $Data;

## License: Public Domain.
