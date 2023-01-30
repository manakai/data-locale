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
  for my $item (values %$Tags) {
    $TagByKey->{$item->{key}}->{label_sets} = $item->{label_sets};
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
    ([values %{$Data->{eras}}], $EraById, \&set_object_tag, $Data);

for my $data (values %{$Data->{eras}}) {
  my $shorts = $data->{_SHORTHANDS} ||= {};
  for my $label_set (@{$data->{label_sets}}) {
    for my $label (@{$label_set->{labels}}) {
      names::get_label_shorthands ($label => $shorts);
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
