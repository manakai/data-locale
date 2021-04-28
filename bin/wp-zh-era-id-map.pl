use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

binmode STDOUT, qw(:utf8);

my $RootPath = path (__FILE__)->parent->parent;

my $Data = json_bytes2perl $RootPath->child ('data/calendar/era-defs.json')->slurp;

my $Result = [];
for my $data (values %{$Data->{eras}}) {
  if (defined $data->{wref_zh} and defined $data->{name_tw}) {
    my $ukey = $data->{name_tw};
    if (defined $data->{offset}) {
      $ukey .= ',' . $data->{offset};
    }
    push @$Result, $ukey . ' ' . $data->{id} . ' ' . $data->{key} . "\n";
  }
}

print join '', sort { $a cmp $b } @$Result;

## License: Public Domain.
