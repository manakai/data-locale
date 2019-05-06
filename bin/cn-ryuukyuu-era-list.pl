use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

{
  my $path = $RootPath->child ('src/eras/ryuukyuu.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^rk:\S+\s+(\S+)$/) {
      $Data->{eras}->{$1}->{cn_ryuukyuu_era} = 1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
