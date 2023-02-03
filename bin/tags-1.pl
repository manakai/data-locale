use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $Data;
{
  my $path = $RootPath->child ('local/tags-0.json');
  $Data = json_bytes2perl $path->slurp;
}

{
  my $path = $RootPath->child ('local/tag-labels-0.json');
  my $json = json_bytes2perl $path->slurp;
  for my $tag_id (keys %{$json->{tags}}) {
    $Data->{tags}->{$tag_id}->{_SHORTHANDS} = $json->{tags}->{$tag_id}->{_SHORTHANDS};
    $Data->{tags}->{$tag_id}->{_SHORTHANDS_2} = $json->{tags}->{$tag_id}->{_SHORTHANDS_2};
  }
}

for my $data (values %{$Data->{tags}}) {
  for my $key (keys %{$data->{_SHORTHANDS} or {}}) {
    next if $key =~ /^_/;
    $data->{$key} = $data->{_SHORTHANDS}->{$key};
  }
  if (defined $data->{_SHORTHANDS_2}->{name}) {
    for (keys %{$data->{_SHORTHANDS_2}}) {
      my $x = $_;
      if ($x =~ s/^name/label/) {
        $data->{$x} = $data->{_SHORTHANDS_2}->{$_};
      }
    }
  } else {
    for (keys %{$data->{_SHORTHANDS}}) {
      my $x = $_;
      if ($x =~ s/^name/label/) {
        $data->{$x} = $data->{_SHORTHANDS}->{$_};
      }
    }
  }
  delete $data->{labels};
  delete $data->{label_kana};
  delete $data->{label_kanas};
  delete $data->{label_latn};
  
  for my $key (grep { /^_/ } keys %$data) {
    delete $data->{$key};
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
