use strict;
use warnings;
use utf8;
use JSON::PS;
use Path::Tiny;

my $root_path = path (__FILE__)->parent->parent;

my $json_path = $root_path->child ('src/wp-jp-eras.json');
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
  my $data = $Data->{eras}->{$_->{name}} ||= {};
  $data->{offset} = $first_year - 1;
  if ($south->{$_->{name}}) {
    $data->{jp_south_era} = 1;
  }
  if ($north->{$_->{name}}) {
    $data->{jp_north_era} = 1;
  }
  if (not $north->{$_->{name}} and not $south->{$_->{name}}) {
    $data->{jp_era} = 1;
  }
  $data->{name} = $_->{name};
  $data->{name_ja} = $_->{name};
  $data->{key} = $_->{name};
  for my $key (qw(wref_ja)) { # name_kana name_kanas
    if (defined $_->{$key}) {
      $data->{$key} = $_->{$key};
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
