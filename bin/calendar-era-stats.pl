use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Storable;

my $RootPath = path (__FILE__)->parent->parent;

my $Data = {};


my $LeaderKeys = [];
my $Leaders = {};
{
  print STDERR "Load leaders...";
  my $path = $RootPath->child ('local/char-leaders.dat');
  ($LeaderKeys, $Leaders) = @{retrieve $path};
  print STDERR "done!\n";
}

sub process_han ($) {
  my $fs = shift;

  my $ss = $fs->{others}->[0];
  for my $key (@$LeaderKeys) {
    last if defined $ss;
    $ss = $fs->{$key};
  }
  return if not defined $ss;

  for (@$ss) {
    if (ref $_) {
      for my $c (@$_) {
        my $cc = $Leaders->{$c}->{all} // $c;
        $Data->{han_chars}->{all}->{$cc} = 1;
      }
    } elsif (/^\./) {
      #
    } else {
      my $cc = $Leaders->{$_}->{all} // $_;
      $Data->{han_chars}->{all}->{$cc} = 1;
    }
  }

} # process_han

{
  my $path = $RootPath->child ('local/view/calendar-era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  {
    my $path = $RootPath->child ('local/calendar-era-labels-0.json');
    my $in_json = json_bytes2perl $path->slurp;
    for my $in_era (values %{$in_json->{eras}}) {
      $json->{eras}->{$in_era->{key}}->{label_sets} = $in_era->{label_sets};
    }
  }

  for my $era (sort { $a->{id} <=> $b->{id} } values %{$json->{eras}}) {
    for my $ls (@{$era->{label_sets}}) {
      for my $label (@{$ls->{labels}}) {
        next unless $label->{props}->{is_name};
        FG: for my $fg (@{$label->{form_groups}}) {
          if ($fg->{form_group_type} eq 'compound') {
            for my $item_fg (@{$fg->{items}}) {
              for my $item_fs (@{$item_fg->{form_sets}}) {
                if ($item_fs->{form_set_type} eq 'hanzi') {
                  process_han $item_fs;
                }
              }
            }
          } else {
            for my $fs (@{$fg->{form_sets}}) {
              if ($fs->{form_set_type} eq 'hanzi') {
                process_han $fs;
              }
            } # $fs
          }
        }
      }
    } # $ls

    $Data->{eras}->{all}++;
    $Data->{eras}->{no_offset}++ if not defined $era->{offset};
    $Data->{eras}->{no_start_year}++ if not defined $era->{start_year};
    $Data->{eras}->{no_tag}++ if not keys %{$era->{tag_ids} or {}};
    warn $era->{key} if not keys %{$era->{tag_ids} or {}};
  } # $era
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
