use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Langs = [qw(cn hk mo my sg tw)];

my $Inputs = {};
for my $lang (@$Langs) {
  my $path = $RootPath->child ("local/wp-cn-eras-$lang.json");
  $Inputs->{$lang} = json_bytes2perl $path->slurp;
}

my $Data = $Inputs->{tw};

for my $i (0..$#{$Data->{eras}}) {
  for my $lang (@$Langs) {
    my $c = $Inputs->{$lang}->{eras}->[$i];
    my $t = $Data->{eras}->[$i];
    die if defined $t->{wref} and defined $c->{wref} and not $t->{wref} eq $c->{wref};
    die if defined $t->{offset} and defined $c->{offset} and not $t->{offset} == $c->{offset};
    $t->{$lang} = $c->{name};
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
