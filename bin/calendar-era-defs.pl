use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
binmode STDERR, qw(:encoding(utf-8));

my $root_path = path (__FILE__)->parent->parent;

my $Data = {};

my $Tags;
my $TagByKey = {};
{
  my $path = $root_path->child ('data/tags.json');
  $Tags = (json_bytes2perl $path->slurp)->{tags};
  for my $item (values %$Tags) {
    $TagByKey->{$item->{key}} = $item;
  }
}

## Japanese official eras && pre-大宝 emperor eras
for (
  ['src/wp-jp-eras.json', undef, 'name' => ['name', 'wref_ja']],
  ['local/era-defs-jp-emperor.json', 'eras', 'name' => ['name_ja', 'name_kana', 'name_latn', 'offset', 'wref_ja', 'wref_en']],
  ['local/era-defs-jp-wp-en.json', 'eras', 'key' => ['wref_en']],
  ['local/era-yomi-list.json', 'eras', 'key' => ['ja_readings']],
) {
  my ($file_name, $first_level, $key_key, $data_keys) = @$_;
  my $path = $root_path->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  $json = $json->{$first_level} if defined $first_level;
  for my $key (keys %$json) {
    my $data = $json->{$key};
    next if not defined $data->{$key_key};
    $Data->{eras}->{$key}->{key} //= $data->{$key_key};
    $Data->{eras}->{$key}->{label_sets} //= [{labels => [{reps => []}]}];
    for (@$data_keys) {
      if (defined $data->{$_}) {
        if ($_ eq 'name_ja' or $_ eq 'name') {
          my $name = $data->{$_};
          push @{$Data->{eras}->{$key}->{label_sets}->[0]->{labels}->[0]->{reps}},
              {han => 1, name => 1, values => [{value => $name, ja => 1}]};

          $name =~ s/摂政$// &&
          push @{$Data->{eras}->{$key}->{label_sets}->[0]->{labels}},
              {reps => [{han => 1, name => 1, values => [{value => $name, ja => 1}]}]};

          $name =~ s/皇后$// &&
          push @{$Data->{eras}->{$key}->{label_sets}->[0]->{labels}},
              {reps => [{han => 1, name => 1, values => [{value => $name, ja => 1}]}]};
          
          $name =~ s/天皇$// &&
          push @{$Data->{eras}->{$key}->{label_sets}->[0]->{labels}},
              {reps => [{han => 1, name => 1, values => [{value => $name, ja => 1}]}]};

          $Data->{eras}->{$key}->{short_name} = $name
              unless $name eq $data->{$_};

          # XXX name_kana name_latn
        } elsif ($_ eq 'ja_readings') {
          push @{$Data->{eras}->{$key}->{label_sets}->[0]->{labels}->[0]->{reps}},
              map { {%$_, yomi => 1} } @{$data->{$_}};
        } else {
          $Data->{eras}->{$key}->{$_} = $data->{$_};
        }
      }
    }
  } # $json
}

sub drop_kanshi ($) {
  my $name = shift;
  $name =~ s/\(\w+\)$//;
  return $name;
} # drop_kanshi

my $IndexToKanshi = {map { my $x = $_; $x =~ s/\s+//g; $x =~ s/(\d+)/ $1 /g;
                           grep { length } split /\s+/, $x } q{
1甲子2乙丑3丙寅4丁卯5戊辰6己巳7庚午8辛未9壬申10癸酉11甲戌12乙亥13丙子
14丁丑15戊寅16己卯17庚辰18辛巳19壬午20癸未21甲申22乙酉23丙戌24丁亥25戊子
26己丑27庚寅28辛卯29壬辰30癸巳31甲午32乙未33丙申34丁酉35戊戌36己亥
37庚子38辛丑39壬寅40癸卯41甲辰42乙巳43丙午44丁未45戊申46己酉47庚戌48辛亥
49壬子50癸丑51甲寅52乙卯53丙辰54丁巳55戊午56己未57庚申58辛酉59壬戌60癸亥
}};
sub year2kanshi ($) {
  my $year = shift;
  my $mod = ($year - 4) % 60;
  return $IndexToKanshi->{$mod + 1};
} # year2kanshi

{
  my $path = $root_path->child ('src/wp-cn-eras.json');
  my $json = json_bytes2perl $path->slurp;
  my @era;
  push @era, grep { $_->{caption} ne 'misc' } @{$json->{eras}};
  push @era, grep { $_->{caption} eq 'misc' } @{$json->{eras}};
  my $nc2key = {
    ## Conflictions with Japanese era
    qw(
    建武/東漢 建武(乙酉)
    建武/西晉 建武(甲子)
    建武/東晉 建武(丁丑)
    建武/後趙 建武(乙未)
    建武/西燕 建武(丙戌)
    建武/齊 建武(甲戌)
    建武/misc 建武(己酉)
    元和/東漢 元和(甲申)
    元和/唐朝 元和(丙戌)
    元德/西夏 元德(己亥)
    元亨/後理 元亨(乙巳)
    承和/北涼 承和(癸酉)
    至德/陳 至德(癸卯)
    至德/唐朝 至德(丙申)
    大寶/梁 大寶(庚午)
    大寶/後理 大寶(己巳)
    大寶/南漢 大寶(戊午)
    大寶/misc 大寶(乙丑)
    大同/梁 大同(乙卯)
    大同/遼 大同(丁未)
    大同/中華民國成立以後的中國君主 大同(壬申)
    大同/misc 大同(甲申)
    天正/梁 天正(辛未)
    天正/misc/壬申 天正(壬申)
    天正/misc/戊子 天正(戊子)
    天正/misc/辛巳 天正(辛巳)
    天保/西梁 天保(壬午)
    天保/北齊 天保(庚午)
    天福/後晉 天福(丙申)
    天平/東魏 天平(甲寅)
    天和/北周 天和(丙戌)
    天授/武周 天授(庚寅)
    天授/後理 天授(丙子)
    天授/misc 天授(丁未)
    天應/大長和 天應(丁亥)
    天德/閩 天德(癸卯)
    天德/金朝 天德(己巳)
    天德/misc/丙子 天德(丙子)
    天德/misc/戊子 天德(戊子)
    天德/misc/癸丑/1216 天德(耶律金山)
    天德/misc/癸丑/1853 天德(癸丑)
    天德/misc/辛亥 天德(辛亥)
    天慶/遼 天慶(辛卯)
    天慶/西夏 天慶(甲寅)
    天慶/misc 天慶(己巳)
    天曆/元朝 天曆(戊辰)
    天元/北元 天元(己未)
    天安/北魏 天安(丙午)
    天祿/遼 天祿(丁未)
    天明/misc 天明(癸未)
    弘治/明朝 弘治(戊申)
    承平/北魏 承平(壬辰)
    承平/misc 承平(癸未)
    承安/金朝 承安(丙辰)
    神龜/北魏 神龜(戊戌)
    建德/北周 建德(壬辰)
    承平/高昌 承平(壬午)
    仁壽/隋朝 仁壽(辛酉)
    文明/唐朝 文明(甲申)
    乾元/唐朝 乾元(戊戌)
    貞元/唐朝 貞元(乙丑)
    貞元/金朝 貞元(癸酉)
    貞觀/唐朝 貞觀(丁亥)
    貞觀/西夏 貞觀(辛巳)
    寶曆/唐朝 寶曆(乙巳)
    寶曆/渤海國 寶曆(甲寅)
    文德/唐朝 文德(戊申)
    文德/大理國 文德(戊戌)
    文安/後理 文安(乙酉)
    文治/後理 文治(庚寅)
    仁安/渤海國 仁安(庚申)
    正曆/渤海國 正曆(乙亥)
    永和/東漢 永和(丙子)
    永和/東晉 永和(乙巳)
    永和/後秦 永和(丙辰)
    永和/閩 永和(乙未)
    永和/misc 永和(辛丑)
    永德/渤海國 永德(庚寅)
    永曆/南明 永曆(丁亥)
    永曆/misc 永曆(丁亥)
    明德/大理國 明德(壬子)
    明德/後蜀 明德(甲午)
    保安/大理國 保安(乙酉)
    正元/曹魏 正元(甲戌)
    正平/北魏 正平(辛卯)
    正平/misc/戊辰 正平(戊辰)
    正平/misc/丁丑 正平(丁丑)
    正治/大理國 正治(丁卯)
    正治/misc 正治(丁酉)
    正安/大理國 正安(癸巳)
    正德/西夏 正德(丁未)
    正德/明朝 正德(丙寅)
    正德/misc 正德(辛丑)
    嘉慶/清朝 嘉慶(丙辰)
    昌泰/misc 昌泰(辛巳)
    永樂/明朝 永樂(癸未)

    大同/大封民 大同(大封民)
    安和/大長和 安和(大長和)
    明應/大理國 明應(大理國)
    明治/大理國 明治(大理國)
    天明/大理國 天明(大理國)
    正德/大理國 正德(大理國)
    建德/後理 建德(後理)
    仁壽/後理 仁壽(後理)
    延慶/西遼 延慶(西遼)
    至德/misc 至德(高觀音自)

    清寧/遼 清寧(乙未)
    神武/大理國 神武(大理國)
    武烈/misc 武烈(李添保)

    德昌/北齊 德昌(丙申)
    延壽/高昌 延壽(甲申)
    朱雀/渤海國 朱雀(癸巳)
    天政/後理 天政(癸未)
    大和/吳 大和(己丑)
    正法/misc 正法(李合戎)
    ),
  };
  %$nc2key = (%$nc2key);
  my @cd = split /\s+/, $root_path->child ('src/era-china-dups.txt')->slurp_utf8;
  while (@cd) {
    my $nc = shift @cd;
    my $key = shift @cd;
    if (not defined $nc2key->{$nc}) {
      $nc2key->{$nc} = $key;
    } else {
      if ($key =~ /\((\w\w)\)$/) {
        $nc2key->{"$nc/$1"} = $key;
      } else {
        die "Duplicate key rule |$nc $key|";
      }
    }
  }
  my @dup;
  for my $src (@era) {
    next if $src->{dup};
    next if $src->{name} eq '中平' and $src->{offset} == 189-1;
    next if $src->{name} eq '乾化' and $src->{offset} == 913-1;
    #next if $src->{name} eq '宣統' and $src->{offset} == 1916;
    next if $src->{name} eq '明德' and not defined $src->{offset};
    next if $src->{name} eq '廣德' and not defined $src->{offset};
    next if $src->{name} eq '永天' and $src->{offset} == 1420-1; # viet
    next if $src->{name} eq '監國' and $src->{offset} == 1646-1;
    next if $src->{name} eq '？？';
    #$src->{offset} = 1861 - 1 if $src->{name} eq '祺祥' and not defined $src->{offset};
    my $key = (defined $src->{offset} ?
                   ($nc2key->{$src->{name}.'/'.$src->{caption}.'/'.year2kanshi(($src->{offset})+1).'/'.($src->{offset}+1)} ||
                    $nc2key->{$src->{name}.'/'.$src->{caption}.'/'.year2kanshi(($src->{offset})+1)})
              : undef) ||
              $nc2key->{$src->{name}.'/'.$src->{caption}} ||
              $src->{name};
    if (defined $Data->{name_to_key}->{jp}->{$key} or
        (not $key eq $src->{name} and defined $Data->{eras}->{$key})) {
      warn "Conflict |$src->{name}| (|$src->{caption}|) [key $key]";
      if (defined $src->{offset}) {
        push @dup, sprintf "%s/%s %s(%s) %d\n",
            $src->{name},
            $src->{caption},
            $src->{name},
            year2kanshi ($src->{offset} + 1),
            $src->{offset} + 1;
      } else {
        push @dup, sprintf "%s/%s %s(%s)\n",
            $src->{name},
            $src->{caption},
            $src->{name},
            $src->{caption};
      }
      next;
    }
    $Data->{eras}->{$key} = my $data = {};
    $data->{key} = $key;
    $data->{label_sets} //= [{labels => [{reps => []}]}];
    $data->{offset} = $src->{offset} if defined $src->{offset};
    $data->{wref_zh} = $src->{wref} if defined $src->{wref};

    if ($src->{cn} eq $src->{name}) {
      push @{$data->{label_sets}->[0]->{labels}->[0]->{reps}},
          {han => 1, name => 1,
           values => [{value => $src->{name}, cn => 1, tw => 1}]};
    } else {
      push @{$data->{label_sets}->[0]->{labels}->[0]->{reps}},
          {han => 1, name => 1,
           values => [{value => $src->{name}, tw => 1},
                      {value => $src->{cn}, cn => 1}]};
    }
    warn "Wikipedia cn != my: $src->{cn} $src->{my}"
        if $src->{cn} ne $src->{my};
    warn "Wikipedia cn != sg: $src->{cn} $src->{sg}"
        if $src->{cn} ne $src->{sg};
    warn "Wikipedia tw != hk: $src->{tw} $src->{hk}"
        if $src->{tw} ne $src->{hk};
    warn "Wikipedia tw != mo: $src->{tw} $src->{mo}"
        if $src->{tw} ne $src->{mo};
  } # $src

  warn $_ for @dup;
}

for my $path (
  $root_path->child ('src/era-viet.txt'),
  $root_path->child ('src/era-korea.txt'),
) {
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)(?:\s+(BC|)(\d+)|)(?:$|-)/) {
      my $first_year = defined $3 ? $2 ? 1 - $3 : $3 : undef;
      my @name = split /,/, $1;
      my @n;
      for (@name) {
        if (defined $Data->{name_to_key}->{jp}->{$_} or
            defined $Data->{eras}->{$_}) {
          die "Duplicate era |$_| ($_(@{[year2kanshi $first_year]})) in $path";
        } else {
          push @n, $_;
        }
      }
      next unless @n;
      my $d = $Data->{eras}->{$n[0]} ||= {};
      $d->{key} = $n[0];
      $d->{label_sets} //= [{labels => [{reps => []}]}];
      if (defined $first_year) {
        $d->{offset} = $first_year - 1;
      }

      my @nn = map { drop_kanshi $_ } @n;
      push @{$d->{label_sets}->[0]->{labels}->[0]->{reps}},
          {han => 1, name => 1, values => [{value => $_}]} for @nn;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

sub set_tag ($$) {
  my ($key, $tkey) = @_;
  my $item = $TagByKey->{$tkey};
  die "Tag |$tkey| not defined" unless defined $item;

  $Data->{eras}->{$key}->{tag_ids}->{$item->{id}} = $item->{key};
      for (qw(region_of group_of period_of)) {
        for (keys %{$item->{$_} or {}}) {
          my $item2 = $Tags->{$_};
          $Data->{eras}->{$key}->{tag_ids}->{$item2->{id}} = $item2->{key};
          if ($item2->{type} eq 'country') {
            for (keys %{$item2->{period_of} or {}}) {
              my $item3 = $Tags->{$_};
              $Data->{eras}->{$key}->{tag_ids}->{$item3->{id}} = $item3->{key};
            }
          }
        }
      }
} # set_tag

{
  use utf8;
  $Data->{eras}->{단기}->{key} = '단기';
  $Data->{eras}->{AD}->{key} = 'AD';
  $Data->{eras}->{단기}->{label_sets} //= [{labels => [{reps => []}]}];
  $Data->{eras}->{AD}->{label_sets} //= [{labels => [{reps => []}]}];
}

for (
  ['local/era-date-list.json' => ['_usages', map {
    ($_.'start_year', $_.'start_day',
     $_.'official_start_day', $_.'actual_start_day',
     $_.'end_year', $_.'end_day',
     $_.'official_end_day', $_.'actual_end_day',
     'jp_'.$_.'era', 'jp_emperor_era',
     'starts', 'ends', 'offset',
     'known_oldest_year', 'known_latest_year');
  } '', 'north_', 'south_']],
  ['local/cn-ryuukyuu-era-list.json' => ['cn_ryuukyuu_era']],
) {
  my ($file_name, $data_keys) = @$_;
  my $path = $root_path->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    my $data = $json->{eras}->{$key};
    for (@$data_keys) {
      $Data->{eras}->{$key}->{$_} = $data->{$_} if defined $data->{$_};
      use utf8;
      if ($data->{jp_era}) {
        set_tag $key, '日本';
      }
      if ($data->{jp_north_era}) {
        set_tag $key, '日本北朝';
      }
      if ($data->{jp_south_era}) {
        set_tag $key, '日本南朝';
      }
      if ($data->{jp_emperor_era}) {
        set_tag $key, '天皇即位紀年 (古代)';
      }
    }
  }
}

{
  my $path = $root_path->child ('src/era-variants.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)\s*=\s*(\S+)$/) {
      my $variant = $1;
      my $key = $2;
      die "Era |$key| not defined" unless defined $Data->{eras}->{$key};

      my $name = drop_kanshi $variant;
      push @{$Data->{eras}->{$key}->{label_sets}->[0]->{labels}->[0]->{reps}},
          {han => 1, name => 1, values => [{value => $name}]};
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for my $path (
  $root_path->child ('src/era-data.txt'),
  $root_path->child ('src/era-data-tw.txt'),
) {
  my $key;
  my $prop;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^\[(.+)\]$/) {
      $key = $1;
      die "Bad key |$key|" unless $Data->{eras}->{$key};
      undef $prop;
    } elsif (/^def\[(.+)\]$/) {
      $key = $1;
      die "Bad key |$key|"
          if defined $Data->{eras}->{$key} and
             defined $Data->{eras}->{$key}->{key};
      undef $prop;
      $Data->{eras}->{$key}->{key} = $1;
      $Data->{eras}->{$key}->{label_sets} //= [{labels => [{reps => []}]}];
    } elsif (defined $key and /^(source)$/) {
      push @{$Data->{eras}->{$key}->{sources} ||= []}, $prop = {};
    } elsif (defined $prop and ref $prop eq 'HASH' and
             /^  (title|url):(.+)$/) {
      $prop->{$1} = $2;
    } elsif (defined $key and /^(wref_(?:ja|zh|en|ko))\s+(.+)$/) {
      $Data->{eras}->{$key}->{$1} = $2;
    } elsif (defined $key and /^(name)\s*:=\s*(\S+)$/) {
      $Data->{eras}->{$key}->{$1} = $2;
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {han => 1, name => 1, values => [{value => $2}]};
    } elsif (defined $key and /^name\s+(.+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {han => 1, name => 1, values => [{value => $1}]};
    } elsif (defined $key and /^name_kana\s+(.+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {kana => $1, yomi => 1};
    } elsif (defined $key and /^name_(ja|cn|tw)(!|)\s+(.+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {han => 1, name => 1,
           values => [{value => $3, $1 => 1, _preferred => $2}]};
    } elsif (defined $key and /^name_(ko|vi)(!|)\s+(.+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {$1 => 1, name => 1,
           value => $3,
           _preferred => $2};
    } elsif (defined $key and /^name_(en)(!|)\s+(.+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {alphabetical => 1, name => 1,
           $1 => 1,
           value => $3,
           _preferred => $2};
    } elsif (defined $key and /^abbr_ja\s+([A-Z])\s+(\1[a-z]*)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {ja => 1, abbr => 'first',
           latin => $1, expanded => $2};
    } elsif (defined $key and /^abbr_(ja|tw)\s+(\p{Hani})\s+(\2\p{Hani}*)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {han => 1, abbr => 'first',
           values => [{value => $2, $1 => 1, expanded => $3}]};
    } elsif (defined $key and /^abbr_(ja)\s+(\p{Latn}+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {$1 => 1, abbr => 'first',
           latin => $2};
    } elsif (defined $key and /^abbr_(vi)\s+(\p{Latn}+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {$1 => 1, abbr => 'first',
           value => $2};
    } elsif (defined $key and /^abbr\s+(\p{Latn}+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {alphabetical => 1, abbr => 'first',
           value => $1};
    } elsif (defined $key and /^acronym\s+(\p{Latn}+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {alphabetical => 1, abbr => 'acronym', name => 1,
           dotless => $1};
    } elsif (defined $key and /^acronym\s+(\p{Latn}+)\s+(\p{Latn}+(?: \p{Latn}+)+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {alphabetical => 1, abbr => 'acronym', name => 1,
           dotless => $1, expanded => $2};
    } elsif (defined $key and /^acronym\s+((?:\p{Latn}\.)+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {alphabetical => 1, abbr => 'acronym', name => 1,
           dotted => $1};
    } elsif (defined $key and /^acronym\s+((?:\p{Latn}\.)+)\s+(\p{Latn}+(?: \p{Latn}+)+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {alphabetical => 1, abbr => 'acronym', name => 1,
           dotted => $1, expanded => $2};
    } elsif (defined $key and /^acronym\s+(\p{Latn}+)\s+((?:\p{Latn}\.)+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {alphabetical => 1, abbr => 'acronym', name => 1,
           dotless => $1, dotted => $2};
    } elsif (defined $key and /^acronym\s+(\p{Latn}+)\s+((?:\p{Latn}\.)+)\s+(\p{Latn}+(?: \p{Latn}+)+)$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}->[-1]->{reps}},
          {alphabetical => 1, abbr => 'acronym', name => 1,
           dotless => $1, dotted => $2, expanded => $3};
    } elsif (defined $key and /^&$/) {
      push @{$Data->{eras}->{$key}->{label_sets}->[-1]->{labels}},
          {reps => []};
    } elsif (defined $key and /^&&$/) {
      push @{$Data->{eras}->{$key}->{label_sets}},
          {labels => [{reps => []}]};
    } elsif (defined $key and /^(unicode)\s+(.+)$/) {
      $Data->{eras}->{$key}->{$1} = $2;
      $Data->{eras}->{$key}->{names}->{$2} = 1;
    } elsif (defined $key and /^(AD|BC)(-?\d+)\s*=\s*(\d+)$/) {
      my $g_year = $1 eq 'BC' ? 1 - $2 : $2;
      my $e_year = $3;
      $Data->{eras}->{$key}->{offset} = $g_year - $e_year;
    } elsif (defined $key and
             /^u\s+(-?[0-9]+)(?:-([0-9]+)('|)(?:-([0-9]+)|)|)(?:\s+(\w+)|)$/) {
      push @{$Data->{eras}->{$key}->{_usages} ||= []},
          [[0+$1, $2?0+$2:undef, $3?1:0, $4?0+$4:undef], $5];
    } elsif (defined $key and /^(sw)\s+(.+)$/) {
      $Data->{eras}->{$key}->{suikawiki} = $2;
    } elsif (defined $key and /^code\s+#(7|2)\s+(.)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = $2;
    } elsif (defined $key and /^code\s+#([1-9][0-9]*)\s+([0-9]+)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = 0+$2;
    } elsif (defined $key and /^code\s+#(20)\s+(-[0-9]+)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = 0+$2;
    } elsif (defined $key and /^code\s+#(16)\s+([A-Z])$/) {
      $Data->{eras}->{$key}->{'code' . $1} = $2;
    } elsif (defined $key and /^code\s+#([1-9][0-9]*)\s+(北[1-9][0-9]*)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = $2;
    } elsif (defined $key and /^code\s+#([1-9][0-9]*)\s+0x([0-9A-Fa-f]+)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = hex $2;
    } elsif (defined $key and /^en\s+desc\s+(\S+(?: \S+)*)\s*$/) {
      $Data->{eras}->{$key}->{en_desc} = $1;
    } elsif (defined $key and /^tag\s+(\S.*\S)\s*$/) {
      my $tkey = $1;
      set_tag $key => $tkey;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  for my $era (values %{$Data->{eras}}) {
    if (defined $era->{offset}) {
      for (@{$era->{_usages} or []}) {
        my $y = $era->{offset} + $_->[0]->[0];
        $era->{known_oldest_year} = $y if
            not defined $era->{known_oldest_year} or
            $era->{known_oldest_year} > $y;
        $era->{known_latest_year} = $y if
            not defined $era->{known_latest_year} or
            $era->{known_latest_year} < $y;
      }
    }
    delete $era->{_usages};
    if (not defined $era->{known_oldest_year} and
        defined $era->{offset}) {
      $era->{known_oldest_year} = $era->{offset} + 1;
    }
    if (defined $era->{known_oldest_year} and
        not defined $era->{known_latest_year}) {
      $era->{known_latest_year} = $era->{known_oldest_year};
    }
  } # $era
}

## Name shorthands
{
  for my $era (values %{$Data->{eras}}) {
    for my $label_set (@{$era->{label_sets}}) {
    for my $label (@{$label_set->{labels}}) {
      for my $label (@{$label->{reps}}) {
        if ($label->{name}) {
          if ($label->{han}) {
            for my $value (@{$label->{values}}) {
              $era->{names}->{$value->{value}} = 1;
              $era->{name} //= $value->{value};
              $era->{name_ja} //= $value->{value} if $value->{ja};
              $era->{name_tw} //= $value->{value} if $value->{tw};
              $era->{name_cn} //= $value->{value} if $value->{cn};
              $era->{name_ja} = $value->{value} if $value->{ja} and $value->{_preferred};
              $era->{name_tw} = $value->{value} if $value->{tw} and $value->{_preferred};
              $era->{name_cn} = $value->{value} if $value->{cn} and $value->{_preferred};
              delete $value->{_preferred};
            } # $value
          }
          if ($label->{ko}) {
            $era->{name} //= $label->{value};
            $era->{name_ko} //= $label->{value};
            $era->{name_ko} = $label->{value} if $label->{_preferred};
          }
          if ($label->{vi}) {
            $era->{name} //= $label->{value};
            $era->{name_vi} //= $label->{value};
            $era->{name_vi} = $label->{value} if $label->{_preferred};
          }
          if ($label->{alphabetical}) {
            $era->{name} //= $label->{dotless} // $label->{value};
            if ($label->{en}) {
              if (defined $label->{value}) {
                $era->{name_en} //= $label->{value};
                $era->{name_en} = $label->{value} if $label->{_preferred};
              }
            }
          }
        } # name
        if ($label->{abbr}) {
          if ($label->{han} and $label->{abbr} eq 'first') {
            $era->{abbr} //= $label->{values}->[0]->{value};
            $era->{names}->{$label->{values}->[0]->{value}} = 1;
          }
          if ($label->{ja} and $label->{abbr} eq 'first' and
              length $label->{latin} == 1) {
            $era->{abbr_latn} //= $label->{latin};
          }
        }
        delete $label->{_preferred};
      } # $label
    } # $label_set
    } # $label_set0

    $era->{ja_readings} = [map { my $v = {%$_}; delete $v->{yomi}; $v } grep { $_->{yomi} } map { @{$_->{reps}} } map { @{$_->{labels}} } @{$era->{label_sets}}];
    delete $era->{ja_readings} unless @{$era->{ja_readings}};
    for my $v (@{$era->{ja_readings} or []}) {
      $era->{name_latn} //= $v->{latin} if defined $v->{latin};
      $era->{name_kana} //= $v->{kana};
      $era->{name_kana} =~ s/ //g;
      for (grep { length }
                 $v->{kana} // '',
                 $v->{kana_modern} // '',
                 $v->{kana_classic} // '',
                 @{$v->{kana_others} or []}) {
        my $v = $_;
        $v =~ s/ //g;
        $era->{name_kanas}->{$v} = 1;
      }
    } # $v
    my $w = $era->{name_latn};
    if (defined $w) {
      $w =~ s/ //g;
      $w = ucfirst $w;
      $era->{name_latn} = $w;
    }

    $era->{name_kanas}->{$era->{name_kana}} = 1 if defined $era->{name_kana};
  } # $era
}

{
  my $path = $root_path->child ('src/era-codes-14.txt');
  my $i = 1;
  for (grep { length } split /\x0D?\x0A/, $path->slurp_utf8) {
    ($Data->{eras}->{$_} or die "Era |$_| not found")->{code14} = $i;
    $i++;
  }
}
{
  my $path = $root_path->child ('src/era-codes-15.txt');
  my $i = 1;
  for (grep { length } split /\x0D?\x0A/, $path->slurp_utf8) {
    ($Data->{eras}->{$_} or die "Era |$_| not found")->{code15} = $i;
    $i++;
  }
}
{
  my $path = $root_path->child ('local/cldr-core-json/ja.json');
  my $json = json_bytes2perl $path->slurp;
  for my $i (0..$#{$json->{"dates_calendar_japanese_era"}}) {
    my $v = $json->{"dates_calendar_japanese_era"}->[$i];
    next unless defined $v;
    ($Data->{eras}->{$v} or die "Era |$v| not found")->{code10} = $i;
  }
}

{
  my $variants_path = $root_path->child ('local/char-variants.json');
  my $variants_json = json_bytes2perl $variants_path->slurp;
  my $Variants = $variants_json->{variants};
  my $Scores = {};
  for my $era (values %{$Data->{eras}}) {
    use utf8;
    if ($era->{tag_ids}->{$TagByKey->{'日本の私年号'}->{id}}) {
      $era->{jp_private_era} = 1;
    }
    $Scores->{$era->{key}} = 0;
    $Scores->{$era->{key}} += 50000
        if $era->{jp_era} or $era->{jp_emperor_era} or
           $era->{jp_north_era} or $era->{jp_south_era};
    $Scores->{$era->{key}} += 40000 if $era->{jp_private_era};
    $Scores->{$era->{key}} += 10000
        if defined $era->{name_cn};
    $Scores->{$era->{key}} += 10000 - $era->{offset} if defined $era->{offset};
  }
  my $Names = {};
  for my $era (sort {
    $Scores->{$b->{key}} <=> $Scores->{$a->{key}} ||
    $a->{key} cmp $b->{key};
  } values %{$Data->{eras}}) {
    my @all_name = keys %{$era->{names} or {}};
    my @new_name;
    for my $name (@all_name) {
      my @name = split //, $name;
      @name = map { [keys %$_] } map { $Variants->{$_} || {$_ => 1} } @name;
      my $current = [''];
      while (@name) {
        my $char = shift @name;
        my @next;
        for my $p (@$current) {
          for my $c (@$char) {
            push @next, $p.$c;
          }
        }
        $current = \@next;
      }
      push @new_name, @$current;
      push @new_name, uc $name;
      push @new_name, lc $name;
    }
    $era->{names}->{$_} = 1 for @new_name;
    for (sort { $a cmp $b } @all_name, @new_name) {
      $Names->{$_}->{$era->{key}} = 1;
      $Data->{name_to_key}->{jp}->{$_} //= $era->{key};
    }
  }

  for my $name (keys %$Names) {
    next unless 2 <= keys %{$Names->{$name}};
    $Data->{name_conflicts}->{$name} = $Names->{$name};
  }
}

{
  my $path = $root_path->child ('local/number-values.json');
  my $json = json_bytes2perl $path->slurp;
  my $is_number = {};
  for (keys %$json) {
    if (defined $json->{$_}->{cjk_numeral}) {
      $is_number->{$_} = 1;
    }
  }
  my $path2 = $root_path->child ('data/numbers/kanshi.json');
  my $json2 = json_bytes2perl $path2->slurp;
  for (split //, $json2->{name_lists}->{kanshi}) {
    $is_number->{$_} = 1 unless $_ eq ' ';
  }
  $is_number->{$_} = 1 for qw(元 正 𠙺 端 冬 臘 腊 初 𡔈 末 前 中 後 建 閏); # 元年, 正月, 初七日, 初年, 初期, 前半, ...
  $is_number->{$_} = 1 for qw(年 𠡦 𠦚 載 𡕀 𠧋 歳 月 囝 日 𡆠 時 分 秒 世 紀 星 期 曜 旬 半 火 水 木 金 土);
  my $number_pattern = join '|', map { quotemeta $_ } keys %$is_number;
  for my $data (values %{$Data->{eras}}) {
    for (keys %{$data->{names}}) {
      while (/($number_pattern)/go) {
        $Data->{numbers_in_era_names}->{$1}->{$_} = 1;
      }
    }
  }
}

for my $data (values %{$Data->{eras}}) {
  for (keys %{$data->{names}}) {
    $Data->{name_to_keys}->{$_}->{$data->{key}} = 1;
  }
}

{
  my $path = $root_path->child ('intermediate/era-ids.json');
  my $map = json_bytes2perl $path->slurp;
  my @need_id;
  my $max_id = 0;
  for my $data (sort { $a->{key} cmp $b->{key} } values %{$Data->{eras}}) {
    my $id = $map->{$data->{key}};
    if (defined $id) {
      $data->{id} = $id;
      $max_id = $id if $max_id < $id;
    } else {
      #push @{$Data->{_errors} ||= []}, "ID for key |$data->{key}| not defined";
      push @need_id, $data;
    }
  }
  for (@need_id) {
    $map->{$_->{key}} = $_->{id} = ++$max_id;
  }
  $path->spew (perl2json_bytes_for_record $map) if @need_id;
}

$Data->{current_jp} = '令和';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
