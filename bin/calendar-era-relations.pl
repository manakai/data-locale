use strict;
use warnings;
use utf8;
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

print STDERR "Loading...";
{
  my $path = $RootPath->child ('local/calendar-era-defs-0.json');
  my $json = json_bytes2perl $path->slurp;
  $Eras = [sort { $a->{id} <=> $b->{id} } values %{$json->{eras}}];
  for my $era (@$Eras) {
    $EraById->{$era->{id}} = $era;
  }
}
{
  my $path = $RootPath->child ('local/calendar-era-labels-0.json');
  my $json = json_bytes2perl $path->slurp;
  for my $in_era (values %{$json->{eras}}) {
    $EraById->{$in_era->{id}}->{label_sets} = $in_era->{label_sets};
  }
}
my $Transitions;
{
  my $path = $RootPath->child ('data/calendar/era-transitions.json');
  my $json = json_bytes2perl $path->slurp;
  $Transitions = $json->{transitions};
}
print STDERR "done\n";

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
  } elsif ($fs->{form_set_type} eq 'alphabetical' or
           $fs->{form_set_type} eq 'vietnamese') {
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
  } elsif ($fs->{form_set_type} eq 'alphabetical' or
           $fs->{form_set_type} eq 'vietnamese' or
           $fs->{form_set_type} eq 'chinese') {
    for (
      grep { defined }
      $fs->{en_lower}, $fs->{en_la_roman_lower},
      $fs->{la_lower}, $fs->{es_lower}, $fs->{po_lower}, $fs->{fr_lower},
      $fs->{vi_lower},
      $fs->{pinyin_lower}, $fs->{nan_poj_lower},
      $fs->{ja_latin_lower},
      @{$fs->{lower_others} or []},
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

print STDERR "\rStep 1... ";
for my $era (@$Eras) {
  for my $ls (@{$era->{label_sets}}) {
    for my $label (@{$ls->{labels}}) {
      for my $fg (@{$label->{form_groups}}) {
        if ($fg->{form_group_type} eq 'han' or
            $fg->{form_group_type} eq 'kana' or
            $fg->{form_group_type} eq 'ja' or
            $fg->{form_group_type} eq 'vi') {
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
                $cfg->{form_group_type} eq 'ja' or
                $cfg->{form_group_type} eq 'vi') {
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
  my ($is_abbr) = @_;
  return sub {
    my ($id1, $id2, $type1, $type2) = @_;
    if ($type1 eq 'name_contained' or $type1 eq 'alphabetical_contained') {
      if ($is_abbr) {
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
print STDERR "\rStep 2... ";
for my $era (@$Eras) {
  for my $ls (@{$era->{label_sets}}) {
    for my $label (@{$ls->{labels}}) {
      my $label_abbr = defined $label->{abbr};
      for my $fg (@{$label->{form_groups}}) {
        if ($fg->{form_group_type} eq 'han' or
            $fg->{form_group_type} eq 'kana' or
            $fg->{form_group_type} eq 'ja' or
            $fg->{form_group_type} eq 'vi') {
          for my $fs (@{$fg->{form_sets}}) {
            match_form_set $era, $fs, $matched->($label_abbr, ! 'partial');
          }
        } elsif ($fg->{form_group_type} eq 'alphabetical') {
          for my $fs (@{$fg->{form_sets}}) {
            match_form_set $era, $fs, $matched->($label_abbr, ! 'partial');
          } # $fs
        } elsif ($fg->{form_group_type} eq 'symbols') {
          #
        } elsif ($fg->{form_group_type} eq 'compound') {
          for my $cfg (@{$fg->{items}}) {
            if ($cfg->{form_group_type} eq 'han' or
                $cfg->{form_group_type} eq 'kana' or
                $cfg->{form_group_type} eq 'ja' or
                $cfg->{form_group_type} eq 'vi') {
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

print STDERR "\rStep 3... ";
for my $id1 (keys %{$Data->{eras}}) {
  my $era1 = $EraById->{$id1};
  my $rels = $Data->{eras}->{$id1}->{relateds} || {};
  for my $id2 (keys %$rels) {
    if ($rels->{$id2}->{name_contains} and $rels->{$id2}->{name_contained}) {
      $rels->{$id2}->{name_equal} = 1;
      $Data->{_ERA_TAGS}->{$era1->{key}}->{同名あり} = 1;
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
    $rels->{$id2}->{label_equal} = 1
        if $rels->{$id2}->{name_equal} or
           $rels->{$id2}->{yomi_equal} or
           $rels->{$id2}->{korean_equal} or
           $rels->{$id2}->{alphabetical_equal} or
           $rels->{$id2}->{abbr_equal};
    $rels->{$id2}->{label_similar} = 1
        if $rels->{$id2}->{name_similar} or
           $rels->{$id2}->{yomi_contains} or
           $rels->{$id2}->{korean_contains} or
           $rels->{$id2}->{alphabetical_contains} or
           $rels->{$id2}->{abbr_contains} or
           $rels->{$id2}->{yomi_contained} or
           $rels->{$id2}->{korean_contained} or
           $rels->{$id2}->{alphabetical_contained} or
           $rels->{$id2}->{abbr_contained};
    if ($rels->{$id2}->{label_equal}) {
      my $era2 = $EraById->{$id2};
      if (defined $era1->{offset} and defined $era2->{offset} and
          (($era1->{offset} - $era2->{offset}) % 60) == 0) {
        $rels->{$id2}->{label_kanshi_equal} = 1;
        $Data->{_ERA_TAGS}->{$era1->{key}}->{同名同干支年あり} = 1
            if $rels->{$id2}->{name_equal};
      }
    }
  } # $id2
}

print STDERR "\rStep 4... ";
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
print STDERR "\rStep 5... ";
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
print STDERR "\rDone. \n";

## License: Public Domain.
