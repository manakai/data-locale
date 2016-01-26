use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $cn_path = $root_path->child ('local/wp-cn-eras-cn.json');
my $tw_path = $root_path->child ('local/wp-cn-eras-tw.json');
my $cn = json_bytes2perl $cn_path->slurp;
my $tw = json_bytes2perl $tw_path->slurp;

my $Data = $tw;

for (0..$#{$Data->{eras}}) {
  my $t = $Data->{eras}->[$_];
  my $c = $cn->{eras}->[$_];
  die if defined $t->{wref} and defined $c->{wref} and not $t->{wref} eq $c->{wref};
  die if defined $t->{offset} and defined $c->{offset} and not $t->{offset} == $c->{offset};
  $t->{name_cn} = $c->{name};
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
