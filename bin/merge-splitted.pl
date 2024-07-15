use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

for my $in_name (qw(
  tags
  tag-labels
  calendar/era-defs
  calendar/era-transitions
  calendar/era-labels
  calendar/era-relations
)) {
  my $in_path = $RootPath->child ("data/$in_name.json");
  my $json = json_bytes2perl $in_path->slurp;

  my $info = delete $json->{_parts};
  for my $i (1..$info->{max}) {
    my $p = $RootPath->child ("data/$in_name-$i.json");
    my $j = json_bytes2perl $p->slurp;
    for my $key (keys %$j) {
      if (ref $j->{$key} eq 'ARRAY') {
        push @{$json->{$key} ||= []}, @{$j->{$key}};
      } else {
        for my $k (keys %{$j->{$key}}) {
          $json->{$key}->{$k} = $j->{$key}->{$k};
        }
      }
    }
  }
  for my $i (0..$info->{extra_max}) {
    my $p = $RootPath->child ("data/$in_name-x$i.json");
    my $j = json_bytes2perl $p->slurp;
    for my $key (keys %$j) {
      $json->{$key} = $j->{$key};
    }
  }

  {
    my $in = $in_name;
    $in =~ s{/}{-}g;
    my $p = $RootPath->child ("local/merged/$in.json");
    $p->spew (perl2json_bytes $json);
    #$p->spew (perl2json_bytes_for_record $json);
  }
}

## License: Public Domain.
