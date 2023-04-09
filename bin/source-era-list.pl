use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $In = {items => []};
for my $path (($RootPath->child ('src')->children (qr/^era-list-\w+\.txt$/))) {
  my $tag;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^tag\s+(\S.+\S)\s*$/) {
      $tag = $1;
    } elsif (/^(\w+)\s+([0-9]+)\s*$/) {
      push @{$In->{items}}, {
        name => $1,
        ad_year => $2,
        path => $path,
        tags => [$tag],
      };
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

my $LabelToEras = {};
{
  my $path = $RootPath->child ('local/calendar-era-labels-0.json');
  my $json = json_bytes2perl $path->slurp;
  for my $era (values %{$json->{eras}}) {
    for my $label (keys %{$era->{_SHORTHANDS}->{names}}) {
      push @{$LabelToEras->{$label} ||= []}, $era;
    }
  }
}

my $Data = {};

for my $item (@{$In->{items}}) {
  my $eras = $LabelToEras->{$item->{name}} || [];
  $eras = [grep {
    (defined $_->{offset} and $_->{offset} + 1 == $item->{ad_year});
  } @$eras] if defined $item->{ad_year};
  if (@$eras > 1) {
    push @{$Data->{_ERRORS} ||= []}, ["Multiple matching eras", map { [$_->{id}, $_->{key}] } @$eras];
  }
  if (@$eras == 0) {
    push @{$Data->{_ERRORS} ||= []}, ["Era not found", $item->{name}];
  }
  for my $era (@$eras) {
    $Data->{eras}->{$era->{id}}->{key} = $era->{key};
    $Data->{eras}->{$era->{id}}->{era_names}->{$item->{name}} = 1;
    for my $tag_key (@{$item->{tags}}) {
      $Data->{eras}->{$era->{id}}->{tag_keys}->{$tag_key} = 1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
