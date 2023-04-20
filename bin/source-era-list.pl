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
    } elsif (/^(\w+)\s+([0-9]+)(?:\s+([0-9]+)|)\s*$/) {
      push @{$In->{items}}, {
        name => $1,
        ad_year => $2,
        end_year => (defined $3 ? $2+$3-1 : undef),
        path => $path,
        tags => [$tag],
      };
    } elsif (/^(\w+),(\w+)\s+([0-9]+)(?:\s+([0-9]+)|)\s*$/) {
      push @{$In->{items}}, {
        name => $1,
        ad_year => $3,
        end_year => (defined $4 ? $3+$4-1 : undef),
        path => $path,
        tags => [$tag],
      }, {
        name => $2,
        ad_year => $3,
        end_year => (defined $4 ? $3+$4-1 : undef),
        path => $path,
        tags => [$tag],
      };
    } elsif (m{^p\./(\d+)/$}) {
      #
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

{
  my $path = $RootPath->child ('src/era-slist-viet2020.txt');
  my $mode = 'init';
  my $item;
  use utf8;
  my $tag1 = 'ベトナムの漢字年号について 2020 一覧';
  my $tag2 = 'ベトナムの漢字年号について 2021 一覧';
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^#/) {
      #
    } elsif ($mode eq 'init' and /^\*/) {
      $mode = 'init';
    } elsif ($mode eq 'init' and /^(\d+)(\*|)$/) {
      push @{$In->{items}}, $item = {tags => [$tag1, $tag2], path => $path};
      $item->{_ja_num} = 0+$1;
      $item->{_vi_num} = 0+$1;
      $item->{_conflict_cn} = 1 if $2;

      $mode = 'ja';
    } elsif ($mode eq 'init' and /^(\d+)(\*|)\s+(\d+)$/) {
      push @{$In->{items}}, $item = {tags => [], path => $path};
      $item->{_ja_num} = 0+$1;
      $item->{_vi_num} = 0+$3;
      $item->{_conflict_cn} = 1 if $2;
      $mode = 'ja';
    } elsif ($mode eq 'ja' and /^(\w+)$/) {
      $item->{name} = $1;
      $mode = 'han';
    } elsif ($mode eq 'han' and /^(\w+)$/) {
      $item->{han_names}->{$1} = 1;
      $mode = 'vi';
    } elsif ($mode eq 'vi' and /^(\p{Latin}+(?: \p{Latin}+)+)$/) {
      $item->{vi_names}->{$1} = 1;
      $mode = 'year';
    } elsif ($mode eq 'year' and /^(\d+)-$/) {
      $item->{ad_year} = 0+$1;
      my $item2 = {%$item};
      delete $item2->{_vi_num};
      delete $item2->{han_names};
      delete $item2->{vi_names};
      $item2->{tags} = [$tag1];
      push @{$In->{items}}, $item2;
      delete $item->{_ja_num};
      delete $item->{_conflict_cn};
      $item->{name} = [keys %{$item->{han_names}}]->[0];
      $item->{tags} = [$tag2];
      $mode = 'year2';
    } elsif ($mode eq 'year' and /^(\d+)-(\d+)(\*|)$/) {
      $item->{ad_year} = 0+$1;
      $item->{end_year} = 0+$2;
      $item->{_vi_modified} = 1 if $3;
      $mode = 'end';
    } elsif ($mode eq 'year2' and /^(\d+)-(\d+)(\*|)$/) {
      $item->{ad_year} = 0+$1;
      $item->{end_year} = 0+$2;
      $item->{_vi_modified} = 1 if $3;
      $mode = 'end';
    } elsif ($mode eq 'end' and /^$/) {
      $mode = 'init';
    } elsif (/^p\.([0-9]+)$/) {
      # [ja] page
    } elsif (/^page=([0-9]+)$/) {
      # [vi] PDF page
    } elsif (/\S/) {
      die "Bad line |$_| (mode: $mode)";
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
    push @{$Data->{_ERRORS} ||= []}, ["Era not found", $item->{name}, $item->{ad_year}];
  }
  for my $era (@$eras) {
    $Data->{eras}->{$era->{id}}->{key} = $era->{key};
    $Data->{eras}->{$era->{id}}->{era_names}->{$item->{name}} = 1;
    for my $tag_key (@{$item->{tags}}) {
      $Data->{eras}->{$era->{id}}->{tag_keys}->{$tag_key} = 1;
    }
    for (keys %{$item->{han_names} or {}}) {
      unless ($era->{_SHORTHANDS}->{names}->{$_}) {
        push @{$Data->{_ERRORS} ||= []}, ["Era name not found", $item->{name}, $_];
      }
    }
    X: for my $x (keys %{$item->{vi_names} or {}}) {
      if (defined $era->{_SHORTHANDS}->{name_vi} and
          $era->{_SHORTHANDS}->{name_vi} eq $x) {
        #
      } else {
        for my $ls (@{$era->{label_sets}}) {
          for my $label (@{$ls->{labels}}) {
            for my $fg (@{$label->{form_groups}}) {
              for my $fs (@{$fg->{form_sets}}) {
                if ($fs->{form_set_type} eq 'vietnamese') {
                  my $v = join '', map {
                    if (ref $_) {
                      join '', @$_;
                    } elsif ($_ eq '._') {
                      ' ';
                    } else {
                      $_;
                    }
                  } @{$fs->{vi}};
                  if ($v eq $x) {
                    next X;
                  }
                }
              }
            }
          }
        }
        
        push @{$Data->{_ERRORS} ||= []},
            ["Era name not found", $item->{name}, $x];
      }
    } # X
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
