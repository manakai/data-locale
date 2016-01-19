use strict;
use warnings;
use utf8;
use JSON::PS;
use Path::Tiny;

my $root_path = path (__FILE__)->parent->parent;

my $json_path = $root_path->child ('local/wp-jp-eras-parsed.json');
my $json = json_bytes2perl $json_path->slurp;

my $g2k_map_path = $root_path->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};

my $Data = {};

my $north = {map { $_ => 1 } qw(
元徳
正慶
元弘
建武
暦応 康永 貞和 観応 文和 延文 康安 貞治 応安 永和 康暦 永徳 至徳 嘉慶 康応 明徳
)};
my $south = {map { $_ => 1 } qw(
元徳
元弘
建武
延元 興国 正平 建徳 文中 天授 弘和 元中
明徳
)};

for (values %$json) {
  $_->{start} =~ /^(\d+)/;
  my $start = $1 < 1873 ? $g2k_map->{$_->{start}} : $_->{start};
  die "Bad start |$_->{start}|" unless defined $start;
  $start =~ /^(\d+)/;
  my $first_year = 0+$1;
  $Data->{eras}->{$_->{name}}->{offset} = $first_year - 1;
  if ($south->{$_->{name}}) {
    $Data->{eras}->{$_->{name}}->{jp_south_era} = 1;
  }
  if ($north->{$_->{name}}) {
    $Data->{eras}->{$_->{name}}->{jp_north_era} = 1;
  }
  if (not $north->{$_->{name}} and not $south->{$_->{name}}) {
    $Data->{eras}->{$_->{name}}->{jp_era} = 1;
  }
  $Data->{eras}->{$_->{name}}->{name} = $_->{name};
  $Data->{eras}->{$_->{name}}->{key} = $_->{name};
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
