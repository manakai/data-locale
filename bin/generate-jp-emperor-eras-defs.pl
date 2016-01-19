use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $Data = {};

my $src_path = $root_path->child ('src/jp-emperor-eras.txt');
for (split /\x0D?\x0A/, $src_path->slurp_utf8) {
  if (/^(BC|)(\d+)\s+(\w+)$/) {
    $Data->{eras}->{$3}->{key} = $3;
    $Data->{eras}->{$3}->{name} = $3;
    $Data->{eras}->{$3}->{offset} = ($1 ? -$2 + 1 : $2) - 1;
    $Data->{eras}->{$3}->{jp_emperor_era} = 1
        unless $3 eq '弘文天皇';
  } elsif (/\S/) {
    die "Bad line |$_|";
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
