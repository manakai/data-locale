use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $Data = {};

my $RootPath = path (__FILE__)->parent->parent;

sub from_ss ($) {
  my $ss = shift;
  my $t = join ' ', map {
    if (ref $_) {
      join '', @$_;
    } else {
      {
        '._' => ' ',
        ".'" => "'",
        '.-' => '-',
      }->{$_} // $_;
    }
  } @$ss;
  $t =~ s/   / /g;
  return $t;
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
        next unless $label->{props}->{is_name};
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
          } else { # non-compound
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
                for (@{$fs->{ja_latin_old_wrongs}}) {
                  push @$values, [6108, from_ss $_];
                }
              } elsif ($fs->{form_set_type} eq 'alphabetical') {
                if (defined $fs->{ja_latin_old}) {
                  push @$values, [6107, from_ss $fs->{ja_latin_old}];
                }
                for (@{$fs->{ja_latin_old_wrongs}}) {
                  push @$values, [6108, from_ss $_];
                }
              } elsif ($fs->{form_set_type} eq 'korean' and
                       #$era->{tag_ids}->{1003} # 日本
                       ($fs->{origin_lang} // '') eq 'ja') {
                if (defined $fs->{kr}) {
                  push @$values, [6230, from_ss $fs->{kr}];
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

sub xx ($) { my $s = to_hiragana shift; $s =~ s/-//g; $s =~ s/ //g; return lc $s }

sub remove_long ($) {
  my $s = $_[0];
  use utf8;
  $s =~ s/ゅう/ゅ/g;
  $s =~ s/ょう/ょ/g;
  $s =~ s/おう/お/g;
  $s =~ s/こう/こ/g;
  $s =~ s/そう/そ/g;
  $s =~ s/とう/と/g;
  $s =~ s/どう/ど/g;
  $s =~ s/のう/の/g;
  $s =~ s/ほう/ほ/g;
  $s =~ s/ぼう/ぼ/g;
  $s =~ s/ぽう/ぽ/g;
  $s =~ s/もう/も/g;
  $s =~ s/ゆう/ゆ/g;
  $s =~ s/よう/よ/g;
  $s =~ s/ろう/ろ/g;
  return $s;
} # remove_long

sub get_k_variant ($) {
  my $s = $_[0];
  $s = remove_long $s;
  use utf8;
  $s =~ s/^か/が/;
  $s =~ s/^き(?![ゃゅょ])/ぎ/;
  $s =~ s/^く/ぐ/;
  $s =~ s/^け/げ/;
  $s =~ s/^こ/ご/;
  return $s;
} # get_k_variant

{
  use utf8;
  my $K2H = {qw(
    아 あ 이 い 우 う 에 え 오 お  안 あん 운 うん 엔 えん
    카 か 키 き 쿠 く 케 け 코 こ  칸 かん
    사 さ 시 し 스 す 세 せ 소 そ
    타 た 치 ち 쓰 つ 테 て 토 と  덴 てん
    나 な 니 に 누 ぬ 네 ね 노 の  난 なん 닌 にん
    하 は 히 ひ 후 ふ 헤 へ 호 ほ
    마 ま 미 み 무 む 메 め 모 も  만 まん 몬 もん
    야 や 유 ゆ 요 よ
    라 ら 리 り 루 る 레 れ 로 ろ
    와 わ
    가 が 기 ぎ 구 ぐ 게 げ 고 ご  간 がん 겐 げん
    자 ざ 지 じ 즈 ず 제 ぜ 조 ぞ  진 じん
    다 だ 데 で 도 ど
    바 ば 비 び 부 ぶ 베 べ 보 ぼ  분 ぶん
    파 ぱ 피 ぴ 푸 ぷ 페 ぺ 포 ぽ
    캬 きゃ 큐 きゅ 쿄 きょ
    갸 ぎゃ 규 ぎゅ 교 ぎょ
    샤 しゃ 슈 しゅ 쇼 しょ
    자 じゃ 주 じゅ 조 じょ
    차 ちゃ 추 ちゅ 초 ちょ
    냐 にゃ 뉴 にゅ 뇨 にょ
    햐 ひゃ 휴 ひゅ 효 ひょ
    뱌 びゃ 뷰 びゅ 뵤 びょ
    퍄 ぴゃ 퓨 ぴゅ 표 ぴょ
    먀 みゃ 뮤 みゅ 묘 みょ
    랴 りゃ 류 りゅ 료 りょ
  )};
  #오 を
  my $K2H1 = {qw(
    다 た 지 ち 쓰 つ 데 て 도 と
    갸 きゃ 규 きゅ 교 きょ
  )};
  #가 か 기 き 구 く 게 け 고 こ  간 かん 겐 けん
  #가 が 기 ぎ 구 ぐ 게 げ 고 ご
  #자 ちゃ 주 ちゅ 조 ちょ

  my $NoMap = {};
  sub from_korean ($) {
    my $s = $_[0];

    my $t = join ' ', map {
      my $x = $_;
      $x =~ s/ //g;
      $x =~ s{^(\p{sc=Hang})}{
        if ($K2H1->{$1} // $K2H->{$1}) {
          $K2H1->{$1} // $K2H->{$1};
        } else {
          $1;
        }
      }ge;
      $x =~ s{(?!^)(\p{sc=Hang})}{
        if ($K2H->{$1}) {
          $K2H->{$1};
        } else {
          $1;
        }
      }ge;
      $x;
    } split /-/, $s;

    while ($t =~ /(\p{sc=Hang})/g) {
      warn "No hiragana mapping for |$1|\n"
          unless $NoMap->{$1}++;
    }

    return $t;
  } # from_korean
}

{
  my $SourceIds = [map { ''.$_ }
    6100..6108,
    6001..6004, 6011, 6012, 6013..6020, 6031..6037, 6040,
    6041..6046, 6047..6048, 6049..6050, 6051..6052, 6060,
    6062, 6063, 6068, 6069, 6071..6084, 6090..6091, 6099,
    6230,
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
  $Data->{sources}->{$_}->{is_korean} = 1
      for qw(6230);
  $Data->{sources}->{$_}->{non_native} = 1
      for qw(6002 6003 6004 6230);
}

for my $era (values %{$Data->{eras}}) {
  my $all = {};
  my $all_k = {};
  for (keys %{$era->{yomis}}) {
    next unless /^[0-9]+$/;
    if ($Data->{sources}->{$_}->{is_korean}) {
      my @x;
      my @out;
      for my $in (@{$era->{yomis}->{$_}}) {
        my $out = from_korean $in;
        push @out, $out;
        push @x, $in . ' (' . $out . ')';
      }
      $era->{yomis}->{$_} = \@x;
      $all_k->{$_} = 1 for @out;
    } else {
      $all->{$_} = 1 for map { xx $_ } @{$era->{yomis}->{$_}};
    }
  }
  for (keys %{$era->{yomis}}) {
    next unless /^[0-9]+$/ and 6100 <= $_ and $_ <= 6109;
    for (map { xx $_ } @{$era->{yomis}->{$_}}) {
      delete $all->{$_};
      delete $all_k->{$_};
      delete $all_k->{get_k_variant $_};
    }
  }
  $era->{missing_yomis} = [sort { $a cmp $b } keys %{{%$all, %$all_k}}];
} # $era

print perl2json_bytes_for_record $Data;

## License: Public Domain.
