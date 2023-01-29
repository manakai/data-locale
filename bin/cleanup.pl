use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $path = path (shift);
my $data = json_bytes2perl $path->slurp;

sub cleanup ($);
sub cleanup ($) {
  my $data = shift;
  for (grep { /^_/ } keys %$data) {
    delete $data->{$_};
  }
  for my $key (qw(eras relateds tags)) {
    next unless defined $data->{$key};
    for (values %{$data->{$key}}) {
      cleanup $_;
    }
  } # $key
}

cleanup $data;

print perl2json_bytes_for_record $data;

## License: Public Domain.
