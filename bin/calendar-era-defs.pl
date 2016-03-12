use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
binmode STDERR, qw(:encoding(utf-8));

my $root_path = path (__FILE__)->parent->parent;

my $Data = {};

for my $file_name (qw(
  era-defs-jp.json era-defs-jp-emperor.json
)) {
  my $path = $root_path->child ('local')->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    if (defined $Data->{eras}->{$key}) {
      die "Duplicate era key |$key|";
    }
    $Data->{eras}->{$key} = $json->{eras}->{$key};
  }
}

for my $file_name (qw(era-defs-dates.json)) {
  my $path = $root_path->child ('local')->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    my $data = $json->{eras}->{$key};
    for (keys %$data) {
      $Data->{eras}->{$key}->{$_} = $data->{$_};
    }
  }
}

{
  my $path = $root_path->child ('src/wp-jp-eras-en.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (values %{$Data->{eras}}) {
    next unless $data->{jp_era} or $data->{jp_north_era} or $data->{jp_south_era};
    my $en;
    if (defined $data->{start_year} and defined $data->{end_year}) {
      $en ||= $json->{$data->{start_year}, $data->{end_year}};
    }
    if (defined $data->{north_start_year} and defined $data->{north_end_year}) {
      $en ||= $json->{$data->{north_start_year}, $data->{north_end_year}};
    }
    if (defined $data->{south_start_year} and defined $data->{south_end_year}) {
      $en ||= $json->{$data->{south_start_year}, $data->{south_end_year}};
    }
    if (defined $data->{start_year} and not defined $data->{end_year}) {
      $en ||= $json->{$data->{start_year}, ''};
    }
    if ($data->{name} eq '宝亀') {
      $en ||= $json->{770, 781};
    }
    if ($data->{name} eq '永延') {
      $en ||= $json->{987, 988};
    }
    if ($data->{name} eq '永祚') {
      $en ||= $json->{988, 990};
    }
    if ($data->{name} eq '文亀') {
      $en ||= $json->{1501, 1521};
    }
    if (defined $en) {
      $data->{name_latn} = $en->{name};
      $data->{wref_en} = $en->{wref_en} if defined $en->{wref_en};
    } else {
      warn "Era |$data->{name}| not defined in English Wikipedia";
    }
  }
}

my $Variants = {};
{
  my $path = $root_path->child ('src/char-variants.txt');
  for (split /\n/, $path->slurp_utf8) {
    my @char = split /\s+/, $_;
    @char = map { s/^j://; $_ } @char;
    for my $c1 (@char) {
      for my $c2 (@char) {
        $Variants->{$c1}->{$c2} = 1;
      }
    }
  }
}

sub drop_kanshi ($) {
  my $name = shift;
  $name =~ s/\(\w+\)$//;
  return $name;
} # drop_kanshi

sub expand_name ($$) {
  my ($era, $name) = @_;
  $era->{names}->{drop_kanshi $name} = 1;
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
  for (@$current) {
    if (/^(.+?)\(\w+\)$/) {
      $era->{names}->{$1} = 1;
    } else {
      $era->{names}->{$_} = 1;
    }
  }
  my @all = @$current;
  for my $name (@$current) {
    if ($name =~ s/摂政$//) {
      $era->{names}->{$name} = 1,
      push @all, $name
          if length $name;
    }
    if ($name =~ s/天皇$//) {
      $era->{names}->{$name} = 1,
      push @all, $name
          if length $name;
    }
  }

  for (@all) {
    if (/^(.+)\(\w+\)$/) {
      $Data->{name_conflicts}->{$1}->{$era->{key}} = 1;
    } elsif (defined $Data->{name_to_key}->{jp}->{$_} and
             not $Data->{name_to_key}->{jp}->{$_} eq $era->{key}) {
      #warn "Duplicate era |$_| (|$era->{key}| vs |$Data->{name_to_key}->{jp}->{$_}|)";
    } else {
      $Data->{name_to_key}->{jp}->{$_} = $era->{key};
    }
  }
} # expand_name

$Data->{eras}->{$_}->{abbr} = substr $_, 0, 1
    for qw(慶応 明治 大正 昭和 平成);
$Data->{eras}->{明治}->{abbr_latn} = 'M';
$Data->{eras}->{大正}->{abbr_latn} = 'T';
$Data->{eras}->{昭和}->{abbr_latn} = 'S';
$Data->{eras}->{平成}->{abbr_latn} = 'H';
$Data->{eras}->{明治}->{names}->{'㍾'} = 1;
$Data->{eras}->{大正}->{names}->{'㍽'} = 1;
$Data->{eras}->{昭和}->{names}->{'㍼'} = 1;
$Data->{eras}->{平成}->{names}->{'㍻'} = 1;
expand_name $Data->{eras}->{明治}, '㍾';
expand_name $Data->{eras}->{大正}, '㍽';
expand_name $Data->{eras}->{昭和}, '㍼';
expand_name $Data->{eras}->{平成}, '㍻';

for my $era (values %{$Data->{eras}}) {
  my $name = $era->{name};
  expand_name $era, $name;
  $era->{short_name} = $name;
  $name =~ s/摂政$//;
  $era->{names}->{$name} = 1 if length $name;
  $era->{short_name} = $name if length $name;
  $name =~ s/天皇$//;
  $era->{names}->{$name} = 1 if length $name;
  $era->{short_name} = $name if length $name;
  if ($name ne $era->{name}) {
    expand_name $era, $name;
  }
  $era->{names}->{$era->{abbr}} = 1, expand_name $era, $era->{abbr}
      if defined $era->{abbr};
  $era->{names}->{$era->{abbr_latn}} = 1, expand_name $era, $era->{abbr_latn}
      if defined $era->{abbr_latn};
  $era->{names}->{lc $era->{abbr_latn}} = 1, expand_name $era, lc $era->{abbr_latn}
      if defined $era->{abbr_latn};
}

{
  my $path = $root_path->child ('src/era-yomi.txt');
  my $key;
  my $prop;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)\s+(\S+)$/) {
      die "Bad key |$1|" unless $Data->{eras}->{$1};
      $Data->{eras}->{$1}->{name_kanas}->{$2} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $root_path->child ('src/jp-private-eras.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)(?:\s+(BC|)(\d+)|)$/) {
      my $first_year = defined $3 ? $2 ? 1 - $3 : $3 : undef;
      my @name = split /,/, $1;
      my @n;
      for (@name) {
        if (defined $Data->{name_to_key}->{jp}->{$_}) {
          warn "Duplicate era |$_|";
        } else {
          push @n, $_;
        }
      }
      next unless @n;
      my $d = $Data->{eras}->{$n[0]} ||= {};
      $d->{jp_private_era} = 1;
      $d->{key} = $n[0];
      $d->{name_ja} = $d->{name} = drop_kanshi $n[0];
      $d->{names}->{drop_kanshi $_} = 1 for @n;
      expand_name $d, $_ for @n;
      if (defined $first_year) {
        $d->{offset} = $first_year - 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

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
    next if $src->{name} eq '宣統' and $src->{offset} == 1916;
    next if $src->{name} eq '明德' and not defined $src->{offset};
    next if $src->{name} eq '廣德' and not defined $src->{offset};
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
    $data->{name} = $src->{name};
    $data->{name_cn} = $src->{name_cn};
    $data->{name_tw} = $src->{name};
    $data->{names}->{$src->{name}} = 1;
    $data->{names}->{$src->{name_cn}} = 1;
    $data->{offset} = $src->{offset} if defined $src->{offset};
    $data->{wref_zh} = $src->{wref} if defined $src->{wref};
    expand_name $data, $src->{name};
    expand_name $data, $src->{name_cn};
  }

  warn $_ for @dup;
}

for my $path (
  $root_path->child ('src/era-tw.txt'),
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
      $d->{name} = drop_kanshi $n[0];
      $d->{names}->{drop_kanshi $_} = 1 for @n;
      expand_name $d, $_ for @n;
      if (defined $first_year) {
        $d->{offset} = $first_year - 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
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
      $Data->{eras}->{$key}->{names}->{drop_kanshi $variant} = 1;
      expand_name $Data->{eras}->{$key}, $variant;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $root_path->child ('src/era-data.txt');
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
      die "Bad key |$key|" if $Data->{eras}->{$key};
      undef $prop;
      $Data->{eras}->{$key}->{key} = $1;
    } elsif (defined $key and /^(source)$/) {
      push @{$Data->{eras}->{$key}->{sources} ||= []}, $prop = {};
    } elsif (defined $prop and ref $prop eq 'HASH' and
             /^  (title|url):(.+)$/) {
      $prop->{$1} = $2;
    } elsif (defined $key and /^(wref_(?:ja|zh|en|ko))\s+(.+)$/) {
      $Data->{eras}->{$key}->{$1} = $2;
    } elsif (defined $key and /^(name)\s*:=\s*(\S+)$/) {
      $Data->{eras}->{$key}->{$1} = $2;
      $Data->{eras}->{$key}->{names}->{$2} = 1;
      expand_name $Data->{eras}->{$key}, $2;
    } elsif (defined $key and /^(name(?:_ja|_en|_cn|_tw|_ko|_vi|_kana|)|abbr)\s+(.+)$/) {
      $Data->{eras}->{$key}->{$1} ||= $2;
      $Data->{eras}->{$key}->{$1} = $2 unless $1 eq 'name';
      $Data->{eras}->{$key}->{name} ||= $2 unless $1 eq 'name';
      $Data->{eras}->{$key}->{names}->{$2} = 1;
      $Data->{eras}->{$key}->{name_kanas}->{$2} = 1 if $1 eq 'name_kana';
      expand_name $Data->{eras}->{$key}, $2;
    } elsif (defined $key and /^(AD|BC)(\d+)\s*=\s*(\d+)$/) {
      my $g_year = $1 eq 'BC' ? 0 - $2 : $2;
      my $e_year = $3;
      $Data->{eras}->{$key}->{offset} = $g_year - $e_year;
    } elsif (defined $key and /^(sw)\s+(.+)$/) {
      $Data->{eras}->{$key}->{suikawiki} = $2;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $root_path->child ('data/calendar/era-systems.json');
  my $json = json_bytes2perl $path->slurp;
  for (@{$json->{systems}->{ryuukyuu}->{points}}) {
    my $key = $_->[2];
    my $def = $Data->{eras}->{$key} or die "Era |$key| not defined";
    if ($def->{jp_era} or $def->{jp_north_era} or $def->{jp_south_era} or
        $def->{jp_emperor_era}) {
      #
    } elsif ($key eq 'AD') {
      #
    } else {
      $def->{cn_ryuukyuu_era} = 1;
    }
  }
}

for my $name (keys %{$Data->{name_conflicts}}) {
  if (defined $Data->{name_to_key}->{jp}->{$name}) {
    $Data->{name_conflicts}->{$name}->{$Data->{name_to_key}->{jp}->{$name}} = 1;
  } else {
    warn "Era name |$name| not defined";
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

$Data->{current_jp} = '平成';

print perl2json_bytes_for_record $Data;

## License: Public Domain.