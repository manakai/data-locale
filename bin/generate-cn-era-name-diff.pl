use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;
my $path = $root_path->child ('intermediate/wp-cn-eras.json');
my $json = json_bytes2perl $path->slurp;

my $variants = {};

for (@{$json->{eras}}) {
  my @t = split //, $_->{tw};
  my @c = split //, $_->{cn};
  for (0..$#t) {
    if ($t[$_] ne $c[$_]) {
      my @v = sort { $a cmp $b } $t[$_], $c[$_];
      $variants->{$v[0]}->{$v[1]} = 1;
    }
  }
}

binmode STDOUT, q{:encoding(utf-8)};
for (sort { $a cmp $b } keys %{$variants}) {
  print join ' ', $_, sort { $a cmp $b } keys %{$variants->{$_}};
  print "\n";
}
## License: Public Domain.
