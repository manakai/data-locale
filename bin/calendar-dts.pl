use strict;
use warnings;
use JSON::PS;
use Path::Tiny;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

for my $key (qw(dtsjp1 dtsjp2 dtsjp3)) {
  my $path = $RootPath->child ("local/$key.json");
  my $data = json_bytes2perl $path->slurp;
  for (keys %{$data->{dts}}) {
    $Data->{dts}->{$_} = $data->{dts}->{$_};
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
