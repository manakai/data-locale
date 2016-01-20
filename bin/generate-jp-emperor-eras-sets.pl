use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
binmode STDOUT, q(:encoding(utf-8));

my $root_path = path (__FILE__)->parent->parent;

my $Output = qq{\$jp-pre-645:\n};

my $src_path = $root_path->child ('src/jp-emperor-eras.txt');
for (split /\x0D?\x0A/, $src_path->slurp_utf8) {
  if (/^(BC|)(\d+)\s+(\w+)\s+(\w+)\s+([\w-]+)$/) {
    my $y = $1 ? -$2 + 1 : $2;
    next unless $y < 645;
    $Output .= qq{y:$y $3\n};
  } elsif (/\S/) {
    die "Bad line |$_|";
  }
}

print $Output;

## License: Public Domain.
