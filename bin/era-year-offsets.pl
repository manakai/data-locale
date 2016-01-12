use strict;
use warnings;
use JSON::PS;
use Path::Tiny;

my $root_path = path (__FILE__)->parent->parent;

my $json_path = $root_path->child ('local/wp-jp-eras-parsed.json');
my $json = json_bytes2perl $json_path->slurp;

my $g2k_map_path = $root_path->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};

my $Data = {};

for (values %$json) {
  $_->{start} =~ /^(\d+)/;
  my $start = $1 < 1873 ? $g2k_map->{$_->{start}} : $_->{start};
  die "Bad start |$_->{start}|" unless defined $start;
  $start =~ /^(\d+)/;
  my $first_year = 0+$1;
  $Data->{$_->{name}}->{offset} = $first_year - 1;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
