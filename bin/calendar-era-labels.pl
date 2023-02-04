use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Carp;
use JSON::PS;

require (path (__FILE__)->parent->child ("names.pl")->absolute);

my $Data = {};
my $RootPath = path (__FILE__)->parent->parent;

my $Eras;
my $EraById;
my $EraByKey = {};
print STDERR "Loading...";
{
  my $path = $RootPath->child ('local/calendar-era-defs-0.json');
  my $json = json_bytes2perl $path->slurp;
  $Eras = [sort { $a->{id} <=> $b->{id} } values %{$json->{eras}}];
  for my $era (@$Eras) {
    $EraById->{$era->{id}} = $era;
    $EraByKey->{$era->{key}} = $era;
  }
}
{
  my $path = $RootPath->child ('local/era-transitions-0.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{_ERA_PROPS}}) {
    for my $prop (keys %{$json->{_ERA_PROPS}->{$key}}) {
      $EraByKey->{$key}->{$prop} //= $json->{_ERA_PROPS}->{$key}->{$prop};
    }
    for my $prop (keys %{$json->{_ERA_PROPS_2}->{$key}}) {
      $EraByKey->{$key}->{$prop} //= $json->{_ERA_PROPS_2}->{$key}->{$prop};
    }
  }
}
print STDERR "done\n";

my $DataByKey = {};
for my $in_era (@$Eras) {
  my $era = $Data->{eras}->{$in_era->{id}} = {};
  $era->{id} = $in_era->{id};
  $era->{key} = $in_era->{key};
  $era->{offset} = $in_era->{offset};
  $DataByKey->{$era->{key}} = $era;

  $era->{_LABELS} = $in_era->{_LABELS};
  $era->{_SHORTHANDS} = $in_era->{_LPROPS};
} # $in_era

my $Tags;
my $TagByKey = {};
{
  my $path = $RootPath->child ('data/tags.json');
  $Tags = (json_bytes2perl $path->slurp)->{tags};
  for my $item (values %$Tags) {
    $TagByKey->{$item->{key}} = $item;
  }
}
{
  my $path = $RootPath->child ('data/tag-labels.json');
  my $json = (json_bytes2perl $path->slurp)->{tags};
  for my $item (values %$json) {
    $Tags->{$item->{id}}->{label_sets} = $item->{label_sets};
  }
}

sub set_object_tag ($$) {
  my ($obj, $tkey) = @_;
  my $item = $TagByKey->{$tkey};
  die "Tag |$tkey| not defined", Carp::longmess unless defined $item;

  $obj->{tag_ids}->{$item->{id}} = $item->{key};
  for (qw(region_of group_of period_of)) {
    for (keys %{$item->{$_} or {}}) {
      my $item2 = $Tags->{$_};
      $obj->{tag_ids}->{$item2->{id}} = $item2->{key};
      if ($item2->{type} eq 'country') {
        for (keys %{$item2->{period_of} or {}}) {
          my $item3 = $Tags->{$_};
          $obj->{tag_ids}->{$item3->{id}} = $item3->{key};
        }
      }
    }
  }
  return $item;
} # set_object_tag

names::process_object_labels
    ([values %{$Data->{eras}}], sub {
       my ($object, $label) = @_;

       my $inp = $label->{_IN};
       $label->{props}->{has_country} = 1 if $inp->{has_country};
       $label->{props}->{has_monarch} = 1 if $inp->{has_monarch};
       
       my $in = $EraById->{$object->{id} // ''};
       if ($label->{props}->{is_name} and not $label->{abbr}) {
         if (defined $in->{country_tag_id} and
             not $label->{props}->{has_country}) {
           $label->{props}->{country_tag_ids}->{$in->{country_tag_id}} = {preferred => 1};

           my $tag = $Tags->{$in->{country_tag_id}};
           for my $stag_id (keys %{$tag->{period_of}}) {
             my $stag = $Tags->{$stag_id};
             if ($stag->{type} eq 'country') {
               $label->{props}->{country_tag_ids}->{$stag->{id}} ||= {};
             }
           }
         }
         if (defined $in->{monarch_tag_id} and
             not $label->{props}->{has_country} and
             not $label->{props}->{has_monarch}) {
           $label->{props}->{monarch_tag_ids}->{$in->{monarch_tag_id}} = {preferred => 1};
         }
       }
       
          my $preferred_tag_ids = delete $label->{_PREFERRED};
          for my $key (qw(country_tag_ids monarch_tag_ids)) {
            if (keys %{$label->{props}->{$key} or {}}) {
              my $has_preferred = 0;
              for (values %{$label->{props}->{$key} or {}}) {
                $has_preferred++ if $_->{preferred};
              }
              die "Too many preferred" if $has_preferred > 1;
              if ($has_preferred == 0) {
                if ($preferred_tag_ids->{$key}) {
                  $label->{props}->{$key}->{$preferred_tag_ids->{$key}}->{preferred} = 1;
                } else {
                  for (sort { $a <=> $b } keys %{$label->{props}->{$key}}) {
                    $label->{props}->{$key}->{$_}->{preferred} = 1;
                    last;
                  }
                }
              }
            }
          } # $key

       }, sub { $Tags->{$_[0]} }, \&set_object_tag, $Data);

for my $data (values %{$Data->{eras}}) {
  my $shorts = $data->{_SHORTHANDS} ||= {};
  for my $label_set (@{$data->{label_sets}}) {
    for my $label (@{$label_set->{labels}}) {
      if ($label->{props}->{is_name}) {
        names::get_label_shorthands ($label => $shorts);
        my $shorts2 = {};
        names::get_label_shorthands ($label => $shorts2);

        my $prefixes = {};
        my $prefixes_c = {};
        for my $tag_id (keys %{$label->{props}->{country_tag_ids} or {}}) {
          my $tag = $Tags->{$tag_id};
          for my $t_ls (@{$tag->{label_sets}}) {
            for my $t_l (@{$t_ls->{labels}}) {
              if ($t_l->{props}->{is_name}) {
                my $ss;
                if (defined $t_l->{_shorts}) {
                  $ss = $t_l->{_shorts};
                } else {
                  $ss = $t_l->{_shorts} = {};
                  names::get_label_shorthands ($t_l => $ss);
                }
                for my $lang (keys %{$ss->{_names} or {}}) {
                  for my $s (keys %{$ss->{_names}->{$lang}}) {
                    $prefixes->{$lang}->{$s} = 1;
                    $prefixes_c->{$lang}->{$s} = 1;
                  }
                }
              }
            }
          }
        } # $tag_id
        for my $tag_id (keys %{$label->{props}->{monarch_tag_ids} or {}}) {
          my $tag = $Tags->{$tag_id};
          for my $t_ls (@{$tag->{label_sets}}) {
            for my $t_l (@{$t_ls->{labels}}) {
              if ($t_l->{props}->{is_name}) {
                my $ss;
                if (defined $t_l->{_shorts}) {
                  $ss = $t_l->{_shorts};
                } else {
                  $ss = $t_l->{_shorts} = {};
                  names::get_label_shorthands ($t_l => $ss);
                }
                for my $lang (keys %{$ss->{_names} or {}}) {
                  for my $s (keys %{$ss->{_names}->{$lang}}) {
                    $prefixes->{$lang}->{$s} = 1;
                  }
                  for my $s1 ((keys %{$prefixes_c->{$lang}}),
                              (keys %{$prefixes_c->{_}})) {
                    for my $s (keys %{$ss->{_names}->{$lang}}) {
                      $prefixes->{$lang}->{$s1 . $s} = 1;
                    }
                  }
                }
              }
            }
          }
        } # $tag_id
        for my $lang (keys %$prefixes) {
          next if $lang eq '_';
          for my $s1 (keys %{$prefixes->{$lang}}) {
            for my $s3 (keys %{$shorts2->{_names}->{$lang}}) {
              $shorts->{names}->{$s1 . $s3} = 1;
            }
          }
        }
        for my $s1 (keys %{$prefixes->{_} or {}}) {
          for my $lang (keys %{$shorts2->{_names} or {}}) {
            for my $s3 (keys %{$shorts2->{_names}->{$lang}}) {
              $shorts->{names}->{$s1 . $s3} = 1;
            }
          }
        } # $tag_id
      }
    } # $label
  } # $label_set
}

{
  my $path = $RootPath->child ('src/era-codes-14.txt');
  my $i = 1;
  for (grep { length } split /\x0D?\x0A/, $path->slurp_utf8) {
    ($DataByKey->{$_} or die "Era |$_| not found")->{_SHORTHANDS}->{code14} = $i;
    $i++;
  }
}
{
  my $path = $RootPath->child ('src/era-codes-15.txt');
  my $i = 1;
  for (grep { length } split /\x0D?\x0A/, $path->slurp_utf8) {
    ($DataByKey->{$_} or die "Era |$_| not found")->{_SHORTHANDS}->{code15} = $i;
    $i++;
  }
}
{
  my $path = $RootPath->child ('src/era-codes-24.txt');
  my $i = 1;
  for (grep { length } split /\x0D?\x0A/, $path->slurp_utf8) {
    ($DataByKey->{$_} or die "Era |$_| not found")->{_SHORTHANDS}->{code24} = $i;
    $i++;
  }
}
{
  my $path = $RootPath->child ('local/cldr-core-json/ja.json');
  my $json = json_bytes2perl $path->slurp;
  for my $i (0..$#{$json->{"dates_calendar_japanese_era"}}) {
    my $v = $json->{"dates_calendar_japanese_era"}->[$i];
    next unless defined $v;
    ($DataByKey->{$v} or die "Era |$v| not found")->{_SHORTHANDS}->{code10} = $i;
  }
}

{
  my $Scores = {};
  for my $era (values %{$Data->{eras}}) {
    my $in_era = $EraById->{$era->{id}};
    $Scores->{$era->{key}} = 0;
    $Scores->{$era->{key}} += 50000
        if $in_era->{jp_era} or $in_era->{jp_emperor_era} or
           $in_era->{jp_north_era} or $in_era->{jp_south_era};
    $Scores->{$era->{key}} += 40000 if $in_era->{jp_private_era};
    $Scores->{$era->{key}} += 10000
        if defined $era->{_SHORTHANDS}->{name_cn};
    $Scores->{$era->{key}} += 10000 - $in_era->{offset}
        if defined $in_era->{offset};
  }
  my $Names = {};
  for my $era (sort {
    $Scores->{$b->{key}} <=> $Scores->{$a->{key}} ||
    $a->{key} cmp $b->{key};
  } values %{$Data->{eras}}) {
    my @all_name = keys %{$era->{_SHORTHANDS}->{names} or {}};
    for (sort { $a cmp $b } @all_name) {
      $Names->{$_}->{$era->{key}} = 1;
      $Data->{_SHORTHANDS}->{name_to_key}->{jp}->{$_} //= $era->{key};
    }
  }

  for my $name (keys %$Names) {
    next unless 2 <= keys %{$Names->{$name}};
    $Data->{_SHORTHANDS}->{name_conflicts}->{$name} = $Names->{$name};
  }
}

{
  use utf8;
  my $path = $RootPath->child ('local/number-values.json');
  my $json = json_bytes2perl $path->slurp;
  my $is_number = {};
  for (keys %$json) {
    if (defined $json->{$_}->{cjk_numeral}) {
      $is_number->{$_} = 1;
    }
  }
  my $path2 = $RootPath->child ('data/numbers/kanshi.json');
  my $json2 = json_bytes2perl $path2->slurp;
  for (split //, $json2->{name_lists}->{kanshi}) {
    $is_number->{$_} = 1 unless $_ eq ' ';
  }
  $is_number->{$_} = 1 for qw(元 正 𠙺 端 冬 臘 腊 初 𡔈 末 前 中 後 建 閏); # 元年, 正月, 初七日, 初年, 初期, 前半, ...
  $is_number->{$_} = 1 for qw(年 𠡦 𠦚 載 𡕀 𠧋 歳 月 囝 日 𡆠 時 分 秒 世 紀 星 期 曜 旬 半 火 水 木 金 土);
  my $number_pattern = join '|', map { quotemeta $_ } keys %$is_number;
  for my $data (values %{$Data->{eras}}) {
    for (keys %{$data->{_SHORTHANDS}->{names}}) {
      while (/($number_pattern)/go) {
        $Data->{_SHORTHANDS}->{numbers_in_era_names}->{$1}->{$_} = 1;
      }
    }
  }
}

for my $data (values %{$Data->{eras}}) {
  for (keys %{$data->{_SHORTHANDS}->{names}}) {
    $Data->{_SHORTHANDS}->{name_to_keys}->{$_}->{$data->{key}} = 1;
  }
  $data->{_TAG_IDS} = delete $data->{tag_ids};
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
