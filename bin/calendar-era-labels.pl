use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::Encoding;
use Web::Encoding::Normalization qw(to_nfd);

my $Data = {};
my $RootPath = path (__FILE__)->parent->parent;

my $Eras;
my $EraById;
warn "Loading...\n";
{
  my $path = $RootPath->child ('local/calendar-era-defs-0.json');
  my $json = json_bytes2perl $path->slurp;
  $Eras = [sort { $a->{id} <=> $b->{id} } values %{$json->{eras}}];
  for my $era (@$Eras) {
    $EraById->{$era->{id}} = $era;
  }
}
warn "Loaded\n";

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


{

  sub serialize_segmented_text ($) {
    my $st = shift;
    die $st, Carp::longmess () if not ref $st or not ref $st eq 'ARRAY';
    return join '', map {
      if (ref $_) {
        join '', map {
          if (/^:/) {
            return undef; # not serializable
          } else {
            $_;
          }
        } @$_;
      } elsif (/^\./) {
        use utf8;
        {
          '._' => ' ',
          '.・' => '',
          '..' => '',
          ".'" => "'",
          '.-' => '-',
        }->{$_} // die "Bad segment separator |$_|";
      } else {
        $_;
      }
    } @$st;
  } # serialize_segmented_text

  sub serialize_segmented_text_for_key ($) {
    my $st = shift;
    return join '', map {
      if (ref $_) {
        '['.(join '', map {
          '['.$_.']';
        } @$_).']';
      } else {
        if (/^\./) {
          '[['.$_.']]';
        } else {
          '['.(join '', map { "[$_]" } split //, $_).']';
        }
      }
    } @$st;
  } # serialize_segmented_text_for_key

  sub for_segment (&$) {
    my ($code, $ss) = @_;
    my $i = 0;
    for (@$ss) {
      if (ref $_) {
        local $_ = join '', @$_;
        $code->($i++);
      } elsif (/^\./) {
        #
      } else {
        $code->($i++); # $_
      }
    }
  } # for_segment

  sub segmented_string_length ($) {
    my $ss = shift;
    my $i = 0;
    for_segment {
      $i++;
    } $ss;
    return $i;
  } # segmented_string_length
  
  sub equal_segmented_string ($$) {
    my ($ss1, $ss2) = @_;
    return (
      (serialize_segmented_text_for_key $ss1)
          eq
      (serialize_segmented_text_for_key $ss2)
    );
  } # equal_segmented_string

  sub transform_segmented_string ($$) {
    my ($ss, $code) = @_;
    
    my $tt = [];
    for (@$ss) {
      if (ref $_) {
        push @$tt, [map {
          if (/^\:/) {
            $_;
          } else {
            $code->($_);
          }
        } @$_];
      } elsif (/^\./) {
        push @$tt, $_;
      } else {
        push @$tt, $code->($_);
      }
    }
    
    return $tt;
  } # transform_segmented_string

  sub transform_segmented_string_first ($$) {
    my ($ss, $code) = @_;
    
    my $tt = [];
    my $is_first = 1;
    for (@$ss) {
      if (ref $_) {
        push @$tt, [map {
          if (/^\:/) {
            $is_first = 0;
            $_;
          } else {
            if ($is_first) {
              $is_first = 0;
              $code->($_);
            } else {
              $_;
            }
          }
        } @$_];
      } elsif (/^\./) {
        push @$tt, $_;
        if ($_ eq '..' or $_ eq '._' or $_ eq '.-') {
          $is_first = 1;
        }
      } else {
        if ($is_first) {
          push @$tt, my $t = [split //, $_];
          $t->[0] = $code->($t->[0]);
          $is_first = 0;
        } else {
          push @$tt, $_;
        }
      }
    }
    
    return $tt;
  } # transform_segmented_string_first
}

my $LeaderKeys = [];
{
  my $Leaders = {};

  my $rpath = $RootPath->child ("local/cluster-root.json");
  my $root = json_bytes2perl $rpath->slurp;
  my $x = [];
  $x->[0] = 'all';
  for (values %{$root->{leader_types}}) {
    $x->[$_->{index}] = $_->{key};
    push @$LeaderKeys, $_->{key};
  }
  
  my $path = $RootPath->child ("local/char-leaders.jsonl");
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    my $json = json_bytes2perl $_;
    my $r = {};
    for (0..$#$x) {
      $r->{$x->[$_]} = $json->[1]->[$_]; # or undef
    }
    $Leaders->{$json->[0]} = $r;
  }

  sub han_normalize ($) {
    my ($s) = @_;
    my $r = '';
    while ($s =~ s/^(\w[\x{FE00}-\x{FE0F}\x{E0100}-\x{E01EF}]?|.)//) {
      my $c = $1;
      my $l = $Leaders->{$c};
      if (defined $l and defined $l->{all}) {
        $r .= $l->{all};
      } else {
        $r .= $c;
      }
    }
    return $r;
  } # han_normalize

  sub segmented_text_to_han_variants ($) {
    my $ss = shift;

    my @r;
    for (@$ss) {
      for (ref $_ ? @$_ : split //, $_) {
        my $v = to_han_variants $_;
        return undef unless defined $v;
        warn "<$_> => @$v";
        push @r, $v;
      }
    }

    return \@r;
  } # segmented_text_to_han_variants

  sub is_same_han ($$) {
    my ($v, $w) = @_;
    return 0 unless @$v == @$w;
    my $r = 2;
    for (0..$#$v) {
      if ($v->[$_] eq $w->[$_]) {
        #
      } else {
        my $vv = $Leaders->{$v->[$_]}->{all} // $v->[$_];
        my $ww = $Leaders->{$w->[$_]}->{all} // $w->[$_];
        if ($vv eq $ww) {
          $r = 1;
        } else {
          return 0;
        }
      }
    }
    return $r;
    ## 0 not equal
    ## 1 equivalent but not same
    ## 2 same
  } # is_same_han

  sub fill_han_variants ($) {
    my $x = shift;
    my $w = $x->{jp} //
            $x->{tw} //
            $x->{cn} //
            $x->{kr} //
            $x->{others}->[0];

    my $has_value = {};
    LANG: for my $lang (@$LeaderKeys) {
      my $v = [map {
        if (ref $_) {
          [map {
            my $c = $Leaders->{$_}->{$lang};
            next LANG if not defined $c;
            $c;
          } @$_];
        } else {
          my $c = $Leaders->{$_}->{$lang};
          next LANG if not defined $c;
          if (1 == length $c) {
            $c;
          } else {
            [$c];
          }
        }
      } @$w];

      if (defined $v) {
        if (not defined $x->{$lang}) {
          $x->{$lang} = $v;
        } else {
          my $vs = serialize_segmented_text_for_key $v;
          my $xs = serialize_segmented_text_for_key $x->{$lang};
          unless ($vs eq $xs) {
            push @{$x->{others} ||= []}, $v;
            push @{$x->{_ERRORS} ||= []}, "$lang=$xs ($vs expected)";
          }
        }
      }

      $has_value->{serialize_segmented_text_for_key $x->{$lang}} = 1
          if defined $x->{$lang};
    }
    $x->{others} = [grep {
      my $v = serialize_segmented_text_for_key $_;
      if ($has_value->{$v}) {
        0;
      } else {
        $has_value->{$v} = 1;
        1;
      }
    } @{$x->{others} or []}];
    delete $x->{others} unless @{$x->{others}};
  } # fill_han_variants
}

{
  use utf8;
  my $ToLatin = {qw(
    あ a い i う u え e お o
    か ka き ki く ku け ke こ ko
    さ sa し shi す su せ se そ so
    た ta ち chi つ tsu て te と to
    な na に ni ぬ nu ね ne の no
    は ha ひ hi ふ fu へ he ほ ho
    ま ma み mi む mu め me も mo
    や ya ゆ yu よ yo
    ら ra り ri る ru れ re ろ ro
    わ wa ん n
    が ga ぎ gi ぐ gu げ ge ご go
    ざ za じ ji ず zu ぜ ze ぞ zo
    だ da で de ど do
    ば ba び bi ぶ bu べ be ぼ bo
    ぱ pa ぴ pi ぷ pu ぺ pe ぽ po
    きゃ kya きゅ kyu きょ kyo
    しゃ sha しゅ shu しょ sho
    ちゃ cha ちゅ chu ちょ cho
    にゃ nya にゅ nyu にょ nyo
    ひゃ hya ひゅ hyu ひょ hyo
    みゃ mya みゅ myu みょ myo
    りゃ rya りゅ ryu りょ ryo
    ぎゃ gya ぎゅ gyu ぎょ gyo
    じゃ ja じゅ ju じょ jo
    びゃ bya びゅ byu びょ byo
    ぴゃ pya ぴゅ pyu ぴょ pyo

    ちぇ che
  )};
  sub romaji ($) {
    my $s = shift;
    $s =~ s/([きしちにひみりぎじびぴ][ゃゅょぇ])/$ToLatin->{$1}/g;
    $s =~ s/([あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわんがぎぐげござじずぜぞだでどばびぶべぼぱぴぷぺぽ])/$ToLatin->{$1}/g;
    #$s =~ s/^(\S+ \S+) (\S+ \S+)$/$1 - $2/g;
    $s =~ s/ (ten nou|ki [gn]en)$/ - $1/g;
    $s =~ s/ (kou gou) (seっ shou)$/ - $1 - $2/g;
    $s =~ s/^(\S+) (\S+) (reki)$/$1 $2 - $3/g;
    $s =~ s/n ([aiueoyn])/n ' $1/g;
    $s =~ s/っ ([ksthyrwgzdbp])/$1 $1/g;
    $s =~ s{([aiueo])ー}{
      {a => "\x{0101}", i => "\x{012B}", u => "\x{016B}",
       e => "\x{0113}", o => "\x{014D}"}->{$1};
    }ge;
    #$s =~ s/ //g;
    die $s if $s =~ /\p{Hiragana}/;
    #return ucfirst $s;
    return $s;
  }

  sub romaji2 ($) {
    #my $s = lcfirst romaji $_[0];
    my $s = romaji $_[0];
    $s =~ s/ou/\x{014D}/g;
    $s =~ s/uu/\x{016B}/g;
    #$s =~ s/ii/\x{012B}/g;
    #return ucfirst $s;
    return $s;
  }

  sub romaji_variants (@) {
    my @s = @_;
    my $found = {};
    $found->{$_} = 1 for @s;
    my @r = @s;
    for (@s) {
      {
        my $s = $_;
        $s =~ s/n( ?[mpb])/m$1/g;
        push @r, $s;

        $s =~ s/m m([aiueo\x{0101}\x{016B}\x{016B}\x{0113}\x{014D}y])/m ' m$1/g;
        push @r, $s;
      }
      {
        my $s = $_;
        $s =~ s/n ' n/n n/g;
        push @r, $s;
      }
    }
    {
      my @t = @r;
      for (@t) {
        my $s = $_;
        $s =~ s/m( ?)(?:' |)([mpb])/n$1$2/g;
        $s =~ s/sh([i\x{012B}])/s$1/g;
        $s =~ s/ch([i\x{012B}])/t$1/g;
        $s =~ s/j([i\x{012B}])/z$1/g;
        $s =~ s/ts([u\x{016B}])/t$1/g;
        $s =~ s/sh([aueo\x{0101}\x{016B}\x{0113}\x{014D}])/sy$1/g;
        $s =~ s/ch([aueo\x{0101}\x{016B}\x{0113}\x{014D}])/ty$1/g;
        $s =~ s/j([aueo\x{0101}\x{016B}\x{0113}\x{014D}])/jy$1/g;
        push @r, $s;
        $s =~ s/jy([aueo\x{0101}\x{016B}\x{0113}\x{014D}])/zy$1/g;
        push @r, $s;
      }
    }
    return [grep { not $found->{$_}++ } sort { $a cmp $b } @r];
  } # romaji_variants

  sub to_hiragana ($) {
    use utf8;
    my $s = shift;
    $s =~ tr/アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォッャュョヮ𛀄𛃚𛁩/あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎあもつ/;
    return $s;
  } # to_hiragana

  sub to_katakana ($) {
    use utf8;
    my $s = shift;
    $s =~ tr/あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎ𛀄𛃚𛁩/アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォッャュョヮアモツ/;
    return $s;
  } # to_katakana

sub to_contemporary_kana ($) {
  use utf8;
  my $s = shift;
  $s =~ s/く[わゎ]/か/g;
  $s =~ s/ぐ[わゎ]/が/g;
  $s =~ s/ぢ/じ/g;
  $s =~ s/ゐ/い/g;
  $s =~ s/ゑ/え/g;
  $s =~ s/を/お/g;
  $s =~ s/かう/こう/g;
  $s =~ s/たう/とう/g;
  $s =~ s/はう/ほう/g;
  $s =~ s/ばう/ぼう/g;
  $s =~ s/やう/よう/g;
  $s =~ s/わう/おう/g;
  $s =~ s/ゃう/ょう/g;
  $s =~ s/ちよう/ちょう/g;
  $s =~ s/らう/ろう/g;
  $s =~ s/きう/きゅう/g;
  $s =~ s/ぎう/ぎゅう/g;
  $s =~ s/しう/しゅう/g;
  $s =~ s/ちう/ちゅう/g;
  $s =~ s/いう/ゆう/g;
  $s =~ s/しゆ/しゅ/g;
  $s =~ s/じゆ/じゅ/g;
  $s =~ s/きよ/きょ/g;
  $s =~ s/しよ/しょ/g;
  $s =~ s/じよ/じょ/g;
  $s =~ s/によ/にょ/g;
  $s =~ s/せう/しょう/g;
  $s =~ s/てう/ちょう/g;
  $s =~ s/しよう/しょう/g;
  $s =~ s/む$/ん/g;
  return $s;
} # to_contemporary_kana

{
  use utf8;
  my $Ons = {};

sub compute_ons_eqs ($) {
  my $ons = shift;
  {
    my $kk = join $;, sort { $a cmp $b } keys %{$ons->{kans}};
    my $gg = join $;, sort { $a cmp $b } keys %{$ons->{gos}};
    $ons->{kan_eq_go} = 1 if $kk eq $gg;
  }
  {
    my $kk = join $;, sort { $a cmp $b } keys %{$ons->{kan_cs}};
    my $gg = join $;, sort { $a cmp $b } keys %{$ons->{go_cs}};
    $ons->{kan_c_eq_go_c} = 1 if $kk eq $gg;
  }
} # compute_ons_eqs

sub merge_onses ($$) {
  my ($ons1, $ons2) = @_;
  my $new = {};
  for my $key (qw(kans gos kan_cs go_cs)) {
    for (keys %{$ons1->{$key}}) {
      $new->{$key}->{$_} = 1;
    }
    for (keys %{$ons2->{$key}}) {
      $new->{$key}->{$_} = 1;
    }
  }
  compute_ons_eqs $new;
  return $new;
} # merge_onses

  my $path = $RootPath->child ('intermediate/kanjion-binran.txt');
  my $text = decode_web_utf8 $path->slurp;
  for (split /\x0D?\x0A/, $text) {
    if (/^#/) {
    } elsif (/^(\S+)\t(\S+)\t(\S+)$/) {
      my $c = $1;
      my $kans = $2;
      my $gos = $3;
      my $cc = han_normalize $c;
      $kans = [split /,/, $kans];
      $gos = [split /,/, $gos];

      for my $v (@$kans) {
        $Ons->{$cc}->{kans}->{$v} = 1;
        my $v_c = to_contemporary_kana $v;
        $Ons->{$cc}->{kan_cs}->{$v_c} = 1;
      }
      for my $v (@$gos) {
        $Ons->{$cc}->{gos}->{$v} = 1;
        my $v_c = to_contemporary_kana $v;
        $Ons->{$cc}->{go_cs}->{$v_c} = 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
  for my $ons (values %$Ons) {
    compute_ons_eqs ($ons);
  }

  sub kanji_ons ($) {
    my $c = shift;
    my $cc = han_normalize $c;
    my $d = $Ons->{$cc};
    unless (defined $d) {
      use utf8;
      my $map = {
        強 => '强',
        万 => '萬',
        体 => '體',
        禄 => '祿',
        豊 => '豐',
      };
      my $mapped = $map->{$cc};
      if (defined $mapped) {
        my $dd = han_normalize $mapped;
        $d = $Ons->{$dd};
      }
    }
    return $d; # or undef
  } # kanji_ons
}

sub compute_form_group_ons ($) {
  my $fg = shift;

  my $fg_data = {};
  
  my $onses = $fg_data->{onses} = [];
  my $no_chars = [];
  for my $fs (@{$fg->{form_sets}}) {
    if ($fs->{form_set_type} eq 'hanzi') {
      my $ss = $fs->{jp} // $fs->{tw} // $fs->{kr} // $fs->{hk} // $fs->{cn} // $fs->{others}->[0] // [];
      my $fs_data = {};
      $fs_data->{chars} = [];
      my $fs_onses = $fs_data->{onses} = [];
      for_segment {
        push @{$fs_data->{chars}}, $_;
        my $ons = kanji_ons $_;
        if (defined $ons) {
          $fs_onses->[$_[0]] = $ons;
          if (defined $onses->[$_[0]]) {
            $onses->[$_[0]] = merge_onses $ons, $onses->[$_[0]];
          } else {
            $onses->[$_[0]] = $ons;
          }
        } else {
          push @$no_chars, $_;
          $onses->[$_[0]] //= undef;
        }
      } $ss;
      push @{$fg_data->{hanzis} ||= []}, $fs_data;
    } elsif ($fs->{form_set_type} eq 'yomi') {
      my $fs_data = {};
      my $counts = $fs_data->{counts} = [];
      $fs_data->{fields} = [];
      my $process_yomi = sub {
        my $fs_key = shift;
        my $kanas = [];
        for_segment {
          my $ons = $onses->[$_[0]];
          push @$kanas, $_;
          for my $key (qw(kans gos kan_cs go_cs)) {
            $counts->[$_[0]]->{$key}++
                if defined $ons and $ons->{$key}->{$_};
            $counts->[$_[0]]->{$key}++
                if $key =~ /_cs$/ and
                    defined $ons and 
                    not $ons->{$key}->{$_} and
                    $ons->{$key}->{to_contemporary_kana $_};
          }
        } shift;
        push @{$fs_data->{fields}}, [$fs_key, $kanas];
      }; # $process_yomi
      if (defined $fs->{hiragana_modern}) {
        $process_yomi->('hiragana_modern', $fs->{hiragana_modern});
      }
      if (defined $fs->{hiragana_classic}) {
        $process_yomi->('hiragana_classic', $fs->{hiragana_classic});
      }
      for (@{$fs->{hiragana_others} or []}) {
        $process_yomi->('hiragana_others', $_);
      }
      for (@{$fs->{hiragana_wrongs} or []}) {
        $process_yomi->('hiragana_wrongs', $_);
      }

      $fs->{on_types} = $fs_data->{types} = [];
      for (0..$#$onses) {
        my $count = $counts->[$_];
        my $ons = $onses->[$_];
        if ($count->{kan_cs} and $count->{go_cs}) {
          $fs_data->{types}->[$_] = 'KG';
        } elsif (($count->{kans} or $count->{kan_cs}) and
                 not $count->{gos} and not $count->{go_cs}) {
          $fs_data->{types}->[$_] = 'K';
        } elsif (($count->{gos} or $count->{go_cs}) and
                 not $count->{kans} and not $count->{kan_cs}) {
          $fs_data->{types}->[$_] = 'G';
        } else {
          $fs_data->{types}->[$_] = undef;
        }
      }

      push @{$fg_data->{yomis} ||= []}, $fs_data;
    }
  } # $fs

  if (@{$fg_data->{yomis} or []}) {
    $Data->{_ONS}->{_errors}->{not_found_chars}->{$_} = 1 for @$no_chars;
    return $fg_data;
  } else {
    return undef;
  }
} # compute_form_group_ons

  sub to_italic ($) {
    my $s = shift;
    no warnings; # warning for tr is broken in some versions of perl
    $s =~ tr/A-Za-z/\x{1D434}-\x{1D454}\x{210E}\x{1D456}-\x{1D467}/;
    return $s;
  } # to_italic

  sub to_uc ($) {
    my $s = shift;
    $s = uc $s;
    no warnings; # warning for tr is broken in some versions of perl
    $s =~ tr/\x{1D44E}-\x{1D454}\x{210E}\x{1D456}-\x{1D467}/\x{1D434}-\x{1D44D}/;
    return $s;
  } # to_uc
  
  sub to_lc ($) {
    my $s = shift;
    $s = lc $s;
    $s =~ tr/\x{1D434}-\x{1D44D}/\x{1D44E}-\x{1D454}\x{210E}\x{1D456}-\x{1D467}/;
    return $s;
  } # to_lc

  my $FukuiMap = {};
  for (0x00..0x12) {
    $FukuiMap->{chr (0x1100 + $_)} = qw(
      g gg n d dd r m b bb s ss ' j jj c k
      t p h
    )[$_];
  }
  for (0x61..0x75) {
    $FukuiMap->{chr (0x1100 + $_)} = qw(
        a ai ia iai e ei ie iei o oa oai oi io u ue
      uei ui iu y yi i
    )[$_ - 0x61];
  }
  $FukuiMap->{"\x{119E}"} = '@';
  for (0xA8..0xC2) {
    $FukuiMap->{chr (0x1100 + $_)} = qw(
                    g gg gs n nj nh d r
      rg rm rb rs rd rp rh m b bs s ss ' j c k
      t p h
    )[$_ - 0xA8];
  }
  $FukuiMap->{"\x{115F}"} = '';
  $FukuiMap->{"\x{1160}"} = '';
  sub to_fukui ($) {
    my $s = shift;

    $s = join '', map { $FukuiMap->{$_} // $_ } split //, to_nfd $s;
    while ($s =~ /([\x{1100}-\x{11FF}])/) {
      warn sprintf "Romaji for Korean jamo U+%04X not found", ord $1;
    }

    return $s;
  } # to_fukui

  sub to_zuyntn ($) {
    my $s = shift;

    $s =~ tr/ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙ/bpmfdtnlgkhjcşẑĉŝĵzçs/;
    # ㄧ y
    $s =~ tr/ㄧㄨㄩㄚㄛㄜㄝㄦ帀/iuüaôeêrï/;
    $s =~ tr/ㄢㄣㄤㄥㄞㄟㄠㄡ/ænãñâîåo/;
    
    $s =~ tr/ˉˊˇˋ˙/12345/;

    return $s;
  } # to_zuyntn

  sub fill_alphabetical ($) {
    my $fs = shift;

    if (defined $fs->{latin}) {
      $fs->{ja_latin_lower} //= $fs->{latin};

      my $has_value = {};
      $has_value->{serialize_segmented_text_for_key $fs->{latin}} = 1;
      for (
        $fs->{latin_normal}, $fs->{latin_macron},
        @{$fs->{latin_others} or []},
      ) {
        next unless defined $_;
        next if $has_value->{serialize_segmented_text_for_key $_}++;
        push @{$fs->{ja_latin_lower_others} ||= []}, $_;
      }
      delete $fs->{ja_latin_lower_others}
          unless @{$fs->{ja_latin_lower_others} or []};
    }
    die if @{$fs->{ja_latin_others} or []} and
           @{$fs->{ja_latin_lower_others} or []};

    if (defined $fs->{en_la}) {
      $fs->{en_la_roman} = $fs->{en_la};
      $fs->{en_la} = [map { to_italic $_ } @{$fs->{en_la}}];
    }
    
    for my $lang ('en',
                  'la', 'en_la', 'en_la_roman',
                  'it', 'fr', 'es', 'po',
                  'vi',
                  'nan_poj', 'pinyin',
                  'ja_latin', 'ja_latin_old') {
      if (defined $fs->{$lang}) {
        my $ss = $fs->{$lang};
        $fs->{$lang . '_lower'} //= transform_segmented_string $ss, sub { to_lc $_[0] };
        $fs->{$lang . '_upper'} //= transform_segmented_string $ss, sub { to_uc $_[0] };
        $fs->{$lang . '_capital'} //= transform_segmented_string_first $ss, sub { to_uc $_[0] };
      } elsif (defined $fs->{$lang . '_lower'}) {
        my $ss = $fs->{$lang . '_lower'};
        $fs->{$lang . '_capital'} //= transform_segmented_string_first $ss, sub { to_uc $_[0] };
        $fs->{$lang} //= $fs->{$lang . '_capital'};
        $fs->{$lang . '_upper'} //= transform_segmented_string $ss, sub { to_uc $_[0] };
      }
      if ($lang eq 'ja_latin_old') {
        if (equal_segmented_string $fs->{$lang}, $fs->{$lang . '_capital'}) {
          #
        } else {
          delete $fs->{$lang . '_capital'};
        }
      }

      die if $lang eq 'ja_latin_old' and @{$fs->{$lang . '_others'} or []};
      if (@{$fs->{$lang . '_others'} or []}) {
        for my $ss (@{$fs->{$lang . '_others'} or []}) {
          push @{$fs->{$lang . '_lower_others'} ||= []},
              transform_segmented_string $ss, sub { to_lc $_[0] };
          push @{$fs->{$lang . '_upper_others'} ||= []},
              transform_segmented_string $ss, sub { to_uc $_[0] };
          push @{$fs->{$lang . '_capital_others'} ||= []},
              transform_segmented_string_first $ss, sub { to_uc $_[0] };
        }
      } elsif (@{$fs->{$lang . '_lower_others'} or []}) {
        for my $ss (@{$fs->{$lang . '_lower_others'} or []}) {
          push @{$fs->{$lang . '_capital_others'} ||= []},
              my $cap = transform_segmented_string_first $ss, sub { to_uc $_[0] };
          push @{$fs->{$lang . '_others'} ||= []}, $cap;
          push @{$fs->{$lang . '_upper_others'} ||= []},
              transform_segmented_string $ss, sub { to_uc $_[0] };
        }
      }
    } # $lang

  } # fill_alphabetical

  sub fill_rep_yomi ($) {
    my $rep = shift;

    if (defined $rep->{kana_modern}) {
      my $ih = sub {
        if ($rep->{insert_22hyphen}) {
          my $s = shift;
          $s =~ s/^(\S+ \S+) (\S+ \S+)$/$1 - $2/g;
          return $s;
        } else {
          return $_[0];
        }
      };
      
      $rep->{kana} //= $rep->{kana_modern};
      $rep->{latin_normal} //= $ih->(romaji $rep->{kana_modern});
      $rep->{latin_macron} //= $ih->(romaji2 $rep->{kana_modern});
      $rep->{latin} //= $rep->{latin_macron};

      my $variants = romaji_variants $rep->{latin_normal}, $rep->{latin_macron};
      push @{$rep->{latin_others}}, @$variants;
    }
  } # fill_rep_yomi

  sub fill_yomi_from_rep ($$) {
    my ($rep => $v) = @_;

    $v->{hiragana} = [split / /,
                      $rep->{kana} //
                      $rep->{kana_modern} //
                      $rep->{kana_classic} //
                      $rep->{kana_others}->[0] // ''];
    delete $v->{hiragana} unless @{$v->{hiragana}};
    $v->{hiragana_modern} = [split / /, $rep->{kana_modern}]
        if defined $rep->{kana_modern};
    $v->{hiragana_classic} = [split / /, $rep->{kana_classic}]
        if defined $rep->{kana_classic};

    for (@{$rep->{kana_others} or []}) {
      push @{$v->{hiragana_others} ||= []}, [split / /, $_];
    }
    for (@{$rep->{kana_wrongs} or []}) {
      push @{$v->{hiragana_wrongs} ||= []}, [split / /, $_];
    }
    for (@{$rep->{hans} or []}) {
      push @{$v->{han_others} ||= []}, [split / /, to_hiragana $_];
    }
    for my $key (qw(hiragana_others hiragana_wrongs han_others)) {
      next unless defined $v->{$key};
      my $found = {};
      $v->{$key} = [map { $_->[0] } sort { $a->[1] cmp $b->[1] } grep {
        not $found->{$_->[1]}++;
      } map {
        [$_, serialize_segmented_text_for_key $_];
      } @{$v->{$key}}];
    }

    my $found = {};
    for (qw(latin latin_normal latin_macron)) {
      $v->{$_} = [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ } split /( (?:['-] |))/, $rep->{$_}]
          if defined $rep->{$_};
      $found->{serialize_segmented_text_for_key $v->{$_}} = 1
          if defined $v->{$_};
    }
    for (@{$rep->{latin_others} or []}) {
      push @{$v->{latin_others} ||= []},
          [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ } split /( (?:['-] |))/, $_];
    }
    if (defined $v->{latin_others}) {
      $v->{latin_others} = [map {
        $_->[0];
      } grep { not $found->{$_->[1]}++ } map {
        [$_, serialize_segmented_text_for_key $_];
      } @{$v->{latin_others}}];
    }

    fill_alphabetical $v;
  } # fill_yomi_from_rep

  sub fill_kana ($) {
    my $v = shift;
    use utf8;

    my $s = $v->{kana} // $v->{hiragana};
    $v->{hiragana} //= [map {
      to_hiragana $_;
    } @$s];
    $v->{katakana} //= [map {
      to_katakana $_;
    } @$s];

    if (not defined $v->{hiragana_classic}) {
      $v->{hiragana_modern} //= $v->{hiragana};
      $v->{katakana_modern} //= $v->{katakana};
    }

    $v->{katakana_classic} //= [map {
      if (ref $_) {
        map { to_katakana $_ } @$_;
      } else {
        to_katakana $_;
      }
    } @{$v->{hiragana_classic}}]
        if defined $v->{hiragana_classic};
    
    my $rep = {};
    $rep->{kana_modern} = join ' ', map {
      {'.・' => '._'}->{$_} // $_;
    } @{$v->{hiragana_modern}}
        if defined $v->{hiragana_modern};
    fill_rep_yomi $rep;

    my $found = {};
    for (qw(latin latin_normal latin_macron)) {
      $v->{$_} = [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ } split /( (?:['-] |))/, $rep->{$_}]
          if defined $rep->{$_};
      $found->{serialize_segmented_text_for_key $v->{$_}} = 1
          if defined $v->{$_};
    }
    for (@{$rep->{latin_others} or []}) {
      push @{$v->{latin_others} ||= []},
          grep { not $found->{serialize_segmented_text_for_key $_}++ }
          [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ }
           split /( (?:['-] |))/, $_];
    }

    fill_alphabetical $v;
  } # fill_kana

  sub fill_korean ($) {
    my $fs = shift;

    for my $lang (qw(kr kp ko)) {
      next unless defined $fs->{$lang};

      $fs->{$lang . '_fukui'} = [map { to_fukui $_ } @{$fs->{$lang}}];
    } # $lang
  } # fill_korean

  sub fill_chinese ($) {
    my $fs = shift;

    if (defined $fs->{bopomofo}) {
      $fs->{bopomofo_zuyntn} = [map { to_zuyntn $_ } @{$fs->{bopomofo}}];
    }

    fill_alphabetical $fs;
  } # fill_chinese
}

## Name shorthands
{
  use utf8;
  
  sub filter_labels ($) {
    my $labels = shift;
    return [grep { @{$_->{form_groups}} or @{$_->{expandeds} or []} } @$labels];
  } # filter_labels
  
  sub reps_to_labels ($$$);
  sub reps_to_labels ($$$) {
    my ($reps => $labels, $has_preferred) = @_;

    my $label = {form_groups => []};
    my $label_added = 0;
    if (@$labels) {
      $label = $labels->[-1];
      $label_added = 1;
    }

    for my $rep (@$reps) {
      if ($rep->{next_label}) {
        push @$labels, $label unless $label_added;
        $label = {form_groups => []};
        $label_added = 0;
        next;
      }
      
      my $value = {};
      my $value_added = 0;

      if (defined $rep->{kind}) {
        if ($rep->{kind} eq 'expanded') {
          if (@{$label->{form_groups}} and
              defined $label->{form_groups}->[-1]->{abbr}) {
            $value = $label->{form_groups}->[-1];
            $value_added = 1;
          }
          $rep->{kind} = '(expanded)';
          $value->{expandeds} ||= [];
          reps_to_labels [$rep] => $value->{expandeds}, {jp=>1,cn=>1,tw=>1};
        } else {
          my $v = {};
          my $v_added = 0;

          if ($rep->{type} eq 'han') {
            for (@{$label->{form_groups}}) {
              if ($_->{form_group_type} eq 'han') {
                $value = $_;
                $value_added = 1;
              } elsif ($_->{form_group_type} eq 'korean') {
                $value = $_;
                $value_added = 1;
                for my $v (@{$_->{form_sets}}) {
                  $v->{form_set_type} = 'korean';
                }
              } elsif ($_->{form_group_type} eq 'vi') {
                $value = $_;
                $value_added = 1;
              }
            }
            $value->{form_group_type} = 'han';
            $v->{form_set_type} = 'hanzi';
            
            my $w = [split //, $rep->{value}];
            for my $x (@{$value->{form_sets}}) {
              next unless $x->{form_set_type} eq 'hanzi';
              my $eq = is_same_han $w,
                      $x->{jp} //
                      $x->{tw} //
                      $x->{cn} //
                      $x->{kr} //
                      $x->{others}->[0];
              if ($eq == 2 and
                  (not defined $rep->{lang} or defined $x->{$rep->{lang}})) {
                $v_added = 1;
              } elsif ($eq) {
                $v = $x;
                $v_added = 1;
              }
            }

            my $lang = {
              ja => 'jp',
              ko => 'kr',
            }->{$rep->{lang} // ''} // $rep->{lang};
            if (defined $lang and
                not defined $v->{$lang}) {
              $v->{$lang} = $w;
              if ($lang eq 'jp' or $lang eq 'tw' or $lang eq 'cn') {
                if (not $has_preferred->{$lang}) {
                  $v->{is_preferred}->{$lang} = 1;
                  $has_preferred->{$lang} = 1;
                }
              }
            } else {
              push @{$v->{others} ||= []}, $w;
            }

            $value->{abbr} = $rep->{abbr} if defined $rep->{abbr};
            if (defined $rep->{to_abbr} and $rep->{to_abbr} eq 'single') {
              $v->{abbr_indexes} = [map { undef } @$w];
              $v->{abbr_indexes}->[$rep->{abbr_index} // 0] = 0;
            }
          } elsif ($rep->{type} eq 'yomi') {
            if (not defined $rep->{source}) {
              my $vtype = $rep->{is_ja} ? 'ja' : 'han';
              my $han_value;
            for (@{$label->{form_groups}}) {
              if ($_->{form_group_type} eq $vtype) {
                $value = $_;
                $value_added = 1;
              } elsif ($_->{form_group_type} eq 'han') {
                $han_value = $_;
              } elsif ($_->{form_group_type} eq 'korean' and $vtype ne 'ja') {
                $value = $_;
                $value_added = 1;
                for my $v (@{$_->{form_sets}}) {
                  $v->{form_set_type} = 'korean';
                }
              }
            }

              $value->{form_group_type} = $vtype;
              fill_rep_yomi $rep;
              
            if ($vtype eq 'ja' and defined $han_value and
                not @{$value->{form_sets} or []}) {
              for my $fs (@{$han_value->{form_sets}}) {
                if ($fs->{form_set_type} eq 'hanzi') {
                  my $new_fs = {form_set_type => 'hanzi',
                                others => [$fs->{jp} //
                                           $fs->{tw} //
                                           $fs->{cn} //
                                           $fs->{kr} //
                                           $fs->{others}->[0]]};
                  if (not $rep->{kana} =~ / /) {
                    $new_fs->{others}->[0] = [[map {
                      if (ref $_) {
                        @$_;
                      } else {
                        split //, $_;
                      }
                    } @{$new_fs->{others}->[0]}]];
                  }
                  push @{$value->{form_sets} ||= []}, $new_fs;
                }
              }
            }

              $v->{form_set_type} = 'yomi';
              fill_yomi_from_rep $rep => $v;
            } elsif ($rep->{source} eq '6034') {
              $value_added = 1;
              $v_added = 1;
              my $found = {};
              RV: for my $rv (grep { not $found->{$_}++ } sort { $a cmp $b } @{$rep->{value}}) {
                FG: for my $fg (@{$label->{form_groups}}) {
                  if ($fg->{form_group_type} eq 'han') {
                    for my $fs (@{$fg->{form_sets}}) {
                      if ($fs->{form_set_type} eq 'yomi') {
                        if ($rv eq (serialize_segmented_text ($fs->{ja_latin_capital} // [])) or
                            $rv eq (serialize_segmented_text ($fs->{ja_latin_upper} // [])) or
                            $rv eq (serialize_segmented_text ($fs->{ja_latin_lower} // []))) {
                          next RV;
                        }
                      }
                    }
                  }
                } # FG

                my $value = {};
                $value->{form_group_type} = 'ja';
                my $v = {};
                $v->{form_set_type} = 'alphabetical';
                $v->{ja_latin_old} = [map { $_ eq ' ' ? '._' : $_ } split /( )/, $rv];
                push @{$value->{form_sets} ||= []}, $v;
                push @{$label->{form_groups} ||= []}, $value;
              }
            } elsif ($rep->{source} eq '6036') {
              $value->{form_group_type} = 'ja';
              $v->{form_set_type} = 'alphabetical';
              my $found = {};
              $v->{ja_latin_old_wrongs} = [map {
                [map { $_ eq ' ' ? '._' : $_ } split /( )/, $_];
              } sort { $a cmp $b } grep { not $found->{$_}++ } @{$rep->{value}}];
            } else {
              die "Bad source |$rep->{source}|";
            }
          } elsif ($rep->{type} eq 'alphabetical') {
            my $w = [grep { length } map { $_ eq '|' ? '' : /\s+/ ? '._' : $_ } split /(\s+|\[[^\[\]]+\]|\|)/, $rep->{value}];
            my $w_length = @{[grep { not /^\./ } @$w]};
            # $w and $w_length will be modified later
            
            my $lang = $rep->{lang};
            for my $fg (@{$label->{form_groups}}) {
              if ($lang eq 'ja_latin' or $lang eq 'ja_latin_old') {
                next;
              }
              
              if (($lang eq 'vi' or $lang eq 'vi_latin' or
                   $lang eq 'nan' or $lang eq 'pinyin') and
                  not defined $rep->{abbr}) {
                if ($fg->{form_group_type} eq 'han') {
                  $value = $fg;
                  $value_added = 1;
                  last;
                }
                next;
              }
              
              if ($fg->{form_group_type} eq 'alphabetical') {
                $value = $fg;
                $value_added = 1;
                last;
              } elsif ($fg->{form_group_type} eq 'han' and
                       not defined $rep->{abbr}) {
                my $fs = $fg->{form_sets}->[0];
                my $s = $fs->{cn} //
                    $fs->{jp} //
                    $fs->{tw} //
                    $fs->{kr} //
                    $fs->{ja_latin} // $fs->{kana} // $fs->{kr} // $fs->{kp} // $fs->{ko} // $fs->{others}->[0] // die;
                my $s_length = @{[grep { not /^\./ } @$s]};
                if ($w_length == $s_length) {
                  $value = $fg;
                  $value_added = 1;
                  last;
                }
              }
            } # $fg
            $v->{form_set_type} = 'alphabetical';
            if ($lang eq 'ja_latin' or $lang eq 'ja_latin_old') {
              $value->{form_group_type} = 'ja' if not $value_added;

              if (not defined $rep->{lang}) {
              FG: for my $fg (@{$label->{form_groups}}) {
                if ($fg->{form_group_type} eq 'han') {
                  for my $fs (@{$fg->{form_sets}}) {
                    if ($fs->{form_set_type} eq 'yomi') {
                      if ($rep->{value} eq (join '', @{$fs->{ja_latin_capital}}) or
                          $rep->{value} eq (join '', @{$fs->{ja_latin_upper}}) or
                          $rep->{value} eq (join '', @{$fs->{ja_latin_lower}})) {
                        $value_added = $v_added = 1;
                        last FG;
                      }
                    }
                  }
                }
              } # FG
              }
            } elsif ($lang eq 'vi' or $lang eq 'vi_latin') {
              $value->{form_group_type} = 'vi' if not $value_added;
              $v->{form_set_type} = 'vietnamese';
              $lang = 'vi';
            } elsif ($lang eq 'nan' or $lang eq 'pinyin') {
              $value->{form_group_type} = 'han' if not $value_added;
              $v->{form_set_type} = 'chinese';
              $lang = 'nan_poj' if $lang eq 'nan';
            } else {
              $value->{form_group_type} = 'alphabetical' if not $value_added;
              if ($lang eq 'fr_ja') {
                $lang = 'fr';
                $v->{origin_lang} = 'ja';
              }
            }
            
            my $abbr_indexes;
            if (defined $rep->{abbr}) {
              if ($rep->{abbr} eq 'acronym') {
                  use utf8;
                  if ($rep->{value} =~ /[.・]/) {
                    $w = [map { ($_ eq '.' or $_ eq "・") ? '..' : $_ } split /([.・])/, $rep->{value}];
                  } else {
                    $w = [split //, $rep->{value}];
                  }
                  if ($rep->{abbr} eq 'acronym' and
                      (@$w == 1 or
                       (@$w == 2 and $w->[1] eq '..'))) {
                    $value->{abbr} = 'single';
                  } else {
                    $value->{abbr} = $rep->{abbr};
                  }
              } else {
                die "Unknown abbr type |$rep->{abbr}|";
              }
            } else { # not abbr
              if ($lang eq 'nan_poj') {
                $w = [map { $_ eq '-' ? '.-' : $_ } map { split /(-)/, $_ } @$w];
              } elsif ($lang eq 'pinyin') {
                my $matched = 0;
                my $x = [];
                push @$x, ucfirst shift @$w;
                for (@$w) {
                  next if $_ eq '._';
                  if (/^[aoeAOEāōēĀŌĒáóéÁÓÉǎǒěǍǑĚàòèÀÒÈ]/) {
                    push @$x, ".'";
                  }
                  push @$x, $_;
                }
                $w = $x;
              } else {
                $w = [map { s/-$// ? ($_, '.-') : ($_) } @$w];
              }
              my @abbr;
              my $j = 0;
              for my $i (0..$#$w) {
                if ($w->[$i] =~ s/\A\[// and $w->[$i] =~ s/\]\z//) {
                  push @abbr, $j++;
                } elsif ($w->[$i] =~ /^\./) {
                  #
                } else {
                  push @abbr, undef;
                }
              }
              $abbr_indexes = \@abbr unless $j == 0;
            } # not abbr
            $w_length = @{[grep { not /^\./ } @$w]};
            
            if ($v->{form_set_type} eq 'alphabetical' and
                @{$value->{form_sets} || []} and
                $value->{form_sets}->[-1]->{form_set_type} eq 'alphabetical' and
                ((not defined $abbr_indexes and
                  not defined $value->{form_sets}->[-1]->{abbr_indexes}) or
                  (defined $abbr_indexes and
                   defined $value->{form_sets}->[-1]->{abbr_indexes} and
                   @$abbr_indexes == @{$value->{form_sets}->[-1]->{abbr_indexes}} and
                   join ($;, map { $_ // '' } @$abbr_indexes) eq
                   join ($;, map { $_ // '' } @{$value->{form_sets}->[-1]->{abbr_indexes}}))) and
                   ($value->{form_sets}->[-1]->{segment_length} == $w_length)) {
              $v = $value->{form_sets}->[-1];
              $v_added = 1;
            } elsif ($v->{form_set_type} eq 'chinese' and
                     ($lang eq 'nan_poj' or $lang eq 'pinyin')) {
              for my $fs (@{$value->{form_sets}}) {
                if ($fs->{form_set_type} eq 'chinese') {
                  $v = $fs;
                  $v_added = 1;
                  last;
                }
              }
            }
            if (not defined $v->{$lang}) {
              $v->{$lang} = $w;
              if ($lang eq 'vi' and not $has_preferred->{$lang}) {
                $v->{is_preferred}->{$lang} = 1;
                $has_preferred->{$lang} = 1;
              }
            } else {
              push @{$v->{$lang . '_others'} ||= []}, $w;
            }
            $v->{segment_length} = $w_length;
            $v->{abbr_indexes} = $abbr_indexes if defined $abbr_indexes;
          } elsif ($rep->{type} eq 'jpan' or
                   $rep->{type} eq 'zh') {
            my @value;
            while (length $rep->{value}) {
              use utf8;
              if ($rep->{value} =~ s/\A([\p{Hiragana}\p{Katakana}\x{1B001}-\x{1B11F}ー、][\p{Hiragana}\p{Katakana}\x{1B001}-\x{1B11F}ー、・|]*)//) {
                $value->{form_group_type} = 'kana';
                $v->{form_set_type} = 'kana';
                my $w = [map {
                  /^\s+$/ ? '._' : $_ eq "・" ? '.・' : $_ eq "、" ? '.・' : $_;
                } grep { length } split /([・、]|\s+)|\|/, $1];
                $v->{kana} = $w;
                if (defined $rep->{lang} and $rep->{lang} eq 'ja_old') {
                  $v->{hiragana_classic} = [map { to_hiragana $_ } @$w];
                }
                if ($rep->{value} =~ s/\A\[J:\]//) {
                  $value->{form_group_type} = 'ja';
                } elsif ($rep->{value} =~ s/\A\[\]//) {
                  #
                }
              } elsif ($rep->{value} =~ s/\A([\p{Han}|]+)//) {
                $value->{form_group_type} = 'han';
                $v->{form_set_type} = 'hanzi';
                my $w = [split //, $1];
                push @{$v->{others} ||= []}, $w;
                while ($rep->{value} =~ s/\A\[(!|)(J:|)(,*[\p{Hiragana}\p{Han}\x{1B001}-\x{1B11F}]+(?:[\s,]+[\p{Hiragana}\p{Han}\x{1B001}-\x{1B11F}]+)*)\]//) {
                  my $is_wrong = $1;
                  my $is_ja = $2;
                  if ($is_ja) {
                    $value->{form_group_type} = 'ja';
                    $v->{others} = [map {
                      my $r = [[]];
                      for (@$_) {
                        if ($_ eq '|') {
                          push @$r, [];
                        } else {
                          push @{$r->[-1]}, $_;
                        }
                      }
                      $r;
                    } @{$v->{others}}] if $v->{form_set_type} eq 'hanzi';
                  }
                  push @{$value->{form_sets}}, $v;
                  $v = {};

                  my $kanas = [split /,/, $3];
                  my $rep = {};
                  die if $is_wrong and
                         (length $kanas->[0] or length $kanas->[1]);
                  $rep->{kana_modern} = $kanas->[0]
                      if @$kanas >= 1 and length $kanas->[0];
                  $rep->{kana_classic} = $kanas->[1]
                      if @$kanas >= 2 and length $kanas->[1];
                  shift @$kanas;
                  shift @$kanas;
                  if ($is_wrong) {
                    $rep->{kana_wrongs} = $kanas;
                  } else {
                    for (@$kanas) {
                      if (/\p{Han}/) {
                        push @{$rep->{hans} ||= []}, $_;
                      } else {
                        push @{$rep->{kana_others} ||= []}, $_;
                      }
                    }
                  }
                  fill_rep_yomi $rep;

                  $v->{form_set_type} = 'yomi';
                  fill_yomi_from_rep $rep => $v;
                }
                if ($rep->{value} =~ s/\A\[(J:|)\]//) {
                  $value->{form_group_type} = 'ja' if $1;
                  $v->{others} = [map {
                    my $r = [[]];
                    for (@$_) {
                      if ($_ eq '|') {
                        push @$r, [];
                      } else {
                        push @{$r->[-1]}, $_;
                      }
                    }
                    $r;
                  } @{$v->{others}}];
                }
              } elsif ($rep->{value} =~ s/\A(\p{Latn}+)//) {
                $value->{form_group_type} = 'ja';
                $v->{form_set_type} = 'alphabetical';
                my $w = [$1];
                if (defined $v->{ja_latin}) {
                  push @{$v->{ja_latin_others} ||= []}, $w;
                } else {
                  $v->{ja_latin} = $w;
                }
              } elsif ($rep->{value} =~ s/\A([()\p{Geometric Shapes}・]+)//) {
                $value->{form_group_type} = 'symbols';
                $v->{form_set_type} = 'symbols';
                my $w = [{'・' => '.・'}->{$1} // $1];
                push @{$v->{others} ||= []}, $w;
              } else {
                die "Bad compound value |$rep->{value}|";
              }
              push @{$value->{form_sets}}, $v;
              $v = {};
              push @value, $value;
              $value = {form_sets => []};
            }
            if (@value == 1) {
              $value = $value[0];
            } else {
              $value = {form_group_type => 'compound', items => \@value};
              my $lang = {
                jpan => 'jp',
                ja => 'jp',
                ja_old => 'jp',
                cn => 'cn',
                tw => 'tw',
                hk => 'hk',
              }->{$rep->{lang} // $rep->{type}};
              if (not $has_preferred->{$lang}) {
                $value->{is_preferred}->{$lang} = 1;
                $has_preferred->{$lang} = 1;
              }
            }
            $v_added = 1;
          } elsif ($rep->{type} eq 'bopomofo') {
            for (@{$label->{form_groups}}) {
              if ($_->{form_group_type} eq 'han') {
                $value = $_;
                $value_added = 1;
              }
            }
            $value->{form_group_type} = 'han' unless $value_added;

            my $lang = 'bopomofo';
            for my $fs (@{$value->{form_sets}}) {
              if ($fs->{form_set_type} eq 'chinese' and
                  not defined $fs->{$lang}) {
                $v = $fs;
                $v_added = 1;
                last;
              }
            }

            $v->{form_set_type} = 'chinese';
            my $w = [map {
              $_ =~ /\s/ ? '._' : $_;
            } split /(\s+)/, $rep->{value}];
            $v->{$lang} = $w;
          } elsif ($rep->{type} eq 'korean') { # Korean alphabet
            for (@{$label->{form_groups}}) {
              if ($_->{form_group_type} eq 'han') {
                $value = $_;
                $value_added = 1;
              }
            }
            $value->{form_group_type} = 'korean' unless $value_added;

            my $lang = $rep->{lang};
            if ($lang =~ s/_(ja|vi)$//) {
              $v->{origin_lang} = $1;
            }
            
            my $found = 0;
            for my $fs (@{$value->{form_sets}}) {
              if ($fs->{form_set_type} eq 'korean' and
                  defined $fs->{$lang} and
                  (join '', @{$fs->{$lang}}) eq $rep->{value}) {
                $found = 1;
                last;
              }
            }

            if ($found) {
              $v_added = 1;
            } else {
              $v->{form_set_type} = 'korean';
              my $w = [$rep->{value} =~ /\|/ ? split /\|/, $rep->{value} : split //, $rep->{value}];
              if (not defined $v->{$lang}) {
                $v->{$lang} = $w;
                if (not $has_preferred->{$lang}) {
                  $v->{is_preferred}->{$lang} = 1;
                  $has_preferred->{$lang} = 1;
                }
              } else {
                push @{$v->{others} ||= []}, $w;
              }
            }
          } elsif ($rep->{type} eq 'manchu') {
            $value->{form_group_type} = 'manchu';
            $v->{form_set_type} = 'manchu';
            for my $key (qw(manchu),
                         qw(moellendorff abkai xinmanhan)) { # latin
              $v->{$key} = [map { $_ =~ /\s/ ? '._' : $_ } split /(\s+)/, $rep->{$key}]
                  if defined $rep->{$key};
            }
          } elsif ($rep->{type} eq 'mongolian') {
            $value->{form_group_type} = 'mongolian';
            $v->{form_set_type} = 'mongolian';
            $rep->{cyrillic} = to_lc $rep->{cyrillic} if defined $rep->{cyrillic};
            for my $key (qw(mongolian),
                         qw(cyrillic),
                         qw(vpmc)) { # latin
              $v->{$key} = [map { $_ =~ /\s/ ? '._' : $_ } split /(\s+)/, $rep->{$key}]
                  if defined $rep->{$key};
            }
          } else {
            die "Unknown type |$rep->{type}|";
          }

          if ($rep->{kind} eq 'name') {
            $label->{is_name} = \1;
            if ($rep->{preferred} and defined $rep->{lang}) {
              my $lang = {
                ja => 'jp',
                ko => 'kr',
              }->{$rep->{lang}} // $rep->{lang};
              if ($value->{form_group_type} eq 'compound') {
                $value->{is_preferred}->{$lang} = \1;
              } else {
                $v->{is_preferred}->{$lang} = \1;
              }
            }
          } elsif ($rep->{kind} eq '(expanded)' or
                   $rep->{kind} eq 'yomi') {
            #
          } else {
            die "Unknown type |$rep->{kind}|";
          }
          push @{$value->{form_sets}}, $v if not $v_added and keys %$v;
        }
      } else { # XXX old style
        $value = $rep;
      }
      
      $value->{expandeds} = filter_labels $value->{expandeds}
          if defined $value->{expandeds};
      push @{$label->{form_groups}}, $value unless $value_added;
    } # $rep

    push @$labels, $label unless $label_added;
  } # reps_to_labels
  
  for my $era (values %{$Data->{eras}}) {
    my $has_preferred = {};
    for my $label_set (@{$era->{_LABELS}}) {
      for my $label (@{$label_set->{labels}}) {
        for my $rep (@{$label->{reps}}) {
          if ($rep->{preferred} and defined $rep->{lang}) {
            my $lang = {
              ja => 'jp',
              ko => 'kr',
            }->{$rep->{lang}} // $rep->{lang};
            $has_preferred->{$lang} = 1;
          }
        }
      }
    }

    $era->{label_sets} = [];
    for my $label_set (@{$era->{_LABELS}}) {
      my $new_label_set = {labels => []};
      reps_to_labels [map { (@{$_->{reps}}, {next_label => 1}) } @{$label_set->{labels}}] => $new_label_set->{labels}, $has_preferred;
      $new_label_set->{labels} = filter_labels $new_label_set->{labels};
      push @{$era->{label_sets}}, $new_label_set if @{$new_label_set->{labels}};
    }
  } # $era
  
  for my $era (values %{$Data->{eras}}) {
    for my $label_set (@{$era->{label_sets}}) {
      for my $label (@{$label_set->{labels}}) {
        if ($label->{is_name}) {
          for my $text (@{$label->{form_groups}}) {
            if ($text->{form_group_type} eq 'han' or
                $text->{form_group_type} eq 'ja' or
                $text->{form_group_type} eq 'kana') {
              my $jp_preferred = 0;
              for my $value (@{$text->{form_sets}}) {
                if ($value->{form_set_type} eq 'hanzi') {
                  for my $lang (qw(jp tw cn)) {
                    if (defined $value->{$lang} and
                        not defined $text->{abbr} and
                        (not defined $era->{_SHORTHANDS}->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} or
                         ($value->{is_preferred} or {})->{$lang})) {
                      $era->{_SHORTHANDS}->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} = serialize_segmented_text $value->{$lang};
                      $jp_preferred = 1 if $lang eq 'jp';
                      $era->{_SHORTHANDS}->{name} //= $era->{_SHORTHANDS}->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang};
                    }
                  if (defined $value->{$lang} and
                      defined $text->{abbr} and $text->{abbr} eq 'single') {
                    $era->{_SHORTHANDS}->{abbr} //= serialize_segmented_text $value->{$lang};
                  }
                    $era->{_SHORTHANDS}->{names}->{serialize_segmented_text $value->{$lang}} = 1
                        if defined $value->{$lang};
                  }
                  for ($value->{kr} // undef, @{$value->{others} or []}) {
                    next unless defined;
                    my $s = serialize_segmented_text $_;
                    $era->{_SHORTHANDS}->{names}->{$s} = 1;
                    $era->{_SHORTHANDS}->{name} //= $s;
                  }
                } elsif ($value->{form_set_type} eq 'yomi' or
                         $value->{form_set_type} eq 'kana') {
                  if ($text->{form_group_type} eq 'kana' and
                      defined $value->{kana}) {
                    my $name = serialize_segmented_text $value->{kana};
                    if (not defined $era->{_SHORTHANDS}->{name_ja} or
                        ($value->{is_preferred} or {})->{jp}) {
                      $era->{_SHORTHANDS}->{name_ja} = $name;
                      $era->{_SHORTHANDS}->{name} //= $era->{_SHORTHANDS}->{name_ja};
                    }
                    $era->{_SHORTHANDS}->{names}->{$name} = 1;
                  }

                  if (defined $value->{hiragana_modern}) {
                    my $kana = serialize_segmented_text $value->{hiragana_modern};
                    $era->{_SHORTHANDS}->{name_kana} //= $kana;
                    $era->{_SHORTHANDS}->{name_kana} = $kana if $jp_preferred;
                    $era->{_SHORTHANDS}->{name_kanas}->{$kana} = 1;

                    my $latin = serialize_segmented_text $value->{ja_latin};
                    $era->{_SHORTHANDS}->{name_latn} //= $latin;
                    $era->{_SHORTHANDS}->{name_latn} = $latin if $jp_preferred;

                    $jp_preferred = 0;
                  }
                }
              } # $fs
            }
          }
        } # is_name
      } # $label
    } # $label_set
    for my $label_set (@{$era->{label_sets}}) {
      for my $label (@{$label_set->{labels}}) {
        for my $text (@{$label->{form_groups}}) {
          if ($text->{form_group_type} eq 'han' or
              $text->{form_group_type} eq 'ja' or
              $text->{form_group_type} eq 'vi' or
              $text->{form_group_type} eq 'korean') {
            for my $fs (@{$text->{form_sets}}) {
              if ($fs->{form_set_type} eq 'hanzi') {
                fill_han_variants $fs;
                for my $lang (qw(tw jp cn)) {
                  if ($label->{is_name} and
                      defined $fs->{$lang} and
                      not defined $text->{abbr} and
                      not defined $era->{_SHORTHANDS}->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang}) {
                    $era->{_SHORTHANDS}->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} = serialize_segmented_text $fs->{$lang};
                    $era->{_SHORTHANDS}->{name} //= $era->{_SHORTHANDS}->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang};
                  }
                } # $lang
                for my $lang (@$LeaderKeys) {
                  if ($label->{is_name} and defined $fs->{$lang}) {
                    my $v = serialize_segmented_text $fs->{$lang};
                    $era->{_SHORTHANDS}->{names}->{$v} = 1 if defined $v;
                  }
                } # $lang
              } elsif ($fs->{form_set_type} eq 'yomi') {
                $era->{_SHORTHANDS}->{name_kana} //= serialize_segmented_text $fs->{hiragana_modern};
                for (grep { defined }
                     $fs->{hiragana} // undef,
                     $fs->{hiragana_modern} // undef,
                     $fs->{hiragana_classic} // undef,
                     @{$fs->{hiragana_others} or []}) {
                  my $v = serialize_segmented_text $_;
                  $era->{_SHORTHANDS}->{name_kanas}->{$v} = 1;
                }
                
                if (defined $fs->{ja_latin}) {
                  $era->{_SHORTHANDS}->{name_latn} //= serialize_segmented_text $fs->{ja_latin};
                }
              } elsif ($fs->{form_set_type} eq 'kana') {
                fill_kana $fs;
              } elsif ($fs->{form_set_type} eq 'korean') {
                fill_korean $fs;
                
                for my $lang (qw(ko kr kp)) {
                  if (defined $fs->{$lang} and
                      (not defined $era->{_SHORTHANDS}->{name_ko} or
                       ($fs->{is_preferred} or {})->{$lang})) {
                    $era->{_SHORTHANDS}->{name_ko} = serialize_segmented_text $fs->{$lang};
                    $era->{_SHORTHANDS}->{name} //= $era->{_SHORTHANDS}->{name_ko};
                  }
                }
              } elsif ($fs->{form_set_type} eq 'chinese') {
                fill_chinese $fs;

                for my $lang (qw(pinyin nan_poj)) {
                  if (defined $fs->{$lang} and
                          (not defined $era->{_SHORTHANDS}->{name_latn})) {
                    my $v = serialize_segmented_text $fs->{$lang};
                    $era->{_SHORTHANDS}->{name_latn} //= $v;
                    $era->{_SHORTHANDS}->{name} //= $v;
                  }
                }
              } elsif ($fs->{form_set_type} eq 'vietnamese') {
                fill_alphabetical $fs;

                for my $lang (qw(vi)) {
                  if (defined $fs->{$lang} and
                      (not defined $era->{_SHORTHANDS}->{name_vi} or
                       ($fs->{is_preferred} or {})->{$lang})) {
                    $era->{_SHORTHANDS}->{name_vi} = serialize_segmented_text $fs->{$lang};
                    $era->{_SHORTHANDS}->{name_latn} //= $era->{_SHORTHANDS}->{name_vi};
                    $era->{_SHORTHANDS}->{name} //= $era->{_SHORTHANDS}->{name_vi};
                  }
                }
              } elsif ($fs->{form_set_type} eq 'alphabetical') {
                fill_alphabetical $fs;

                if (defined $fs->{ja_latin} and
                    (not defined $era->{_SHORTHANDS}->{abbr_latn} or
                     ($fs->{is_preferred} or {})->{ja_latin}) and
                     defined $text->{abbr} and
                     $text->{abbr} eq 'single') {
                  $era->{_SHORTHANDS}->{abbr_latn} = serialize_segmented_text $fs->{ja_latin};
                }

                if (defined $fs->{en} and
                    (not defined $era->{_SHORTHANDS}->{name_en} or
                     ($fs->{is_preferred} or {})->{en})) {
                  $era->{_SHORTHANDS}->{name_en} = serialize_segmented_text $fs->{en};
                  $era->{_SHORTHANDS}->{name_latn} //= $era->{_SHORTHANDS}->{name_en};
                  $era->{_SHORTHANDS}->{name} //= $era->{_SHORTHANDS}->{name_en};
                }
              }
            } # $fs
            my $fst = {
              'chinese' . $; . '' => 'han_0',
              'yomi' . $; . '' => 'han_1',
              'vietnamese' . $; . '' => 'han_2',
              'korean' . $; . '' => 'han_3',
              'korean' . $; . 'ja' => 'han_4',
              'korean' . $; . 'vi' => 'han_5',
              'alphabetical' . $; . '' => 'han_6',
            };
            $text->{form_sets} = [sort {
              ($fst->{$a->{form_set_type}, $a->{origin_lang} // ''} || 0) cmp ($fst->{$b->{form_set_type}, $b->{origin_lang} // ''} || 0);
            } @{$text->{form_sets}}];
          } elsif ($text->{form_group_type} eq 'kana') {
            for my $fs (@{$text->{form_sets}}) {
              if ($fs->{form_set_type} eq 'kana') {
                fill_kana $fs;
                if (defined $fs->{ja_latin}) {
                  $era->{_SHORTHANDS}->{name_latn} //= serialize_segmented_text $fs->{ja_latin};
                }
              }
            } # $fs
          } elsif ($text->{form_group_type} eq 'alphabetical') {
            for my $fs (@{$text->{form_sets}}) {
              if ($fs->{form_set_type} eq 'alphabetical') {
                fill_alphabetical $fs;

                if (defined $fs->{en} and
                    (not defined $era->{_SHORTHANDS}->{name_en} or
                     ($fs->{is_preferred} or {})->{en})) {
                  $era->{_SHORTHANDS}->{name_en} = serialize_segmented_text $fs->{en};
                  $era->{_SHORTHANDS}->{name_latn} //= $era->{_SHORTHANDS}->{name_en};
                  $era->{_SHORTHANDS}->{name} //= $era->{_SHORTHANDS}->{name_en};
                }
              }
            } # $fs
          } elsif ($text->{form_group_type} eq 'compound') {
            my $name_jp = ''; my $name_cn = ''; my $name_tw = '';
            my $kana = ''; my $no_kana = 0;
            my $latin = ''; my $no_latin = 0;
            for my $item_fg (@{$text->{items}}) {
              if ($item_fg->{form_group_type} eq 'han' or
                  $item_fg->{form_group_type} eq 'ja' or
                  $item_fg->{form_group_type} eq 'vi' or
                  $item_fg->{form_group_type} eq 'kana') {
                my $has_kana = 0;
                my $has_latin = 0;
                for my $item_fs (@{$item_fg->{form_sets}}) {
                  if ($item_fs->{form_set_type} eq 'hanzi') {
                    fill_han_variants $item_fs;
                    $name_jp .= serialize_segmented_text
                        ($item_fs->{jp} //
                         $item_fs->{tw} //
                         $item_fs->{cn} //
                         $item_fs->{kr} //
                         $item_fs->{others}->[0]);
                    $name_cn .= serialize_segmented_text
                        ($item_fs->{cn} //
                         $item_fs->{jp} //
                         $item_fs->{tw} //
                         $item_fs->{kr} //
                         $item_fs->{others}->[0]);
                    $name_tw .= serialize_segmented_text
                        ($item_fs->{tw} //
                         $item_fs->{kr} //
                         $item_fs->{jp} //
                         $item_fs->{cn} //
                         $item_fs->{others}->[0]);
                  } elsif ($item_fs->{form_set_type} eq 'kana' or
                           $item_fs->{form_set_type} eq 'yomi') {
                    if ($item_fs->{form_set_type} eq 'kana') {
                      fill_kana $item_fs;
                      my $v = serialize_segmented_text ($item_fs->{kana} // die);
                      $name_jp .= $v;
                      $name_cn .= $v;
                      $name_tw .= $v;
                    }
                    $kana .= serialize_segmented_text ($item_fs->{hiragana_modern} // die);
                    $has_kana = 1;
                    $latin .= ' ' if length $latin;
                    $latin .= serialize_segmented_text ($item_fs->{ja_latin} // die);
                    $has_latin = 1;
                  } elsif ($item_fs->{form_set_type} eq 'alphabetical' or
                           $item_fs->{form_set_type} eq 'vietnamese') {
                    fill_alphabetical $item_fs;
                    my $v = serialize_segmented_text ($item_fs->{ja_latin} // die);
                    $name_jp .= $v;
                    $name_cn .= $v;
                    $name_tw .= $v;
                    $latin .= ' ' if length $latin;
                    $latin .= $v;
                  }
                } # $item_fs
                $no_kana = 1 unless $has_kana;
                $no_latin = 1 unless $has_latin;
              } elsif ($item_fg->{form_group_type} eq 'symbols') {
                for my $item_fs (@{$item_fg->{form_sets}}) {
                  my $v = serialize_segmented_text ($item_fs->{others}->[0] // die);
                  $name_jp .= $v;
                  $name_cn .= $v;
                  $name_tw .= $v;
                }
              } else {
                die "Unknown form group type |$item_fg->{form_group_type}|";
              }
            } # $item_fg

            $era->{_SHORTHANDS}->{names}->{$name_jp} = 1;
            $era->{_SHORTHANDS}->{names}->{$name_cn} = 1;
            $era->{_SHORTHANDS}->{names}->{$name_tw} = 1;
            if ((not defined $era->{_SHORTHANDS}->{name_ja} or
                 ($text->{is_preferred} or {})->{jp})) {
              $era->{_SHORTHANDS}->{name_ja} = $name_jp;
              $era->{_SHORTHANDS}->{name} //= $era->{_SHORTHANDS}->{name_ja};
              $era->{_SHORTHANDS}->{name} = $era->{_SHORTHANDS}->{name_ja}
                  if ($text->{is_preferred} or {})->{jp};
            }
            if (not $no_kana) {
              if ((not defined $era->{_SHORTHANDS}->{name_kana} or
                  ($text->{is_preferred} or {})->{jp})) {
                $era->{_SHORTHANDS}->{name_kana} = $kana;
              }
              $era->{_SHORTHANDS}->{name_kanas}->{$kana} = 1;
            }
            if (not $no_latin and
                ((not defined $era->{_SHORTHANDS}->{name_latn} or
                 ($text->{is_preferred} or {})->{jp}))) {
              $era->{_SHORTHANDS}->{name_latn} = $latin;
            }
            if ((#not defined $era->{_SHORTHANDS}->{name_cn} or
                 ($text->{is_preferred} or {})->{cn})) {
              $era->{_SHORTHANDS}->{name_cn} = $name_cn;
            }
            if ((#not defined $era->{_SHORTHANDS}->{name_tw} or
                 ($text->{is_preferred} or {})->{tw})) {
              $era->{_SHORTHANDS}->{name_tw} = $name_tw;
            }
          } # form_group_type
          for my $label (@{$text->{expandeds} or []}) {
            for my $fg (@{$label->{form_groups}}) {
              if ($fg->{form_group_type} eq 'han' or
                  $fg->{form_group_type} eq 'ja' or
                  $fg->{form_group_type} eq 'vi') {
                for my $fs (@{$fg->{form_sets}}) {
                  if ($fs->{form_set_type} eq 'hanzi') {
                    fill_han_variants $fs;
                  } elsif ($fs->{form_set_type} eq 'alphabetical' or
                           $fs->{form_set_type} eq 'vietnamese') {
                    fill_alphabetical $fs;
                  }
                } # $fs
              } elsif ($fg->{form_group_type} eq 'alphabetical') {
                for my $fs (@{$fg->{form_sets}}) {
                  if ($fs->{form_set_type} eq 'alphabetical') {
                    fill_alphabetical $fs;
                  }
                } # $fs
              }
            }
          } # $label
        }
      }
    } # $label_set
    
    for my $ls (@{$era->{label_sets}}) {
      for my $label (@{$ls->{labels}}) {
        my $abbr = undef;
        for my $fg (@{$label->{form_groups}}) {
          my $fg_abbr = $fg->{abbr} // '';
          $abbr //= $fg_abbr;
          if (not $abbr eq $fg_abbr) {
            die "Era |$era->{key}|: Label |abbr| conflict: |$abbr| vs |$fg_abbr|";
          }
          delete $fg->{abbr};
        }
        if (defined $abbr and length $abbr) {
          $label->{abbr} = $abbr;
        }
      }
    }
    
    {
      my $fg_datas = [];
      for my $ls (@{$era->{label_sets}}) {
        for my $label (@{$ls->{labels}}) {
          for my $fg (@{$label->{form_groups}}) {
            if ($fg->{form_group_type} eq 'compound') {
              for my $item_fg (@{$fg->{items}}) {
                my $r = compute_form_group_ons $item_fg;
                push @$fg_datas, $r if defined $r;
              }
            } else {
              my $r = compute_form_group_ons $fg;
              push @$fg_datas, $r if defined $r;
            }
          }
        }
      }
      $era->{_FORM_GROUP_ONS} = $fg_datas;
    }
    
    delete $era->{_LABELS};
  } # $era
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
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
