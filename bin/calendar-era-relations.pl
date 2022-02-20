use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $Data = {};
my $RootPath = path (__FILE__)->parent->parent;

my $Eras;
my $EraById = {};
my $CharsEras = {};
my $YomisEras = {};
my $KrsEras = {};
my $AlphasEras = {};

{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  $Eras = [sort { $a->{id} <=> $b->{id} } values %{$json->{eras}}];
  for my $era (@$Eras) {
    $EraById->{$era->{id}} = $era;
  }
}
my $Transitions;
{
  my $path = $RootPath->child ('data/calendar/era-transitions.json');
  my $json = json_bytes2perl $path->slurp;
  $Transitions = $json->{transitions};
}

sub read_form_set ($$$) {
  my ($era, $fs, $offsets) = @_;
  my $new_offsets = {};
  if ($fs->{form_set_type} eq 'hanzi') {
    for (
      grep { defined }
      $fs->{cn}, $fs->{cn_complex},
      $fs->{hk},
      $fs->{tw},
      $fs->{jp}, $fs->{jp_new}, $fs->{jp_old}, $fs->{jp_h22},
      $fs->{kr},
      @{$fs->{others} or []},
    ) {
      my $w = [grep { not /^\./ } @$_];
      for my $i (0..$#$w) {
        my $x = ref $w->[$i] ? (join '', @{$w->[$i]}) : $w->[$i];
        for my $offset (keys %$offsets) {
          $CharsEras->{$x}->{$era->{id}}->{$offset + $i}->{''} = $era->{key};
        }
      }
      for my $offset (keys %$offsets) {
        $new_offsets->{$offset + @$w} = 1;
      }
    }
  } elsif ($fs->{form_set_type} eq 'yomi' or
           $fs->{form_set_type} eq 'kana') {
    for (
      grep { defined }
      $fs->{hiragana}, $fs->{hiragana_modern},
      $fs->{hiragana_classic}, @{$fs->{hiragana_others} or []},
      $fs->{katakana}, $fs->{katakana_modern},
      $fs->{katakana_classic}, @{$fs->{katakana_others} or []},
      $fs->{kana}, $fs->{kana_modern},
      $fs->{kana_classic}, @{$fs->{kana_others} or []},
    ) {
      my $w = [grep { not /^\./ } @$_];
      for my $i (0..$#$w) {
        my $x = ref $w->[$i] ? (join '', @{$w->[$i]}) : $w->[$i];
        for my $offset (keys %$offsets) {
          $YomisEras->{$x}->{$era->{id}}->{$offset + $i}->{''} = $era->{key};
        }
      }
      for my $offset (keys %$offsets) {
        $new_offsets->{$offset + @$w} = 1;
      }
    }
  } elsif ($fs->{form_set_type} eq 'korean') {
    for (
      grep { defined }
      $fs->{kr},
    ) {
      my $w = [grep { not /^\./ } @$_];
      for my $i (0..$#$w) {
        my $x = ref $w->[$i] ? (join '', @{$w->[$i]}) : $w->[$i];
        for my $offset (keys %$offsets) {
          $KrsEras->{$x}->{$era->{id}}->{$offset + $i}->{''} = $era->{key};
        }
      }
      for my $offset (keys %$offsets) {
        $new_offsets->{$offset + @$w} = 1;
      }
    }
  } elsif ($fs->{form_set_type} eq 'alphabetical') {
    for (
      grep { defined }
      $fs->{en}, $fs->{en_la},
      $fs->{la}, $fs->{es}, $fs->{po}, $fs->{fr},
      $fs->{vi},
      $fs->{ja_latin},
      @{$fs->{others} or []},
    ) {
      my $w = [map {
        my $x = $_;
        lc $x;
      } grep { not /^\./ } @$_];
      for my $i (0..$#$w) {
        my $x = ref $w->[$i] ? (join '', @{$w->[$i]}) : $w->[$i];
        for my $offset (keys %$offsets) {
          $AlphasEras->{$x}->{$era->{id}}->{$offset + $i}->{''} = $era->{key};
        }
      }
      for my $offset (keys %$offsets) {
        $new_offsets->{$offset + @$w} = 1;
      }
    }
  } elsif ($fs->{form_set_type} eq 'symbols') {
    %$new_offsets = %$offsets;
  }
  %$offsets = %$new_offsets;
} # read_form_set

sub match_form_set ($$$) {
  my ($era, $fs, $code) = @_;
  if ($fs->{form_set_type} eq 'hanzi') {
    for (
      grep { defined }
      $fs->{cn}, $fs->{cn_complex},
      $fs->{hk},
      $fs->{tw},
      $fs->{jp}, $fs->{jp_new}, $fs->{jp_old}, $fs->{jp_h22},
      $fs->{kr},
      @{$fs->{others} or []},
    ) {
      my $w = [grep { not /^\./ } @$_];
      my $ids = undef;
      for my $i (0..$#$w) {
        my $x = ref $w->[$i] ? (join '', @{$w->[$i]}) : $w->[$i];
        if (not defined $ids) {
          $ids = {map {
            my $id = $_;
            $id => [[map {
              [$_];
            } sort { $a <=> $b } keys %{$CharsEras->{$x}->{$id}}]];
          } keys %{$CharsEras->{$x}}};
          delete $ids->{$era->{id}};
        } else {
          $ids = {map {
            my $id = $_;
            $id => [@{$ids->{$id}}, [map {
              [$_];
            } sort { $a <=> $b } keys %{$CharsEras->{$x}->{$id}}]];
          } grep { $ids->{$_} } keys %{$CharsEras->{$x}}};
        }
        last unless keys %$ids;
      }
      for (keys %$ids) {
        my $match = $ids->{$_};
        $Data->{eras}->{$era->{id}}->{relateds}->{$_}->{_matches}->{join ';', map { join ',', map { join '-', @$_ } @$_ } @$match} = 1;
        $code->($era->{id}, $_, 'name_similar', 'name_similar');
        if (do {
          my $matched = 0;
          FIRST: for my $first (@{$match->[0]}) {
            $matched = 1;
            for my $i (1..$#$match) {
              if (grep { $_->[0] == $first->[0] + $i } @{$match->[$i]}) {
                #
              } else {
                $matched = 0;
                next FIRST;
              }
            }
            last FIRST if $matched;
          } # FIRST
          $matched;
        }) {
          $code->($era->{id}, $_, 'name_contained', 'name_contains');
        } elsif (do {
          my $matched = 0;
          FIRST: for my $first (@{$match->[0]}) {
            $matched = 1;
            for my $i (1..$#$match) {
              if (grep { $_->[0] == $first->[0] - $i } @{$match->[$i]}) {
                #
              } else {
                $matched = 0;
                next FIRST;
              }
            }
            last FIRST if $matched;
          } # FIRST
          $matched;
        }) {
          $code->($era->{id}, $_, 'name_rev_contained', 'name_rev_contains');
        }
      }
    }
  } elsif ($fs->{form_set_type} eq 'yomi' or
           $fs->{form_set_type} eq 'kana') {
    for (
      grep { defined }
      $fs->{hiragana}, $fs->{hiragana_modern},
      $fs->{hiragana_classic}, @{$fs->{hiragana_others} or []},
      $fs->{katakana}, $fs->{katakana_modern},
      $fs->{katakana_classic}, @{$fs->{katakana_others} or []},
      $fs->{kana}, $fs->{kana_modern},
      $fs->{kana_classic}, @{$fs->{kana_others} or []},
    ) {
      my $w = [grep { not /^\./ } @$_];
      my $ids = undef;
      for my $i (0..$#$w) {
        my $x = ref $w->[$i] ? (join '', @{$w->[$i]}) : $w->[$i];
        if (not defined $ids) {
          $ids = {map {
            my $id = $_;
            $id => [[map {
              [$_];
            } sort { $a <=> $b } keys %{$YomisEras->{$x}->{$id}}]];
          } keys %{$YomisEras->{$x}}};
          delete $ids->{$era->{id}};
        } else {
          $ids = {map {
            my $id = $_;
            $id => [@{$ids->{$id}}, [map {
              [$_];
            } sort { $a <=> $b } keys %{$YomisEras->{$x}->{$id}}]];
          } grep { $ids->{$_} } keys %{$YomisEras->{$x}}};
        }
        last unless keys %$ids;
      }
      for (keys %$ids) {
        my $match = $ids->{$_};
        #$Data->{eras}->{$era->{id}}->{relateds}->{$_}->{_matches}->{join ';', map { join ',', map { join '-', @$_ } @$_ } @$match} = 1;
        if (do {
          my $matched = 0;
          FIRST: for my $first (@{$match->[0]}) {
            $matched = 1;
            for my $i (1..$#$match) {
              if (grep { $_->[0] == $first->[0] + $i } @{$match->[$i]}) {
                #
              } else {
                $matched = 0;
                next FIRST;
              }
            }
            last FIRST if $matched;
          } # FIRST
          $matched;
        }) {
          $code->($era->{id}, $_, 'yomi_contained', 'yomi_contains');
        }
      }
    }
  } elsif ($fs->{form_set_type} eq 'korean') {
    for (
      grep { defined }
      $fs->{kr},
    ) {
      my $w = [grep { not /^\./ } @$_];
      my $ids = undef;
      for my $i (0..$#$w) {
        my $x = ref $w->[$i] ? (join '', @{$w->[$i]}) : $w->[$i];
        if (not defined $ids) {
          $ids = {map {
            my $id = $_;
            $id => [[map {
              [$_];
            } sort { $a <=> $b } keys %{$KrsEras->{$x}->{$id}}]];
          } keys %{$KrsEras->{$x}}};
          delete $ids->{$era->{id}};
        } else {
          $ids = {map {
            my $id = $_;
            $id => [@{$ids->{$id}}, [map {
              [$_];
            } sort { $a <=> $b } keys %{$KrsEras->{$x}->{$id}}]];
          } grep { $ids->{$_} } keys %{$KrsEras->{$x}}};
        }
        last unless keys %$ids;
      }
      for (keys %$ids) {
        my $match = $ids->{$_};
        #$Data->{eras}->{$era->{id}}->{relateds}->{$_}->{_matches}->{join ';', map { join ',', map { join '-', @$_ } @$_ } @$match} = 1;
        if (do {
          my $matched = 0;
          FIRST: for my $first (@{$match->[0]}) {
            $matched = 1;
            for my $i (1..$#$match) {
              if (grep { $_->[0] == $first->[0] + $i } @{$match->[$i]}) {
                #
              } else {
                $matched = 0;
                next FIRST;
              }
            }
            last FIRST if $matched;
          } # FIRST
          $matched;
        }) {
          $code->($era->{id}, $_, 'korean_contained', 'korean_contains');
        }
      }
    }
  } elsif ($fs->{form_set_type} eq 'alphabetical') {
    for (
      grep { defined }
      $fs->{en}, $fs->{en_la},
      $fs->{la}, $fs->{es}, $fs->{po}, $fs->{fr},
      $fs->{vi},
      $fs->{ja_latin},
      @{$fs->{others} or []},
    ) {
      my $w = [map {
        my $x = $_;
        lc $x;
      } grep { not /^\./ } @$_];
      my $ids = undef;
      for my $i (0..$#$w) {
        my $x = ref $w->[$i] ? (join '', @{$w->[$i]}) : $w->[$i];
        if (not defined $ids) {
          $ids = {map {
            my $id = $_;
            $id => [[map {
              [$_];
            } sort { $a <=> $b } keys %{$AlphasEras->{$x}->{$id}}]];
          } keys %{$AlphasEras->{$x}}};
          delete $ids->{$era->{id}};
        } else {
          $ids = {map {
            my $id = $_;
            $id => [@{$ids->{$id}}, [map {
              [$_];
            } sort { $a <=> $b } keys %{$AlphasEras->{$x}->{$id}}]];
          } grep { $ids->{$_} } keys %{$AlphasEras->{$x}}};
        }
        last unless keys %$ids;
      }
      for (keys %$ids) {
        my $match = $ids->{$_};
        #$Data->{eras}->{$era->{id}}->{relateds}->{$_}->{_matches}->{join ';', map { join ',', map { join '-', @$_ } @$_ } @$match} = 1;
        if (do {
          my $matched = 0;
          FIRST: for my $first (@{$match->[0]}) {
            $matched = 1;
            for my $i (1..$#$match) {
              if (grep { $_->[0] == $first->[0] + $i } @{$match->[$i]}) {
                #
              } else {
                $matched = 0;
                next FIRST;
              }
            }
            last FIRST if $matched;
          } # FIRST
          $matched;
        }) {
          $code->($era->{id}, $_, 'alphabetical_contained', 'alphabetical_contains');
        }
      }
    }
  } elsif ($fs->{form_set_type} eq 'symbols') {
    #
  } # form_set_type
} # match_form_set

for my $era (@$Eras) {
  for my $ls (@{$era->{label_sets}}) {
    for my $label (@{$ls->{labels}}) {
      for my $fg (@{$label->{form_groups}}) {
        if ($fg->{form_group_type} eq 'han' or
            $fg->{form_group_type} eq 'kana' or
            $fg->{form_group_type} eq 'ja') {
          for my $fs (@{$fg->{form_sets}}) {
            read_form_set $era, $fs, {0 => 1};
          }
        } elsif ($fg->{form_group_type} eq 'alphabetical') {
          for my $fs (@{$fg->{form_sets}}) {
            read_form_set $era, $fs, {0 => 1};
          }
        } elsif ($fg->{form_group_type} eq 'symbols') {
          #
        } elsif ($fg->{form_group_type} eq 'compound') {
          my $offsets = {0 => 1};
          for my $cfg (@{$fg->{items}}) {
            my $offsetses = [];
            if ($cfg->{form_group_type} eq 'han' or
                $cfg->{form_group_type} eq 'kana' or
                $cfg->{form_group_type} eq 'ja') {
              for my $cfs (@{$cfg->{form_sets}}) {
                my $q_offsets = {%$offsets};
                read_form_set $era, $cfs, $q_offsets;
                push @$offsetses, $q_offsets;
              }
            } elsif ($cfg->{form_group_type} eq 'alphabetical') {
              for my $cfs (@{$cfg->{form_sets}}) {
                my $q_offsets = {%$offsets};
                read_form_set $era, $cfs, $q_offsets;
                push @$offsetses, $q_offsets;
              }
            } elsif ($cfg->{form_group_type} eq 'symbols') {
              $offsetses = [$offsets];
            }
            $offsets = {map { %$_ } @$offsetses};
          }
        }
      } # $fg
    }
  }
} # $era

my $matched = sub {
  my ($fg_abbr) = @_;
  return sub {
    my ($id1, $id2, $type1, $type2) = @_;
    if ($type1 eq 'name_contained' or $type1 eq 'alphabetical_contained') {
      if ($fg_abbr) {
        $Data->{eras}->{$id1}->{relateds}->{$id2}->{abbr_contained} = 1;
        $Data->{eras}->{$id2}->{relateds}->{$id1}->{abbr_contains} = 1;
      } else {
        $Data->{eras}->{$id1}->{relateds}->{$id2}->{$type1} = 1;
        $Data->{eras}->{$id2}->{relateds}->{$id1}->{$type2} = 1;
      }
    } else {
      $Data->{eras}->{$id1}->{relateds}->{$id2}->{$type1} = 1;
      $Data->{eras}->{$id2}->{relateds}->{$id1}->{$type2} = 1;
    }
  };
}; # $matched
for my $era (@$Eras) {
  for my $ls (@{$era->{label_sets}}) {
    for my $label (@{$ls->{labels}}) {
      for my $fg (@{$label->{form_groups}}) {
        my $fg_abbr = defined $fg->{abbr};
        if ($fg->{form_group_type} eq 'han' or
            $fg->{form_group_type} eq 'kana' or
            $fg->{form_group_type} eq 'ja') {
          for my $fs (@{$fg->{form_sets}}) {
            match_form_set $era, $fs, $matched->($fg_abbr, ! 'partial');
          }
        } elsif ($fg->{form_group_type} eq 'alphabetical') {
          for my $fs (@{$fg->{form_sets}}) {
            match_form_set $era, $fs, $matched->($fg_abbr, ! 'partial');
          } # $fs
        } elsif ($fg->{form_group_type} eq 'symbols') {
          #
        } elsif ($fg->{form_group_type} eq 'compound') {
          for my $cfg (@{$fg->{items}}) {
            if ($cfg->{form_group_type} eq 'han' or
                $cfg->{form_group_type} eq 'kana' or
                $cfg->{form_group_type} eq 'ja') {
              for my $cfs (@{$cfg->{form_sets}}) {
                #
              }
            } elsif ($cfg->{form_group_type} eq 'alphabetical') {
              for my $cfs (@{$cfg->{form_sets}}) {
                #
              }
            } elsif ($cfg->{form_group_type} eq 'symbols') {
              #
            }
          }
        }
      } # $fg
    }
  }
} # $era

for my $id (keys %{$Data->{eras}}) {
  my $rels = $Data->{eras}->{$id}->{relateds} || {};
  for my $id2 (keys %$rels) {
    if ($rels->{$id2}->{name_contains} and $rels->{$id2}->{name_contained}) {
      $rels->{$id2}->{name_equal} = 1;
    }
    if ($rels->{$id2}->{name_rev_contains} and $rels->{$id2}->{name_rev_contained}) {
      $rels->{$id2}->{name_reversed} = 1;
    }
    if ($rels->{$id2}->{abbr_contains} and $rels->{$id2}->{abbr_contained}) {
      $rels->{$id2}->{abbr_equal} = 1;
    }
    if ($rels->{$id2}->{yomi_contains} and $rels->{$id2}->{yomi_contained}) {
      $rels->{$id2}->{yomi_equal} = 1;
    }
    if ($rels->{$id2}->{korean_contains} and $rels->{$id2}->{korean_contained}) {
      $rels->{$id2}->{korean_equal} = 1;
    }
    if ($rels->{$id2}->{alphabetical_contains} and $rels->{$id2}->{alphabetical_contained}) {
      $rels->{$id2}->{alphabetical_equal} = 1;
    }
  }
}

{
  my $offset_eras = {};
  my $year_era_ids = {};
  my $ThisYear = [gmtime]->[5]+1900;
  for my $era (values %$EraById) {
    if (defined $era->{offset}) {
      push @{$offset_eras->{$era->{offset}} ||= []}, $era;
    }
    if (defined $era->{start_year}) {
      my $end = $era->{end_year} // ($ThisYear + 10);
      for my $y ($era->{start_year} .. $end) {
        push @{$year_era_ids->{$y} ||= []}, $era->{id};
      }
    }
  } # $era
  for my $offset (sort { $a <=> $b } keys %$offset_eras) {
    my @era = @{$offset_eras->{$offset}};
    for my $era1 (@era) {
      for my $era2 (@era) {
        next if $era1->{id} == $era2->{id};
        $Data->{eras}->{$era1->{id}}->{relateds}->{$era2->{id}}->{year_equal} = 1;
        $Data->{eras}->{$era2->{id}}->{relateds}->{$era1->{id}}->{year_equal} = 1;
      }
    }
  } # $offset
  for my $era (values %$EraById) {
    if (defined $era->{start_year}) {
      my $end = $era->{end_year} // ($ThisYear + 10);
      for my $y ($era->{start_year} .. $end) {
        for my $id2 (@{$year_era_ids->{$y} || []}) {
          next if $era->{id} == $id2;
          $Data->{eras}->{$era->{id}}->{relateds}->{$id2}->{year_range_overlap} = 1;
        }
      }
    }
  } # $era
}

{
  my $to_canon = {};
  for my $tr (@$Transitions) {
    for my $id1 (sort { $a <=> $b } keys %{$tr->{prev_era_ids}}) {
      for my $id2 (sort { $a <=> $b } keys %{$tr->{next_era_ids}}) {
        next if $id1 == $id2;
        $Data->{eras}->{$id1}->{relateds}->{$id2}->{transition_next} = 1;
        $Data->{eras}->{$id2}->{relateds}->{$id1}->{transition_prev} = 1;
        if ($tr->{tag_ids}->{2867} or # 異説発生
            $tr->{tag_ids}->{2878}) { # 避諱改名
          $Data->{eras}->{$id1}->{relateds}->{$id2}->{cognate_deviates} = 1;
          $Data->{eras}->{$id2}->{relateds}->{$id1}->{cognate_deviated} = 1;
          $to_canon->{$id2} = $id1;
        }
        if ($tr->{tag_ids}->{2877}) { # 元号名再利用
          $Data->{eras}->{$id1}->{relateds}->{$id2}->{name_reused} = 1;
          $Data->{eras}->{$id2}->{relateds}->{$id1}->{name_reuses} = 1;
        }
      }
    }
  } # $tr
  my $loop = 0;
  {
    my $changed = 0;
    my $new_to_canon = {};
    for my $id1 (sort { $a <=> $b } keys %$to_canon) {
      if (defined $to_canon->{$to_canon->{$id1}}) {
        $new_to_canon->{$id1} = $to_canon->{$to_canon->{$id1}};
      } else {
        $new_to_canon->{$id1} = $to_canon->{$id1};
      }
    }
    $to_canon = $new_to_canon;
    die "Too many iterations" if $loop++ > 10;
    redo if $changed;
  }
  for my $id1 (keys %$to_canon) {
    my $id2 = $to_canon->{$id1};
    $Data->{eras}->{$id1}->{relateds}->{$id2}->{cognate_canon} = 1;
  }
}

## For devs
for my $id (keys %{$Data->{eras}}) {
  my $era = $EraById->{$id};
  $Data->{eras}->{$id}->{_key} = $era->{key};
  for (keys %{$Data->{eras}->{$id}->{relateds} || {}}) {
    $Data->{eras}->{$id}->{relateds}->{$_}->{_key} = $EraById->{$_}->{key};
  }
}
$Data->{_CharsEras} = $CharsEras;
#$Data->{_YomisEras} = $YomisEras;
#$Data->{_KrsEras} = $KrsEras;
#$Data->{_AlphasEras} = $AlphasEras;

print perl2json_bytes_for_record $Data;

## License: Public Domain.
