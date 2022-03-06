use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $Data = {};

my $RootPath = path (__FILE__)->parent->parent;

sub from_ss ($) {
  my $ss = shift;
  return join ' ', map {
    if (ref $_) {
      join '', @$_;
    } else {
      {
        '._' => ' ',
        ".'" => "'",
        '.-' => '-',
      }->{$_} // $_;
    }
  } @$ss
} # ss

my $EraKeyToEra = {};
my $EraNameToKey;
{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  {
    my $path = $RootPath->child ('local/calendar-era-labels-0.json');
    my $in_json = json_bytes2perl $path->slurp;
    for my $in_era (values %{$in_json->{eras}}) {
      $json->{eras}->{$in_era->{key}}->{label_sets} = $in_era->{label_sets};
    }
  }

  $EraNameToKey = $json->{name_to_key}->{jp};
  for my $era (sort { $a->{id} <=> $b->{id} } values %{$json->{eras}}) {
    $EraKeyToEra->{$era->{key}} = $era;
    my $values = [];
    for my $ls (@{$era->{label_sets}}) {
      for my $label (@{$ls->{labels}}) {
        next unless $label->{is_name};
        FG: for my $fg (@{$label->{form_groups}}) {
          if ($fg->{form_group_type} eq 'compound') {
            my $yomi = [];
            for my $item_fg (@{$fg->{items}}) {
              my $has_yomi = 0;
              for my $item_fs (@{$item_fg->{form_sets}}) {
                if ($item_fs->{form_set_type} eq 'yomi' or
                    $item_fs->{form_set_type} eq 'kana') {
                  if (defined $item_fs->{hiragana_modern}) {
                    $has_yomi = 1;
                    push @$yomi, from_ss $item_fs->{hiragana_modern};
                  }
                }
              }
              next FG unless $has_yomi;
            }
            push @$values, [6100, join ' ', @$yomi];
          } else {
            for my $fs (@{$fg->{form_sets}}) {
              if ($fs->{form_set_type} eq 'yomi') {
                if (defined $fs->{hiragana_modern}) {
                  push @$values, [6100, from_ss $fs->{hiragana_modern}];
                }
                if (defined $fs->{hiragana_classic}) {
                  push @$values, [6101, from_ss $fs->{hiragana_classic}];
                }
                for (@{$fs->{hiragana_others} or []}) {
                  push @$values, [6104, from_ss $_];
                }
                for (@{$fs->{hiragana_wrongs} or []}) {
                  push @$values, [6105, from_ss $_];
                }
                for (@{$fs->{han_others} or []}) {
                  push @$values, [6106, from_ss $_];
                }
                my $found = {};
                if (defined $fs->{latin_normal}) {
                  push @$values, [6102, from_ss $fs->{latin_normal}];
                  $found->{$values->[-1]->[1]} = 1;
                }
                if (defined $fs->{latin_macron}) {
                  push @$values, [6103, from_ss $fs->{latin_macron}];
                  $found->{$values->[-1]->[1]} = 1;
                }
                for (@{$fs->{latin_others} or []}) {
                  push @$values, [6104, from_ss $_];
                  $found->{$values->[-1]->[1]} = 1;
                }
                if (defined $fs->{latin}) {
                  my $v = from_ss $fs->{latin};
                  unshift @$values, [6104, $v] unless $found->{$v};
                }
                for (@{$fs->{latin_wrongs} or []}) {
                  push @$values, [6105, from_ss $_];
                }
              } elsif ($fs->{form_set_type} eq 'alphabetical') {
                if (defined $fs->{ja_latin_old}) {
                  push @$values, [6107, from_ss $fs->{ja_latin_old}];
                }
                for (@{$fs->{ja_latin_old_wrongs}}) {
                  push @$values, [6108, from_ss $_];
                }
              }
            } # $fs
          }
        }
      }
    } # $ls
    if (@$values) {
      $Data->{eras}->{$era->{id}}->{id} = $era->{id};
      $Data->{eras}->{$era->{id}}->{key} = $era->{key};
      $Data->{eras}->{$era->{id}}->{name} = $era->{name};
      $Data->{eras}->{$era->{id}}->{start_year} = $era->{start_year};
      for (@$values) {
        push @{$Data->{eras}->{$era->{id}}->{yomis}->{$_->[0]} ||= []},
            $_->[1];
      }
    }
  } # $era
}

{
  my $path = $RootPath->child ('local/era-yomi-list.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (sort { $a cmp $b } keys %{$json->{eras}}) {
    my $era = $EraKeyToEra->{$key};
    unless (defined $era) {
      my $key = $EraNameToKey->{$key};
      $era = $EraKeyToEra->{$key // ''};
    }
    die "Bad era key |$key|" unless defined $era;
    $Data->{eras}->{$era->{id}}->{id} = $era->{id};
    $Data->{eras}->{$era->{id}}->{key} = $era->{key};
    $Data->{eras}->{$era->{id}}->{name} = $era->{name};
    $Data->{eras}->{$era->{id}}->{start_year} = $era->{start_year};
    for my $source_id (sort { $a cmp $b } keys %{$json->{eras}->{$key}}) {
      next unless $source_id =~ /\A[1-9][0-9]*\z/;
      next if 6100 <= $source_id and $source_id <= 6109;
      my $yomis = $json->{eras}->{$key}->{$source_id};
      push @{$Data->{eras}->{$era->{id}}->{yomis}->{$source_id} ||= []},
          ref $yomis ? @$yomis : $yomis;
    }
  }
}

  sub to_hiragana ($) {
    use utf8;
    my $s = shift;
    $s =~ tr/アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォッャュョヮ/あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎ/;
    $s =~ s/’/'/;
    return $s;
  } # to_hiragana

  sub xx ($) { my $s = to_hiragana shift; $s =~ s/ //g; return lc $s }

for my $era (values %{$Data->{eras}}) {
  my $all = {};
  for (keys %{$era->{yomis}}) {
    next unless /^[0-9]+$/;
    $all->{$_} = 1 for map { xx $_ } @{$era->{yomis}->{$_}};
  }
  for (keys %{$era->{yomis}}) {
    next unless /^[0-9]+$/ and 6100 <= $_ and $_ <= 6109;
    delete $all->{$_} for map { xx $_ } @{$era->{yomis}->{$_}};
  }
  $era->{missing_yomis} = [sort { $a cmp $b } keys %$all];
}

{
  my $SourceIds = [map { ''.$_ }
    6100..6108,
    6001, 6002, 6011, 6012, 6013..6020, 6031..6037, 6040,
    6041..6046, 6047..6048, 6049..6050, 6051..6052, 6060,
    6062, 6063, 6068, 6069, 6071..6084, 6090..6091, 6099,
  ];
  $Data->{source_ids} = $SourceIds;
  for my $source_id (@$SourceIds) {
    $Data->{sources}->{$source_id}->{suikawiki_url} = q<https://wiki.suikawiki.org/n/%E5%85%83%E5%8F%B7%E4%B8%80%E8%A6%A7#anchor-> . $source_id;
  }
  $Data->{sources}->{$_}->{is_kana_old} = 1
      for qw(6012 6013 6014 6015 6016 6017 6018 6019 6020 6032
             6040 6068 6101 6104);
  $Data->{sources}->{$_}->{is_latin_old} = 1
      for qw(6107 6108);
  $Data->{sources}->{$_}->{is_wrong} = 1
      for qw(6035 6036 6105 6108);
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
