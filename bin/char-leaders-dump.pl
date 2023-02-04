use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Storable;

my $RootPath = path (__FILE__)->parent->parent;

my $LeaderKeys = [];
my $Leaders = {};

{
  my $rpath = $RootPath->child ("local/merged-index.json");
  my $root = json_bytes2perl $rpath->slurp;
  my $x = [];
  $x->[0] = 'all';
  for (values %{$root->{leader_types}}) {
    $x->[$_->{index}] = $_->{key};
    push @$LeaderKeys, $_->{key};
  }
  
  my $path = $RootPath->child ("local/char-leaders.jsonl");
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    my $json = json_bytes2perl $_;
    my $r = {};
    for (0..$#$x) {
      $r->{$x->[$_]} = $json->[1]->[$_]; # or undef
    }
    $Leaders->{$json->[0]} = $r;
  }
}

{
  my $path = $RootPath->child ('local/char-leaders.dat');
  store [$LeaderKeys, $Leaders], $path;
}

## License: Public Domain.
