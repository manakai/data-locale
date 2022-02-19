use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

my $Chars;
{
  my $path = $RootPath->child ('data/calendar/era-stats.json');
  my $json = json_bytes2perl $path->slurp;
  $Chars = $json->{han_chars}->{all};
}

{
  my $Leaders = {};
  my $LeaderKeys = [];
  
  my $rpath = $RootPath->child ("local/cluster-root.json");
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

    if ($Chars->{$r->{all}} and not $r->{all} eq $json->[0]) {
      $Data->{normalize}->{$json->[0]} = $r->{all};
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
