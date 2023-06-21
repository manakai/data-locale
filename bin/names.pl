package names;
use strict;
use warnings;
use Carp;
use Path::Tiny;
use Web::Encoding;
use Web::Encoding::Normalization qw(to_nfd to_nfc);
use Web::URL::Encoding;
use JSON::PS;
use Storable;

my $RootPath = path (__FILE__)->parent->parent;

sub parse_src_line ($$) {
  my ($in => $out) = @_;

  $in =~ s/^\s*//;
  if ($in =~ /^(name|label)(!|)\s+((?:[\p{sc=Han}\x{30000}-\x{3FFFF}][\x{E0100}-\x{E01FF}]?)+)$/) {
    push @{$out->[-1]->{labels}->[-1]->{reps}},
        {kind => $1, type => 'han', value => $3, preferred => $2};
    } elsif ($in =~ /^name_kana\s+([\p{sc=Hiragana} ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'yomi', type => 'yomi', kana_modern => $1};
    } elsif ($in =~ /^name_kana\s+([\p{sc=Hiragana} ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'yomi', type => 'yomi', kana_modern => $1};
    } elsif ($in =~ /^name_kana\s+([\p{sc=Hiragana} ]+),([\p{sc=Hiragana} ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'yomi', type => 'yomi', kana_modern => $1,
           kana_classic => $2};
    } elsif ($in =~ /^name_kana\s+([\p{sc=Hiragana} ]+),,([\p{sc=Hiragana} ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'yomi', type => 'yomi', kana_modern => $1,
           kana_others => [$2]};
    } elsif ($in =~ /^name_kana\s+([\p{sc=Hiragana} ]+),([\p{sc=Hiragana} ]+),([\p{sc=Hiragana} ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'yomi', type => 'yomi', kana_modern => $1,
           kana_classic => $2, kana_others => [$3]};
    } elsif ($in =~ /^name_(ja|cn|tw|ko)(!|)\s+((?:\p{sc=Han}[\x{E0100}-\x{E01FF}]?)+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name', type => 'han', lang => $1, value => $3,
           preferred => $2};
    } elsif ($in =~ /^(name|label)\((en|la|en_la|it|fr|fr_ja|es|po|fr_old_zh|es_old_zh|en_old_zh|ja_latin|ja_latin_old|ja_latin_old_wrong|vi_latin|nan_poj|nan_tl|nan_wp|zh_alalc|sinkan)\)(!|)\s+([\p{sc=Latn}\s%0-9A-F'\x{030D}\x{0358}|-]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => $1,
           type => 'alphabetical',
           lang => $2,
           preferred => $3,
           value => percent_decode_c $4};
    } elsif ($in =~ /^(pinyin)(!|)\s+([\p{sc=Latn}\s%0-9A-F'|-]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'alphabetical',
           lang => $1,
           preferred => $2,
           value => percent_decode_c $3};
    } elsif ($in =~ /^(bopomofo|bopomofo\(nan\))(!|)\s+([\p{sc=Bopo}\x{02C7}\x{02CA}\x{02CB}\x{02D9}\x{22A6}\x{14BB}|\s]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'bopomofo',
           lang => ({'bopomofo(nan)' => 'nan'}->{$1} // 'zh'),
           preferred => $2,
           value => percent_decode_c $3};
    } elsif ($in =~ /^name\((vi)\)(!|)\s+([\p{sc=Latn}\s%0-9A-F]+)$/) {
      my $lang = $1;
      my $preferred = $2;
      my $value = percent_decode_c $3;
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'alphabetical',
           lang => $lang,
           preferred => $preferred,
           value => $value};
    } elsif ($in =~ /^name\((vi_kana)\)\s+([\p{sc=Katakana}\x{30FC}\s|]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'kana',
           lang => $1,
           value => $2};
    } elsif ($in =~ /^name\((vi_old)\)\s+([\p{sc=Latn}\s%0-9A-F]+)\s+([\p{sc=Katakana}\x{30FC}\N{KATAKANA MIDDLE DOT}\s|]+)$/) {
      my $lang = $1;
      my $value2 = $3;
      my $value = percent_decode_c $2;
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'alphabetical',
           lang => $lang,
           value => $value},
          {kind => 'name',
           type => 'kana',
           lang => $lang,
           value => $value2};
    } elsif ($in =~ /^(name|label)\((ja|ja_old|en)\)(!|)\s+([\p{sc=Hiragana}\p{sc=Katakana}\x{30FC}\N{KATAKANA MIDDLE DOT}\x{1B001}-\x{1B11F}\x{3001}\p{sc=Han}\p{sc=Latn}0-9\[\]|:!,()\x{300C}\x{300D}\p{Geometric Shapes}\x{2015}\x{E0100}-\x{E01FF}\s-]+_?)$/) {
      my $rep = {kind => $1,
                 type => 'jpan',
                 lang => $2,
                 preferred => $3,
                 value => $4};
      $rep->{value} =~ s/_$/ /;
      push @{$out->[-1]->{labels}->[-1]->{reps}}, $rep;
    } elsif ($in =~ /^(name|label)\((cn|tw|hk|zh)\)(!|)\s+([\N{KATAKANA MIDDLE DOT}\xB7\p{sc=Han}\p{sc=Latn}0-9():\s-]+_?)$/) {
      my $rep = {kind => $1,
                 type => 'zh',
                 lang => $2,
                 preferred => $3,
                 value => $4};
      $rep->{value} =~ s/_$/ /;
      push @{$out->[-1]->{labels}->[-1]->{reps}}, $rep;
    } elsif ($in =~ /^name\((ko|kr|kp|kr_vi|kr_ja)\)(!|)\s+([\p{sc=Hang}|]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'korean',
           lang => $1,
           preferred => $2,
           value => $3};
    } elsif ($in =~ /^name\((ko|kr|kp|kr_vi|kr_ja)\)(!|)\s+([\p{sc=Hang}|]+)\((\p{sc=Han}+)\)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'korean',
           lang => $1,
           preferred => $2,
           value => $3};
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name', type => 'han', lang => 'ko', value => $4,
           preferred => $2};
    } elsif ($in =~ /^name\((kr)\)(!|)\s+(\p{sc=Hang}[\p{sc=Han}\p{sc=Hang}]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'korean',
           lang => $1,
           preferred => $2,
           value => $3};
    } elsif ($in =~ /^name\((ro)\)(!|)\s+(\p{sc=Cyrl}+(?:\s+\p{sc=Cyrl}+)*)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'alphabetical',
           lang => $1,
           preferred => $2,
           value => $3};
    } elsif ($in =~ /^expanded\((en|la|en_la|it|fr|es|po|vi|vi_latin|ja_latin)\)\s+([\p{sc=Latn}\s%0-9A-F'\[\]-]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'expanded',
           type => 'alphabetical',
           lang => $1,
           value => percent_decode_c $2};
    } elsif ($in =~ /^name_man\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([a-z%0-9A-F ]+),([a-z ]+),([a-z'%0-9A-F ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'manchu',
           manchu => (percent_decode_c $1),
           moellendorff => (percent_decode_c $2),
           abkai => $3,
           xinmanhan => (percent_decode_c $4)};
    } elsif ($in =~ /^name_man\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([a-z%0-9A-F ]+),([a-z ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'manchu',
           manchu => (percent_decode_c $1),
           moellendorff => (percent_decode_c $2),
           abkai => $3};
    } elsif ($in =~ /^name_man\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([a-z%0-9A-F ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'manchu',
           manchu => (percent_decode_c $1),
           moellendorff => (percent_decode_c $2)};
    } elsif ($in =~ /^name_man\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'manchu',
           manchu => (percent_decode_c $1)};
    } elsif ($in =~ /^name_mn\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([\p{sc=Cyrl}%0-9A-F ]+),([a-z%0-9A-F ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'mongolian',
           mongolian => (percent_decode_c $1),
           cyrillic => (percent_decode_c $2),
           vpmc => (percent_decode_c $3)};
    } elsif ($in =~ /^name_mn\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([\p{sc=Cyrl}%0-9A-F ]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'mongolian',
           mongolian => (percent_decode_c $1),
           cyrillic => (percent_decode_c $2)};
    } elsif ($in =~ /^abbr_(ja|tw)\s+(\p{sc=Hani})\s+(\2\p{sc=Hani}*)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name', abbr => 'single', type => 'han',
           lang => $1, value => $2},
          {kind => 'expanded',
           to_abbr => 'single',
           type => 'han',
           lang => $1,
           value => percent_decode_c $3};
    } elsif ($in =~ /^abbr_(ja|tw)\s+(\p{sc=Hani})\s+(\p{sc=Hani}*)\[(\p{sc=Hani})\](\p{sc=Hani}*)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name', abbr => 'single', type => 'han',
           lang => $1, value => $2},
          {kind => 'expanded',
           to_abbr => 'single',
           type => 'han',
           lang => $1,
           value => $3.$4.$5,
           abbr_index => length $3};
    } elsif ($in =~ /^acronym\((en|la|en_la|it|fr|es|po|vi|vi_latin|ja_latin)\)\s+([\p{sc=Latn}.\N{KATAKANA MIDDLE DOT}%0-9A-F]+)$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'alphabetical',
           abbr => 'acronym',
           lang => $1,
           value => percent_decode_c $2};
    } elsif ($in =~ /^\+name\s+(\w+)\s+(\S.*?\S|\S)\s*$/) {
      push @{$out->[-1]->{labels}->[-1]->{reps}},
          {kind => '+tag',
           type => $1,
           value => $2};
    } elsif ($in =~ /^name\s+country\+?$/) {
      $out->[-1]->{labels}->[-1]->{has_country} = 1;
    } elsif ($in =~ /^name\s+monarch\+?$/) {
      $out->[-1]->{labels}->[-1]->{has_monarch} = 1;
    } elsif ($in =~ /^name\s+country\s+monarch\+?$/) {
      $out->[-1]->{labels}->[-1]->{has_country} = 1;
      $out->[-1]->{labels}->[-1]->{has_monarch} = 1;
    } elsif ($in =~ /^&$/) {
      push @{$out->[-1]->{labels}},
          {reps => []};
    } elsif ($in =~ /^&&$/) {
      push @{$out},
          {labels => [{reps => []}]};
    } else {
      die "Bad line |$in|";
    }
} # parse_src_line
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
          #'.-?' => '',
          '.(' => '(',
          '.)' => ')',
          '.:' => ':',
        }->{$_} // die "Bad segment separator |$_| (@$st)";
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

  sub segmented_text_length ($) {
    return 0+@{[grep { not /^\./ } @{$_[0]}]};
  } # segmented_text_length
  
  sub equal_segmented_text ($$) {
    my ($ss1, $ss2) = @_;
    return (
      (serialize_segmented_text_for_key $ss1)
          eq
      (serialize_segmented_text_for_key $ss2)
    );
  } # equal_segmented_text

  sub compare_segmented_text ($$;%) {
    my ($ss1, $ss2) = @_;
    my $s1 = join '', map { ref $_ ? @$_ : $_ } grep { not /^\./ } @$ss1;
    my $s2 = join '', map { ref $_ ? @$_ : $_ } grep { not /^\./ } @$ss2;
    return 1 if $s1 eq $s2;
    return 0;
  } # compare_segmented_text

  sub transform_segmented_text ($$) {
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
  } # transform_segmented_text

  sub transform_segmented_text_first ($$$) {
    my ($ss, $code, $lang) = @_;

    my $First = {'..' => 1, '._' => 1};
    $First->{'.-'} = 1 unless $lang eq 'nan_poj' or $lang eq 'nan_tl';
    
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
        if ($First->{$_}) {
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
  } # transform_segmented_text_first
}

my $LeaderKeys = [];
{
  my $Leaders = {};

  my $loaded;
  sub load_leaders () {
    return if $loaded;
    $loaded = 1;

    print STDERR "Load leaders...";
    my $path = $RootPath->child ('local/char-leaders.dat');
    ($LeaderKeys, $Leaders) = @{retrieve $path};
    print STDERR "done!\n";
  } # load_leaders

  sub han_normalize ($) {
    my ($s) = @_;
    my $r = '';
    load_leaders;
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
    load_leaders;
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

    load_leaders;
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
    わ wa を wo ん n
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

    ふぁ fa

    うぃ wi
    てぃ thi
    でぃ dhi
    
    とぅ tu

    ちぇ che
    ふぇ fe
  )};
  sub romaji ($) {
    my $s = $_[0];
    $s =~ s/([きしちにひみりぎじびぴ][ゃゅょ]|ふぁ|[うてで]ぃ|とぅ|[ちふ]ぇ)/$ToLatin->{$1}/g;
    $s =~ s/([あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんがぎぐげござじずぜぞだでどばびぶべぼぱぴぷぺぽ])/$ToLatin->{$1}/g;
    #$s =~ s/^(\S+ \S+) (\S+ \S+)$/$1 - $2/g;
    $s =~ s/ (ten nou|ki [gn]en)$/ - $1/g;
    $s =~ s/ (kou gou) (seっ shou)$/ - $1 - $2/g;
    $s =~ s/^(\S+) (\S+) (reki)$/$1 $2 - $3/g;
    $s =~ s/n ([aiueoyn])/n ' $1/g;
    $s =~ s/っ ([ksthyrwgzdbp])/$1 $1/g;
    $s =~ s/っ([ksthyrwgzdbp])/$1$1/g;
    $s =~ s{([aiueo])ー}{
      {a => "\x{0101}", i => "\x{012B}", u => "\x{016B}",
       e => "\x{0113}", o => "\x{014D}"}->{$1};
    }ge;
    #$s =~ s/ //g;
    die "romaji: Failed to convert |$_[0]|: |$s|" if $s =~ /\p{sc=Hiragana}/;
    #return ucfirst $s;
    return $s;
  } # romaji

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
    $s =~ tr{アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォッャュョヮ𛀄𛃚𛁩𛀁𛀷𛂰𛀙𛀊𛄒𛀆𛄚𛁈𛀕𛃶}
            {あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎあもつえけほかうえいをしおり};
    return $s;
  } # to_hiragana

  sub to_katakana ($) {
    use utf8;
    my $s = shift;
    $s =~ tr{あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎ𛀄𛃚𛁩𛀁𛀷𛂰𛀙𛀊𛄒𛀆𛄚𛁈𛀕𛃶}
            {アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォッャュョヮアモツエケホカウエイヲシオリ};
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

  my $loaded;
  sub load_ons () {
    return if $loaded;
    $loaded = 1;
    
    print STDERR "Load ons...";
    
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
    print STDERR "done\n";
  } # load_ons

  sub kanji_ons ($) {
    my $c = shift;
    load_ons;
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

sub compute_form_group_ons ($$) {
  my $fg = shift;
  my $out_errors = shift;

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
    $out_errors->{_ONS}->{_errors}->{not_found_chars}->{$_} = 1 for @$no_chars;
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
                  'en_old', 'fr_old', 'es_old',
                  'vi', 'vi_old',
                  'nan_poj', 'nan_tl', 'pinyin',
                  #XXX sinkan
                  'ja_latin', 'ja_latin_old') {
      if (defined $fs->{$lang}) {
        my $ss = $fs->{$lang};
        $fs->{$lang . '_lower'} //= transform_segmented_text $ss, sub { to_lc $_[0] };
        $fs->{$lang . '_upper'} //= transform_segmented_text $ss, sub { to_uc $_[0] };
        $fs->{$lang . '_capital'} //= transform_segmented_text_first $ss, sub { to_uc $_[0] }, $lang;
      } elsif (defined $fs->{$lang . '_lower'}) {
        my $ss = $fs->{$lang . '_lower'};
        $fs->{$lang . '_capital'} //= transform_segmented_text_first $ss, sub { to_uc $_[0] }, $lang;
        $fs->{$lang} //= $fs->{$lang . '_capital'};
        $fs->{$lang . '_upper'} //= transform_segmented_text $ss, sub { to_uc $_[0] };
      }
      if ($lang eq 'ja_latin_old') {
        if (equal_segmented_text $fs->{$lang}, $fs->{$lang . '_capital'}) {
          #
        } else {
          delete $fs->{$lang . '_capital'};
        }
      }

      die if $lang eq 'ja_latin_old' and @{$fs->{$lang . '_others'} or []};
      if (@{$fs->{$lang . '_others'} or []}) {
        for my $ss (@{$fs->{$lang . '_others'} or []}) {
          push @{$fs->{$lang . '_lower_others'} ||= []},
              transform_segmented_text $ss, sub { to_lc $_[0] };
          push @{$fs->{$lang . '_upper_others'} ||= []},
              transform_segmented_text $ss, sub { to_uc $_[0] };
          push @{$fs->{$lang . '_capital_others'} ||= []},
              transform_segmented_text_first $ss, sub { to_uc $_[0] }, $lang;
        }
      } elsif (@{$fs->{$lang . '_lower_others'} or []}) {
        for my $ss (@{$fs->{$lang . '_lower_others'} or []}) {
          push @{$fs->{$lang . '_capital_others'} ||= []},
              my $cap = transform_segmented_text_first $ss, sub { to_uc $_[0] }, $lang;
          push @{$fs->{$lang . '_others'} ||= []}, $cap;
          push @{$fs->{$lang . '_upper_others'} ||= []},
              transform_segmented_text $ss, sub { to_uc $_[0] };
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

    for (@{$rep->{latin_wrongs} or []}) {
      push @{$v->{ja_latin_old_wrongs} ||= []},
          [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ } split /( (?:['-] |))/, $_];
    }
    if (defined $v->{ja_latin_old_wrongs}) {
      $v->{ja_latin_old_wrongs} = [map {
        $_->[0];
      } grep { not $found->{$_->[1]}++ } map {
        [$_, serialize_segmented_text_for_key $_];
      } @{$v->{ja_latin_old_wrongs}}];
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

      $fs->{$lang . '_fukui'} //= [map { to_fukui $_ } @{$fs->{$lang}}];
    } # $lang
  } # fill_korean

  sub fixup_korean ($) {
    my $fs = shift;
    fill_korean $fs;
    
    if (($fs->{origin_lang} // '') eq 'ja') {
      use utf8;
      if (defined $fs->{kr} and
          @{$fs->{kr}} == 3 and
          ($fs->{kr}->[2] eq '이' or
           ($fs->{kr}->[2] eq '쿠' and $fs->{kr_fukui}->[1] =~ /[auo]$/) or
           ($fs->{kr}->[2] eq '키' and $fs->{kr_fukui}->[1] =~ /[i]$/) or
           ($fs->{kr}->[1] eq '키' and $fs->{kr}->[2] eq '쓰'))) {
        $fs->{kr} = [$fs->{kr}->[0], $fs->{kr}->[1] . $fs->{kr}->[2]];
        $fs->{kr_fukui} = [map { to_fukui $_ } @{$fs->{kr}}];
        $fs->{segment_length} = segmented_text_length $fs->{kr};
      } elsif (defined $fs->{kr} and
               @{$fs->{kr}} == 3 and
               ($fs->{kr}->[1] eq '이' or
                ($fs->{kr}->[1] eq '쿠' and $fs->{kr_fukui}->[0] =~ /[auo]$/))) {
        $fs->{kr} = [$fs->{kr}->[0] . $fs->{kr}->[1], $fs->{kr}->[2]];
        $fs->{kr_fukui} = [map { to_fukui $_ } @{$fs->{kr}}];
        $fs->{segment_length} = segmented_text_length $fs->{kr};
      } elsif (defined $fs->{kr} and
               @{$fs->{kr}} == 4 and
               $fs->{kr}->[1] eq '이' and
               $fs->{kr}->[3] eq '이') {
        $fs->{kr} = [$fs->{kr}->[0] . $fs->{kr}->[1],
                     $fs->{kr}->[2] . $fs->{kr}->[3]];
        $fs->{kr_fukui} = [map { to_fukui $_ } @{$fs->{kr}}];
        $fs->{segment_length} = segmented_text_length $fs->{kr};
      }
    }
    
    if (($fs->{origin_lang} // '') eq 'vi') {
      use utf8;
      if (defined $fs->{kr} and
          @{$fs->{kr}} >= 3 and
          $fs->{kr_fukui}->[0] =~ /[aiueoy]$/ and
          $fs->{kr_fukui}->[1] =~ /^'[aiueo]/) {
        $fs->{kr}->[1] = $fs->{kr}->[0] . $fs->{kr}->[1];
        shift @{$fs->{kr}};
        $fs->{kr_fukui} = [map { to_fukui $_ } @{$fs->{kr}}];
        $fs->{segment_length} = segmented_text_length $fs->{kr};
      }
      if (defined $fs->{kr} and
          @{$fs->{kr}} == 3 and
          $fs->{kr_fukui}->[1] =~ /[aiueoy]$/ and
          $fs->{kr_fukui}->[2] =~ /^'[aiueo]/) {
        $fs->{kr} = [$fs->{kr}->[0], $fs->{kr}->[1] . $fs->{kr}->[2]];
        $fs->{kr_fukui} = [map { to_fukui $_ } @{$fs->{kr}}];
        $fs->{segment_length} = segmented_text_length $fs->{kr};
      }
    }
  } # fill_korean

  sub fill_chinese ($) {
    my $fs = shift;

    if (defined $fs->{bopomofo}) {
      $fs->{bopomofo_zuyntn} = [map { to_zuyntn $_ } @{$fs->{bopomofo}}];
    }
    if (defined $fs->{nan_bopomofo}) {
      for (@{$fs->{nan_bopomofo}}) {
        s/\x{22A6}/\x{02EB}/g;
        s/\x{14BB}/\x{02EA}/g;
      }
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
  
  sub reps_to_labels ($$$$$$);
  sub reps_to_labels ($$$$$$) {
    my ($object, $reps => $labels, $has_preferred,
        $get_object_tag, $set_object_tag) = @_;

    my $label = {form_groups => []};
    my $label_added = 0;
    if (@$labels) {
      $label = $labels->[-1];
      $label_added = 1;
    }

    my $in = undef;
    REP: for my $rep (@$reps) {
      if ($rep->{in}) {
        $in = $rep->{in};
        next REP;
      }
      if ($rep->{next_label}) {
        unless ($label_added) {
          $label->{_IN} = $in if defined $in;
          push @$labels, $label;
        }
        $label = {form_groups => []};
        $label_added = 0;
        $in = undef;
        next REP;
      }
      
      my $value = {};
      my $value_added = 0;

      if (defined $rep->{kind}) {
        if ($rep->{kind} eq '+tag') {
          my $tag = $set_object_tag->($object, $rep->{value});
          if ($rep->{type} eq 'country') {
            die "Bad tag |$tag->{key}| (not a country)"
                unless $tag->{type} eq 'country';
            $label->{props}->{country_tag_ids}->{$tag->{id}} = {};
            $label->{_PREFERRED}->{country_tag_ids} //= $tag->{id};

            for my $stag_id (keys %{$tag->{period_of}}) {
              my $stag = $get_object_tag->($stag_id);
              if ($stag->{type} eq 'country') {
                $label->{props}->{country_tag_ids}->{$stag->{id}} ||= {};
              }
            }
          } elsif ($rep->{type} eq 'monarch') {
            die "Bad tag |$tag->{key}|" unless $tag->{type} eq 'person';
            $label->{props}->{monarch_tag_ids}->{$tag->{id}} = {};
            $label->{_PREFERRED}->{monarch_tag_ids} //= $tag->{id};
          } elsif ($rep->{type} eq 'era') {
            die "Bad tag |$tag->{key}|" unless $tag->{type} eq 'person';
            
            my $lses = json_chars2perl perl2json_chars $tag->{label_sets};
            for my $ls (@$lses) {
              for my $lb (@{$ls->{labels}}) {
                $lb->{_IN} = {has_monarch => 1};
              }
            }
            $object->{_LSX} = $lses;
          } else {
            die "Bad |type| value |$rep->{type}|";
          }
          next REP;
        } elsif ($rep->{kind} eq 'expanded') {
          if (@{$label->{form_groups}} and
              defined $label->{form_groups}->[-1]->{abbr}) {
            $value = $label->{form_groups}->[-1];
            $value_added = 1;
          }
          $rep->{kind} = '(expanded)';
          $value->{expandeds} ||= [];
          reps_to_labels $object, [$rep] => $value->{expandeds}, {jp=>1,cn=>1,tw=>1},
              $get_object_tag, $set_object_tag;
        } else {
          my $v = {};
          my $v_added = 0;

          if ($rep->{type} eq 'han') {
            my @mergeable_fg;
            for my $fg (@{$label->{form_groups}}) {
              if ($fg->{form_group_type} eq 'han') {
                $value = $fg;
                $value_added = 1;
                last;
              } elsif ($fg->{form_group_type} eq 'korean' or
                       $fg->{form_group_type} eq 'vi') {
                push @mergeable_fg, $fg;
              }
            }
            $value->{form_group_type} = 'han';
            $v->{form_set_type} = 'hanzi';
            my $old_fgs = {};
            for my $fg (@mergeable_fg) {
              push @{$value->{form_sets}}, @{$fg->{form_sets}};
              $old_fgs->{$fg} = 1;
            }
            $label->{form_groups} = [grep { not $old_fgs->{$_} } @{$label->{form_groups}}];
            
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
            }->{$rep->{lang} // ''} // $rep->{lang} // '';
            if (length $lang and
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

            $v->{segment_length} = segmented_text_length $w;
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
              $v->{segment_length} = segmented_text_length ($v->{latin} // $v->{hiragana} // ($v->{latin_others} or $v->{han_others} or $v->{hiragana_wrongs} or $v->{ja_latin_old_wrongs} or [])->[0]);
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
                  $v->{segment_length} = segmented_text_length $v->{ja_latin_old};
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
              $v->{segment_length} = segmented_text_length $v->{ja_latin_old_wrongs}->[0];
            } else {
              die "Bad source |$rep->{source}|";
            }
          } elsif ($rep->{type} eq 'alphabetical') {
            my $w = [grep { length } map { $_ eq '|' ? '' : $_ eq '-' ? '.-' : /\s+/ ? '._' : $_ } split /(\s+|\[[^\[\]]+\]|\||-)/, $rep->{value}];
            my $w_length = @{[grep { not /^\./ } @$w]};
            # $w and $w_length will be modified later
            my $lang = $rep->{lang};
            #$v->{_w_length} = $w_length;
            
            CHK: for my $fg (@{$label->{form_groups}}) {
              my $mergeable = 0;
              for my $fs (@{$fg->{form_sets}}) {
                if ($fs->{form_set_type} eq 'vietnamese' and
                    ($lang eq 'vi' or $lang eq 'vi_latin' or
                     $lang eq 'vi_old') and
                    defined $fs->{vi} and
                    compare_segmented_text ($w, $fs->{vi})) {
                  $value_added = $v_added = 1;
                  next REP;
                } elsif ($fs->{form_set_type} eq 'vietnamese' and
                         ($lang eq 'vi' or $lang eq 'vi_latin' or
                          $lang eq 'vi_old') and
                         defined $fs->{vi_old} and
                         compare_segmented_text ($w, $fs->{vi_old})) {
                  if ($lang eq 'vi_old') {
                    $value_added = $v_added = 1;
                    next REP;
                  } elsif (not defined $fs->{vi}) {
                    $value_added = 1;
                    $value = $fg;
                    $v_added = 1;
                    $v = $fs;
                    delete $fs->{vi_old};
                    delete $fs->{vi_old_capital};
                    delete $fs->{vi_old_upper};
                    delete $fs->{vi_old_lower};
                    last CHK;
                  }
                } elsif ($fs->{form_set_type} eq 'chinese' and
                         ($lang eq 'nan_poj' or
                          $lang eq 'nan_wp' or
                          $lang eq 'nan_tl' or
                          $lang eq 'pinyin' or
                          $lang eq 'alalc')) {
                  if (not defined $fs->{$lang} and
                      $fs->{segment_length} == $w_length) {
                    $value_added = $v_added = 1;
                    $v = $fs;
                    last CHK;
                  }
                } elsif ($fs->{form_set_type} eq 'alphabetical' and
                         $lang eq 'en_pinyin' and
                         defined $fs->{en} and
                         compare_segmented_text ($w, $fs->{en})) {
                  if (defined $fs->{origin_lang} and
                      $fs->{origin_lang} eq 'zh_pinyin') {
                    $value_added = $v_added = 1;
                    next REP;
                  } elsif (not defined $fs->{origin_lang}) {
                    $fs->{origin_lang} = 'zh_pinyin';
                    $value_added = $v_added = 1;
                    next REP;
                  }
                } elsif ($fs->{form_set_type} eq 'alphabetical' and
                         $lang eq 'en' and
                         defined $fs->{en} and
                         compare_segmented_text ($w, $fs->{en})) {
                  $value_added = $v_added = 1;
                  next REP;
                } elsif ($fs->{form_set_type} eq 'alphabetical' and
                         ($lang eq 'en_la' or $lang eq 'la') and
                         not defined $fs->{origin_lang} and
                         not defined $fs->{$lang}) {
                  $value_added = $v_added = 1;
                  $v = $fs;
                  last CHK;
                } elsif ($fs->{form_set_type} eq 'alphabetical' and
                         ($lang eq 'en_old_zh' or
                          $lang eq 'es_old_zh' or
                          $lang eq 'fr_old_zh') and
                          defined $fs->{origin_lang} and
                          $fs->{origin_lang} eq 'zh') {
                  my $x = $lang;
                  $x =~ s/_zh$//;
                  if (not defined $fs->{$x} and
                      ((defined $fs->{en_old} and compare_segmented_text ($w, $fs->{en_old})) or
                       (defined $fs->{es_old} and compare_segmented_text ($w, $fs->{es_old})) or
                       (defined $fs->{fr_old} and compare_segmented_text ($w, $fs->{fr_old})))) {
                    $value_added = $v_added = 1;
                    $v = $fs;
                    last CHK;
                  }
                } elsif ($fs->{form_set_type} eq 'yomi' and
                         ($lang eq 'ja_latin' or
                          $lang eq 'ja_latin_old' or
                          $lang eq 'ja_latin_old_wrongs') and
                         defined $fs->{ja_latin} and
                         (compare_segmented_text ($w, $fs->{ja_latin_capital}) or
                          compare_segmented_text ($w, $fs->{ja_latin_upper}) or
                          compare_segmented_text ($w, $fs->{ja_latin_lower}))) {
                  $value_added = $v_added = 1;
                  next REP;
                } elsif ($fs->{segment_length} == $w_length and
                         not defined $rep->{abbr}) {
                  $mergeable = 1;
                }
              } # $fs
              if ($mergeable and
                  ($fg->{form_group_type} eq 'alphabetical' or
                   $fg->{form_group_type} eq 'han')) {
                $value = $fg;
                $value_added = 1;
                last CHK;
              }

              if ($fg->{form_group_type} eq 'han' and
                       ($fg->{form_sets}->[0]->{form_set_type} eq 'hanzi' or
                        $fg->{form_sets}->[0]->{form_set_type} eq 'yomi') and
                       not defined $rep->{abbr}) {
                my $fs = $fg->{form_sets}->[0];
                my $s = $fs->{cn} //
                    $fs->{jp} //
                    $fs->{tw} //
                    $fs->{kr} //
                    $fs->{ja_latin} // $fs->{kana} // $fs->{kr} // $fs->{kp} // $fs->{ko} // $fs->{vi} // $fs->{others}->[0] // die;
                my $s_length = @{[grep { not /^\./ } @$s]};
                if ($w_length == $s_length) {
                  $value = $fg;
                  $value_added = 1;
                  last;
                }
              }
            } # $fg
            $v->{form_set_type} = 'alphabetical';
            if ($lang eq 'ja_latin' or
                $lang eq 'ja_latin_old' or
                $lang eq 'ja_latin_old_wrong') {
              $value->{form_group_type} = 'ja' if not $value_added;
            } elsif ($lang eq 'vi' or
                     $lang eq 'vi_latin' or
                     $lang eq 'vi_old') {
              if ($lang eq 'vi') {
                my $v = [split /\s+/, $rep->{value}, -1];
                my $w = [map { to_nfc ucfirst lc $_ } grep { length } @$v];
                unless ((join ' ', @$v) eq (join ' ', @$w)) {
                  die "Bad |name(vi)| value: |$rep->{value}|";
                }
              }
              $value->{form_group_type} = 'vi' if not $value_added;
              $v->{form_set_type} = 'vietnamese';
              $lang = 'vi' if $lang eq 'vi_latin';
            } elsif ($lang eq 'nan_poj' or
                     $lang eq 'nan_wp' or
                     $lang eq 'nan_tl' or
                     $lang eq 'pinyin' or
                     $lang eq 'zh_alalc') {
              $value->{form_group_type} = 'han' if not $value_added;
              $v->{form_set_type} = 'chinese';
              $lang = 'nan_poj' if $lang eq 'nan_wp';
              # nan_poj  閩南語 白話字 (POJ)
              # nan_tl   閩南語 臺羅 (TL) : 臺灣閩南語羅馬字拼音方案
              # nan_wp   zh-min-nan.wikipedia.org 閩南語 白話字 (POJ)
            } elsif ($lang eq 'sinkan') {
              $value->{form_group_type} = 'han' if not $value_added;
              $v->{form_set_type} = 'sinkan';
              $v->{origin_lang} = 'zh';
            } elsif ($lang eq 'en_old_zh' or
                     $lang eq 'es_old_zh' or
                     $lang eq 'fr_old_zh') {
              $value->{form_group_type} = 'han' if not $value_added;
              $v->{origin_lang} = 'zh';
              $lang =~ s/_zh$//;
            } else {
              $value->{form_group_type} = 'alphabetical' if not $value_added;
              if ($lang eq 'fr_ja') {
                $lang = 'fr';
                $v->{origin_lang} = 'ja';
              } elsif ($lang eq 'en_pinyin') {
                $lang = 'en';
                $v->{origin_lang} = 'zh_pinyin';
              } elsif ($lang eq 'en_kr') {
                $lang = 'en';
                $v->{origin_lang} = 'kr';
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
              if ($lang eq 'nan_poj' or $lang eq 'nan_tl') {
                #$w = [map { $_ eq '-' ? '.-' : $_ } map { split /(-)/, $_ } @$w];
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
                #$w = [map { s/-$// ? ($_, '.-') : ($_) } @$w];
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
            $w_length = segmented_text_length $w;
            
            if ($lang eq 'ja_latin_old_wrong') {
              push @{$v->{$lang . 's'} ||= []}, $w;
            } elsif (not defined $v->{$lang}) {
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
          } elsif ($rep->{type} eq 'kana' or
                   ($rep->{type} eq 'jpan' and
                    $rep->{value} =~ /^[\p{sc=Hiragana}\p{sc=Katakana}|]+$/)) {
            for (@{$label->{form_groups}}) {
              if ($_->{form_group_type} eq 'han') {
                $value = $_;
                $value_added = 1;
              }
            }

            my $lang = $rep->{lang};
            $lang = 'vi_kana' if $lang eq 'vi_old';
            if ($lang eq 'ja' or $lang eq 'ja_old') {
              $value->{form_group_type} = 'kana' unless $value_added;

              my $w = [split /\|/, $rep->{value}];
              $v->{segment_length} = segmented_text_length $w;

              $v->{kana} = $w;
              if (defined $rep->{lang} and $rep->{lang} eq 'ja_old') {
                $v->{hiragana_classic} = [map { to_hiragana $_ } @$w];
              }
              
              $v->{form_set_type} = 'kana' unless $v_added;
            } elsif ($lang eq 'vi_kana') {
              $value->{form_group_type} = 'han' unless $value_added;

              use utf8;
              my $w = [map { /\s|\|/ ? '._' : $_ eq '・' ? '.・' : $_ } split /(\s+|\||・)/, $rep->{value}];
              $v->{segment_length} = segmented_text_length $w;
              
              for my $fs (@{$value->{form_sets}}) {
                if ($fs->{form_set_type} eq 'vietnamese' and
                    not defined $fs->{vi_katakana} and
                    $fs->{segment_length} == $v->{segment_length}) {
                  $v = $fs;
                  $v_added = 1;
                  #last; # use last match
                }
              }
              
              $v->{form_set_type} = 'vietnamese' unless $v_added;
              $v->{vi_katakana} = $w;
            } else {
              die "Unknown lang |$lang|";
            }
          } elsif ($rep->{type} eq 'jpan' or
                   $rep->{type} eq 'zh' or
                   ($rep->{type} eq 'korean' and
                    $rep->{value} =~ /\p{sc=Hang}/ and
                    $rep->{value} =~ /\p{sc=Han}/)) {
            my @value;
            while (length $rep->{value}) {
              use utf8;
              if ($rep->{value} =~ s/\A([\p{sc=Hiragana}\p{sc=Katakana}\x{1B001}-\x{1B11F}ー、][\p{sc=Hiragana}\p{sc=Katakana}\x{1B001}-\x{1B11F}ー、・|]*)//) {
                $value->{form_group_type} = 'kana';
                $v->{form_set_type} = 'kana';
                my $w = [map {
                  /^\s+$/ ? '._' : $_ eq "・" ? '.・' : $_ eq "、" ? '.・' : $_;
                } grep { length } split /([・、]|\s+)|\|/, $1];
                $v->{kana} = $w;
                if (defined $rep->{lang} and $rep->{lang} eq 'ja_old') {
                  $v->{hiragana_classic} = [map { to_hiragana $_ } @$w];
                }
                $v->{segment_length} = segmented_text_length $w;
                if ($rep->{value} =~ s/\A\[J:\]//) {
                  $value->{form_group_type} = 'ja';
                } elsif ($rep->{value} =~ s/\A\[\]//) {
                  #
                }
              } elsif ($rep->{value} =~ s/\A((?:\p{sc=Han}[\x{E0100}-\x{E01FF}]?|\|)+)//) {
                $value->{form_group_type} = 'han';
                $v->{form_set_type} = 'hanzi';
                my $w = [split //, $1];
                $v->{segment_length} = segmented_text_length $w;
                push @{$v->{others} ||= []}, $w;
                while ($rep->{value} =~ s/\A\[(!|)(J:|)(,*[\p{sc=Hiragana}\p{sc=Han}\x{1B001}-\x{1B11F}]+(?:[\s,]+[\p{sc=Hiragana}\p{sc=Han}\x{1B001}-\x{1B11F}]+)*)\]//) {
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
                      $v->{segment_length} = segmented_text_length $r;
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
                      if (/\p{sc=Han}/) {
                        push @{$rep->{hans} ||= []}, $_;
                      } else {
                        push @{$rep->{kana_others} ||= []}, $_;
                      }
                    }
                  }
                  fill_rep_yomi $rep;

                  $v->{form_set_type} = 'yomi';
                  fill_yomi_from_rep $rep => $v;
                  $v->{segment_length} = segmented_text_length $v->{latin};
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
                    $v->{segment_length} = segmented_text_length $r;
                    $r;
                  } @{$v->{others}}];
                }
              } elsif ($rep->{value} =~ s/\A([\p{sc=Latn}0-9]+)//) {
                my $w = [$1];
                my $key = {
                  en => 'en',
                  ja => 'ja_latin',
                  hk => 'en',
                }->{$rep->{lang}} // die $rep->{lang};
                $v->{form_set_type} = 'alphabetical';
                $value->{form_group_type} = {
                  ja_latin => 'ja',
                  hk => 'zh',
                }->{$key} // 'alphabetical';
                if (defined $v->{ja_latin}) {
                  push @{$v->{$key . '_others'} ||= []}, $w;
                } else {
                  $v->{$key} = $w;
                }
                $v->{segment_length} = segmented_text_length $w;
              } elsif ($rep->{value} =~ s/\A(\p{sc=Hang}+)//) {
                $value->{form_group_type} = 'korean';
                $v->{form_set_type} = 'korean';
                my $w = [split //, $1];
                $v->{segment_length} = segmented_text_length $w;
                $v->{$rep->{lang}} = $w;
              } elsif ($rep->{value} =~ s/\A([\p{Geometric Shapes}・\xB7\x{2015}-]+)//) {
                $value->{form_group_type} = 'symbols';
                $v->{form_set_type} = 'symbols';
                my $w = [{'・' => '.・', "\xB7" => ".・",
                          '-' => '.-'}->{$1} // $1];
                $v->{segment_length} = segmented_text_length $w;
                push @{$v->{others} ||= []}, $w;
              } elsif ($rep->{value} =~ s/\A\s*([(\x{300C}])//) {
                $value->{form_group_type} = 'symbols';
                $v->{form_set_type} = 'symbols';
                my $w = [{'(' => '.('}->{$1} // $1];
                $v->{segment_length} = segmented_text_length $w;
                push @{$v->{others} ||= []}, $w;
              } elsif ($rep->{value} =~ s/\A([)\x{300D}])\s*//) {
                $value->{form_group_type} = 'symbols';
                $v->{form_set_type} = 'symbols';
                my $w = [{')' => '.)'}->{$1} // $1];
                $v->{segment_length} = segmented_text_length $w;
                push @{$v->{others} ||= []}, $w;
              } elsif ($rep->{value} =~ s/\A\s*([:])\s*//) {
                $value->{form_group_type} = 'symbols';
                $v->{form_set_type} = 'symbols';
                my $w = [{':' => '.:'}->{$1} // $1];
                $v->{segment_length} = segmented_text_length $w;
                push @{$v->{others} ||= []}, $w;
              } elsif ($rep->{value} =~ s/\A\s+//) {
                $value->{form_group_type} = 'symbols';
                $v->{form_set_type} = 'symbols';
                my $w = ['._'];
                $v->{segment_length} = segmented_text_length $w;
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
                kr => 'kr',
                en => 'en',
              }->{$rep->{lang} // $rep->{type} // ''};
              if (defined $lang and not $has_preferred->{$lang}) {
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

            my $lang = {
              zh => 'bopomofo',
              nan => 'nan_bopomofo',
            }->{$rep->{lang}} // die $rep->{lang};
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
              $_ =~ /\s/ ? '._' : $_ eq '|' ? () : $_;
            } split /(\s+|\|)/, $rep->{value}];
            $v->{$lang} = $w;
            $v->{segment_length} = segmented_text_length $w;
          } elsif ($rep->{type} eq 'korean') { # Korean alphabet
            for (@{$label->{form_groups}}) {
              if ($_->{form_group_type} eq 'han' or
                  ($_->{form_group_type} eq 'ja' and
                   $rep->{lang} eq 'kr_ja')) {
                $value = $_;
                $value_added = 1;
              }
            }
            $value->{form_group_type} = 'korean' unless $value_added;

            my $lang = $rep->{lang};
            if ($lang =~ s/_(ja|vi)$//) {
              $v->{origin_lang} = $1;
            }
            
            my $w = [$rep->{value} =~ /\|/ ? split /\|/, $rep->{value} : split //, $rep->{value}];
            my $found = 0;
            for my $fs (@{$value->{form_sets}}) {
              if ($fs->{form_set_type} eq 'korean' and
                  defined $fs->{$lang} and
                  (join '', @{$fs->{$lang}}) eq (join '', @$w)) {
                if ($rep->{value} =~ /\|/) {
                  $v = $fs;
                  $v_added = 1;
                  delete $fs->{$lang};
                  delete $fs->{$lang . '_fukui'};
                } else {
                  $found = 1;
                }
                last;
              }
            }

            if ($found) {
              $v_added = 1;
            } else {
              $v->{form_set_type} = 'korean';
              if (not defined $v->{$lang}) {
                $v->{$lang} = $w;
                if (not $has_preferred->{$lang}) {
                  $v->{is_preferred}->{$lang} = 1;
                  $has_preferred->{$lang} = 1;
                }
              } else {
                push @{$v->{others} ||= []}, $w;
              }
              $v->{segment_length} = segmented_text_length $w;
              fixup_korean $v unless $rep->{value} =~ /\|/;
            }
          } elsif ($rep->{type} eq 'manchu') {
            $value->{form_group_type} = 'manchu';
            $v->{form_set_type} = 'manchu';
            for my $key (qw(manchu),
                         qw(moellendorff abkai xinmanhan)) { # latin
              $v->{$key} = [map { $_ =~ /\s/ ? '._' : $_ } split /(\s+)/, $rep->{$key}]
                  if defined $rep->{$key};
              $v->{segment_length} = segmented_text_length $v->{$key} if defined $v->{$key};
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
              $v->{segment_length} = segmented_text_length $v->{$key} if defined $v->{$key};
            }
          } else {
            die "Unknown type |$rep->{type}|";
          }

          if ($rep->{kind} eq 'name' or $rep->{kind} eq 'label') {
            $label->{props}->{is_name} = \1 unless $rep->{kind} eq 'label';
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

    unless ($label_added) {
      $label->{_IN} = $in if defined $in;
      push @$labels, $label;
    }
  } # reps_to_labels

  sub get_label_shorthands ($$);
  sub get_label_shorthands ($$) {
    my ($label => $shorts) = @_;

    for my $text (@{$label->{form_groups}}) {
        if ($text->{form_group_type} eq 'han' or
            $text->{form_group_type} eq 'ja' or
            $text->{form_group_type} eq 'kana') {
          my $jp_preferred = 0;
          for my $value (@{$text->{form_sets}}) {
            if ($value->{form_set_type} eq 'hanzi') {
              for my $lang (qw(jp tw cn)) {
                next if not defined $value->{$lang};

                my $sv = serialize_segmented_text $value->{$lang};
                if (not defined $label->{abbr} and
                    (not defined $shorts->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} or
                     ($value->{is_preferred} or {})->{$lang})) {
                  $jp_preferred = 1 if $lang eq 'jp';
                  $shorts->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} = $sv;
                  $shorts->{name} //= $shorts->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang};
                  $shorts->{name} = $shorts->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang}
                      if $jp_preferred;
                }
                if (defined $label->{abbr} and $label->{abbr} eq 'single') {
                  $shorts->{abbr} //= $sv;
                }
                $shorts->{names}->{$sv} = 1;
                if (not defined $label->{abbr}) {
                  $shorts->{_names}->{$lang}->{$sv} = 1;
                }
              } # $lang
              if (defined $value->{kr}) {
                my $sv = serialize_segmented_text $value->{kr};
                $shorts->{names}->{$sv} = 1;
                $shorts->{name} //= $sv;
                $shorts->{_name_kr} //= $sv;
                if (not defined $label->{abbr}) {
                  $shorts->{_names}->{kr}->{$sv} = 1;
                }
              }
              for (@{$value->{others} or []}) {
                my $sv = serialize_segmented_text $_;
                $shorts->{names}->{$sv} = 1;
                $shorts->{name} //= $sv;
                if (not defined $label->{abbr}) {
                  $shorts->{_names}->{_}->{$sv} = 1;
                }
              }
            } elsif ($value->{form_set_type} eq 'yomi' or
                     $value->{form_set_type} eq 'kana') {
              if ($value->{form_set_type} eq 'kana' and
                  defined $value->{kana}) {
                my $name = serialize_segmented_text $value->{kana};
                if (not defined $shorts->{name_ja} or
                    ($value->{is_preferred} or {})->{jp}) {
                  $shorts->{name_ja} = $name;
                  $shorts->{name} //= $shorts->{name_ja};
                }
                $shorts->{names}->{$name} = 1;
              }

              if (defined $value->{hiragana_modern}) {
                my $kana = serialize_segmented_text $value->{hiragana_modern};
                $shorts->{name_kana} //= $kana;
                $shorts->{name_kana} = $kana if $jp_preferred;
                $shorts->{name_kanas}->{$kana} = 1;

                my $latin = serialize_segmented_text $value->{ja_latin};
                $shorts->{name_latn} //= $latin;
                $shorts->{name_latn} = $latin if $jp_preferred;

                $jp_preferred = 0;
              }
            }
          } # $fs
        }
    } # $text
    
    for my $text (@{$label->{form_groups}}) {
      if ($text->{form_group_type} eq 'han' or
          $text->{form_group_type} eq 'ja' or
          $text->{form_group_type} eq 'vi' or
          $text->{form_group_type} eq 'korean') {
        for my $fs (@{$text->{form_sets}}) {
          if ($fs->{form_set_type} eq 'hanzi') {
            for my $lang (qw(tw jp cn)) {
              if (defined $fs->{$lang} and
                  not defined $label->{abbr} and
                  not defined $shorts->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang}) {
                $shorts->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} = serialize_segmented_text $fs->{$lang};
                $shorts->{name} //= $shorts->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang};
                $shorts->{name} = $shorts->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang}
                    if ($fs->{is_preferred} or {})->{$lang};
              }
            } # $lang
            for my $lang (@$LeaderKeys) {
              if (defined $fs->{$lang}) {
                my $v = serialize_segmented_text $fs->{$lang};
                $shorts->{names}->{$v} = 1 if defined $v;
              }
            } # $lang
          } elsif ($fs->{form_set_type} eq 'yomi' or
                   $fs->{form_set_type} eq 'kana') {
            if (defined $fs->{hiragana_modern}) {
                $shorts->{name_kana} //= serialize_segmented_text ($fs->{hiragana_modern});
              }
              for (grep { defined }
                   #$fs->{hiragana} // undef,
                   $fs->{hiragana_modern} // undef,
                   #$fs->{hiragana_classic} // undef,
                   #@{$fs->{hiragana_others} or []},
                  ) {
                my $v = serialize_segmented_text $_;
                $shorts->{name_kanas}->{$v} = 1;
              }

              if ($fs->{form_set_type} eq 'kana' and defined $fs->{kana}) {
                my $s = serialize_segmented_text $fs->{kana};
                $shorts->{name_ja} //= $s;
                $shorts->{name} //= $s;
                $shorts->{names}->{$s} = 1;
              }

              if (defined $fs->{ja_latin}) {
                $shorts->{name_latn} //= serialize_segmented_text $fs->{ja_latin};
            }
          } elsif ($fs->{form_set_type} eq 'korean') {
            for my $lang (qw(ko kr kp)) {
                if (defined $fs->{$lang} and
                    (not defined $shorts->{name_ko} or
                     ($fs->{is_preferred} or {})->{$lang})) {
                  $shorts->{name_ko} = serialize_segmented_text $fs->{$lang};
                  $shorts->{name} //= $shorts->{name_ko};
                }
            }
          } elsif ($fs->{form_set_type} eq 'chinese') {
            for my $lang (qw(pinyin nan_poj nan_tl)) {
                if (defined $fs->{$lang} and
                    (not defined $shorts->{name_latn})) {
                  my $v = serialize_segmented_text $fs->{$lang};
                  $shorts->{name_latn} //= $v;
                  $shorts->{name} //= $v;
                }
            }
          } elsif ($fs->{form_set_type} eq 'vietnamese') {
            for my $lang (qw(vi)) {
                if (defined $fs->{$lang} and
                    (not defined $shorts->{name_vi} or
                     ($fs->{is_preferred} or {})->{$lang})) {
                  $shorts->{name_vi} = serialize_segmented_text $fs->{$lang};
                  $shorts->{name_latn} //= $shorts->{name_vi};
                  $shorts->{name} //= $shorts->{name_vi};
                }
            }
          } elsif ($fs->{form_set_type} eq 'alphabetical') {
            if (defined $fs->{ja_latin}) {
              if ((not defined $shorts->{abbr_latn} or
                   ($fs->{is_preferred} or {})->{ja_latin}) and
                   defined $label->{abbr} and
                   $label->{abbr} eq 'single') {
                $shorts->{abbr_latn} = serialize_segmented_text $fs->{ja_latin};
              }

              if (not defined $label->{abbr}) {
                $shorts->{name_latn} //= serialize_segmented_text $fs->{ja_latin};
                $shorts->{name} //= $shorts->{name_latn};
              }
            }
            
              if (defined $fs->{en} and
                  (not defined $shorts->{name_en} or
                   ($fs->{is_preferred} or {})->{en})) {
                $shorts->{name_en} = serialize_segmented_text $fs->{en};
                $shorts->{name_latn} //= $shorts->{name_en};
                $shorts->{name} //= $shorts->{name_en};
              }
          }
        } # $fs
      } elsif ($text->{form_group_type} eq 'kana') {
        for my $fs (@{$text->{form_sets}}) {
          if ($fs->{form_set_type} eq 'kana') {
            if (defined $fs->{ja_latin}) {
              $shorts->{name_latn} //= serialize_segmented_text $fs->{ja_latin};
            }
          }
        } # $fs
      } elsif ($text->{form_group_type} eq 'alphabetical') {
        for my $fs (@{$text->{form_sets}}) {
          if ($fs->{form_set_type} eq 'alphabetical') {
            if (defined $fs->{en} and
                  (not defined $shorts->{name_en} or
                   ($fs->{is_preferred} or {})->{en})) {
                $shorts->{name_en} = serialize_segmented_text $fs->{en};
                $shorts->{name_latn} //= $shorts->{name_en};
                $shorts->{name} //= $shorts->{name_en};
              }
          }
        } # $fs
      } elsif ($text->{form_group_type} eq 'symbols') {
        for my $fs (@{$text->{form_sets}}) {
          my $v = serialize_segmented_text ($fs->{others}->[0] // die);
          $shorts->{name_ja} = $v;
          $shorts->{name_cn} = $v;
          $shorts->{name_tw} = $v;
          $shorts->{name_ko} = $v;
          $shorts->{name_en} = $v;
          $shorts->{name_latn} = $v;
          $shorts->{name} = $v;
          $shorts->{name_kana} = '';
        }
      } elsif ($text->{form_group_type} eq 'compound') {
        my $cur;
        for my $item_fg (@{$text->{items}}) {
          my $ss = {};
          get_label_shorthands ({form_groups => [$item_fg]} => $ss);
          if (defined $cur) {
            for (qw(name_ja name_cn name_tw name_ko name_latn name_en
                    name_kana)) {
              if (defined $cur->{$_} and defined $ss->{$_}) {
                $cur->{$_} .= ' ' if {
                  name_ko => 1, name_latn => 1, name_en => 1,
                }->{$_} and length $cur->{$_} and length $ss->{$_};
                $cur->{$_} .= $ss->{$_};
              } elsif ($_ eq 'name_ja' and not defined $ss->{$_} and
                       defined $cur->{$_} and defined $ss->{name_en}) {
                $cur->{$_} .= $ss->{name_en};
              } elsif ($_ eq 'name_ja' and not defined $ss->{$_} and
                       defined $cur->{$_} and defined $ss->{name_latn}) {
                $cur->{$_} .= $ss->{name_latn};
              } elsif ($_ eq 'name_ja' and defined $ss->{$_} and
                       not defined $cur->{$_} and defined $cur->{name_en}) {
                $cur->{$_} = $cur->{name_en} . $ss->{$_};
              } elsif ($_ eq 'name_ja' and defined $ss->{$_} and
                       not defined $cur->{$_} and defined $cur->{name_latn}) {
                $cur->{$_} = $cur->{name_latn} . $ss->{$_};
              } elsif ($_ eq 'name_ja' and not defined $ss->{$_} and
                       defined $cur->{$_} and defined $ss->{name_tw}) {
                $cur->{$_} .= $ss->{name_tw};
              } elsif ($_ eq 'name_ja' and defined $ss->{$_} and
                       not defined $cur->{$_} and defined $cur->{name_tw}) {
                $cur->{$_} = $cur->{name_tw} . $ss->{$_};
              } elsif ($_ eq 'name_ja' and not defined $ss->{$_} and
                       defined $cur->{$_} and defined $ss->{name_cn}) {
                $cur->{$_} .= $ss->{name_cn};
              } elsif ($_ eq 'name_ja' and defined $ss->{$_} and
                       not defined $cur->{$_} and defined $cur->{name_cn}) {
                $cur->{$_} = $cur->{name_cn} . $ss->{$_};
              } elsif ($_ eq 'name_ko' and not defined $ss->{$_} and
                       defined $cur->{$_} and defined $ss->{_name_kr}){
                $cur->{$_} .= $ss->{_name_kr};
              } else {
                delete $cur->{$_};
              }
            }
          } else {
            $cur = $ss;
          }
        } # $item_fg

        for (qw(name_ja name_cn name_tw)) {
          $shorts->{names}->{$cur->{$_}} = 1 if defined $cur->{$_};
        }
        if (defined $cur->{name_ja} and
            (not defined $shorts->{name_ja} or
             ($text->{is_preferred} or {})->{jp})) {
          $shorts->{name_ja} = $cur->{name_ja};
          $shorts->{name} //= $shorts->{name_ja};
          $shorts->{name} = $shorts->{name_ja}
              if ($text->{is_preferred} or {})->{jp};
        }
        if (defined $cur->{name_kana}) {
          if (not defined $shorts->{name_kana} or
              ($text->{is_preferred} or {})->{jp}) {
            $shorts->{name_kana} = $cur->{name_kana};
          }
          $shorts->{name_kanas}->{$cur->{name_kana}} = 1;
        }
        if (defined $cur->{name_latn} and
            ((not defined $shorts->{name_latn} or
              ($text->{is_preferred} or {})->{jp}))) {
          $shorts->{name_latn} = $cur->{name_latn};
        }
        if (defined $cur->{name_cn} and
            ($text->{is_preferred} or {})->{cn}) {
          $shorts->{name_cn} = $cur->{name_cn};
          $shorts->{name} //= $shorts->{name_cn};
        }
        if (defined $cur->{name_tw} and
            ($text->{is_preferred} or {})->{tw}) {
          $shorts->{name_tw} = $cur->{name_tw};
          $shorts->{name} //= $shorts->{name_tw};
        }
        if (defined $cur->{name_ko} and
            ($text->{is_preferred} or {})->{kr}) {
          $shorts->{name_ko} = $cur->{name_ko};
          $shorts->{name} = $shorts->{name_ko}
              if ($text->{is_preferred} or {})->{kr};
        }
      } # form_group_type
    } # form group
  } # get_label_shorthands

  sub process_object_labels ($$$$$$) {
    my ($objects, $set_label_props,
        $get_object_tag, $set_object_tag, $out_errors) = @_;
    
    for my $object (@$objects) {
      my $has_preferred = {};
      for my $label_set (@{$object->{_LABELS}}) {
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

      $object->{label_sets} = [];
      for my $label_set (@{$object->{_LABELS}}) {
        my $new_label_set = {labels => []};
        reps_to_labels $object, [map {
          ({in => $_},
           @{$_->{reps}},
           {next_label => 1});
        } @{$label_set->{labels}}] => $new_label_set->{labels}, $has_preferred,
            $get_object_tag, $set_object_tag;
        $new_label_set->{labels} = filter_labels $new_label_set->{labels};
        push @{$object->{label_sets}}, $new_label_set if @{$new_label_set->{labels}};
      }
    } # $object

    for my $object (@$objects) {
      for my $label_set (@{$object->{label_sets}}) {
        for my $label (@{$label_set->{labels}}) {
          
          for my $text (@{$label->{form_groups}}) {
          if ($text->{form_group_type} eq 'han' or
              $text->{form_group_type} eq 'ja' or
              $text->{form_group_type} eq 'kana' or
              $text->{form_group_type} eq 'vi' or
              $text->{form_group_type} eq 'korean') {
            for my $fs (@{$text->{form_sets}}) {
              if ($fs->{form_set_type} eq 'hanzi') {
                fill_han_variants $fs;
              } elsif ($fs->{form_set_type} eq 'kana') {
                fill_kana $fs;

                if ($label->{props}->{is_name} and defined $fs->{kana}) {
                  use utf8;
                  $set_object_tag->($object, '仮名名');
                }
              } elsif ($fs->{form_set_type} eq 'korean') {
                fill_korean $fs;
              } elsif ($fs->{form_set_type} eq 'chinese') {
                fill_chinese $fs;
              } elsif ($fs->{form_set_type} eq 'vietnamese') {
                fill_alphabetical $fs;
              } elsif ($fs->{form_set_type} eq 'alphabetical') {
                fill_alphabetical $fs;
              }
            } # $fs
            my $fst = {
              'chinese' . $; . '' => 'han_100',
              'sinkan' . $; . 'zh' => 'han_101',
              'alphabetical' . $; . 'zh' => 'han_102',
              #
              'yomi' . $; . '' => 'han_200',
              'korean' . $; . 'ja' => 'han_201',
              'alphabetical' . $; . 'ja' => 'han_202',
              #
              'vietnamese' . $; . '' => 'han_300',
              'korean' . $; . 'vi' => 'han_301',
              'alphabetical' . $; . 'vi' => 'han_302',
              #
              'korean' . $; . '' => 'han_400',
              #
              'alphabetical' . $; . '' => 'han_700',
            };
            $text->{form_sets} = [sort {
              ($fst->{$a->{form_set_type}, $a->{origin_lang} // ''} || 0) cmp ($fst->{$b->{form_set_type}, $b->{origin_lang} // ''} || 0);
            } @{$text->{form_sets}}];
          } elsif ($text->{form_group_type} eq 'kana') {
            for my $fs (@{$text->{form_sets}}) {
              if ($fs->{form_set_type} eq 'kana') {
                fill_kana $fs;
              }
            } # $fs
          } elsif ($text->{form_group_type} eq 'alphabetical') {
            for my $fs (@{$text->{form_sets}}) {
              if ($fs->{form_set_type} eq 'alphabetical') {
                fill_alphabetical $fs;
              }
            } # $fs
            } elsif ($text->{form_group_type} eq 'compound') {
              my $has_han = 0;
              my $has_kana = 0;
              my $has_non_kanakan = 0;
              for my $item_fg (@{$text->{items}}) {
                if ($item_fg->{form_group_type} eq 'han' or
                    $item_fg->{form_group_type} eq 'ja' or
                    $item_fg->{form_group_type} eq 'vi' or
                    $item_fg->{form_group_type} eq 'kana' or
                    $item_fg->{form_group_type} eq 'korean' or
                    $item_fg->{form_group_type} eq 'alphabetical') {
                  for my $item_fs (@{$item_fg->{form_sets}}) {
                    if ($item_fs->{form_set_type} eq 'hanzi') {
                      fill_han_variants $item_fs;
                      $has_han = 1;
                    } elsif ($item_fs->{form_set_type} eq 'kana' or
                             $item_fs->{form_set_type} eq 'yomi') {
                      if ($item_fs->{form_set_type} eq 'kana') {
                        fill_kana $item_fs;
                        use utf8;
                        unless (defined $item_fs->{kana} and
                                @{$item_fs->{kana}} == 1 and
                                $item_fs->{kana}->[0] eq '.・') {
                          $set_object_tag->($object, '仮名名');
                          $has_kana = 1;
                        }
                      }
                    } elsif ($item_fs->{form_set_type} eq 'alphabetical' or
                             $item_fs->{form_set_type} eq 'vietnamese') {
                      fill_alphabetical $item_fs;
                      $has_non_kanakan = 1;
                    } elsif ($item_fs->{form_set_type} eq 'korean') {
                      fill_korean $item_fs;
                      $has_non_kanakan = 1;
                    } else {
                      $has_non_kanakan = 1;
                    }
                  } # $item_fs
                } elsif ($item_fg->{form_group_type} eq 'symbols') {
                  use utf8;
                  $set_object_tag->($object, '記号名');
                }
              } # $item_fg

              use utf8;
              $set_object_tag->($object, '複合名');
              if ($has_kana and $has_han and not $has_non_kanakan) {
                $set_object_tag->($object, '仮名漢字混じり名');
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
          } # form group
        }
      } # $label_set

      for my $ls (@{$object->{label_sets}}) {
        for my $label (@{$ls->{labels}}) {
          my $abbr = undef;
          for my $fg (@{$label->{form_groups}}) {
            my $fg_abbr = $fg->{abbr} // '';
            $abbr //= $fg_abbr;
            if (not $abbr eq $fg_abbr) {
              die "Era |$object->{key}|: Label |abbr| conflict: |$abbr| vs |$fg_abbr|";
            }
            delete $fg->{abbr};
          }
          if (defined $abbr and length $abbr) {
            $label->{abbr} = $abbr;
          }
        }
      }

      if (defined $object->{_LSX}) {
        push @{$object->{label_sets}}, @{$object->{_LSX}};
      }
      for my $label_set (@{$object->{label_sets}}) {
        for my $label (@{$label_set->{labels}}) {
          $set_label_props->($object, $label);

          delete $label->{_IN};
        } # $label
      } # $label_set
      
      {
        my $fg_datas = [];
        for my $ls (@{$object->{label_sets}}) {
          for my $label (@{$ls->{labels}}) {
            for my $fg (@{$label->{form_groups}}) {
              if ($fg->{form_group_type} eq 'compound') {
                for my $item_fg (@{$fg->{items}}) {
                  my $r = compute_form_group_ons $item_fg, $out_errors;
                  push @$fg_datas, $r if defined $r;
                }
              } else {
                my $r = compute_form_group_ons $fg, $out_errors;
                push @$fg_datas, $r if defined $r;
              }
            }
          }
        }
        $object->{_FORM_GROUP_ONS} = $fg_datas;
      }
      
      delete $object->{_LABELS};
    } # $object
  } # process_object_labels
}

1;

## License: Public Domain.
