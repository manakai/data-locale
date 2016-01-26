use strict;
use warnings;

my $last = 'null';
my $prev = undef;
while (<>) {
  if (/^[^\t]+\t([^\t]+)$/) {
    if ($last ne $1) {
      $last = $1;
      print $prev if defined $prev;
      print;
      $prev = undef;
    } else {
      $prev = $_;
    }
  }
}

## License: Public Domain.
