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
