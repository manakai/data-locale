use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
binmode STDOUT, qw(:encoding(utf-8));

my $RootPath = path (__FILE__)->parent->parent;

my $Data;
{
  my $path = $RootPath->child ('data/calendar/era-yomi-sources.json');
  $Data = json_bytes2perl $path->slurp;
}

sub htescape ($) {
  my $s = shift;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/"/&quot;/g;
  return $s;
} # htescape

{
  use utf8;

  sub to_hiragana ($) {
    use utf8;
    my $s = shift;
    $s =~ tr/アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォッャュョヮ/あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎ/;
    return $s;
  } # to_hiragana
  
  my $L2K = {qw(
    a あ i い u う e え o お
    ka か ki き ku く ke け ko こ
    sa さ si し su す se せ so そ
    ta た ti ち tu つ te て to と
    na な ni に nu ぬ ne ね no の
    ha は hi ひ hu ふ he へ ho ほ
    ma ま mi み mu む me め mo も
    ya や yu ゆ yo よ
    ra ら ri り ru る re れ ro ろ
    wa わ wi ゐ we ゑ wo を
    n ん m ん
    ga が gi ぎ gu ぐ ge げ go ご
    za ざ zi じ zu ず ze ぜ zo ぞ
    da だ di ぢ du づ de で do ど
    ba ば bi び bu ぶ be べ bo ぼ
    pa ぱ pi ぴ pu ぷ pe ぺ po ぽ
    kya きゃ kyu きゅ kyo きょ
    gya ぎゃ gyu ぎゅ gyo ぎょ
    sya しゃ syu しゅ syo しょ
    zya じゃ zyu じゅ zyo じょ
    tya ちゃ tyu ちゅ tyo ちょ
    bya びゃ byu びゅ byo びょ
    pya ぴゃ pyu ぴゅ pyo ぴょ
    rya りゃ ryu りゅ ryo りょ
  )};

  sub to_key ($) {
    my $key = to_hiragana shift;
    $key =~ tr/A-Z\x{014C}/a-z\x{014D}/;
      $key =~ s/shi/し/g;
      $key =~ s/shu/しゅ/g;
      $key =~ s/sho/しょ/g;
      $key =~ s/chi/ち/g;
      $key =~ s/cho/ちょ/g;
      $key =~ s/chu/ちゅ/g;
      $key =~ s/tsu/つ/g;
      $key =~ s/ji/じ/g;
      $key =~ s/ju/じゅ/g;
      $key =~ s/ja/じゃ/g;
      $key =~ s/jo/じょ/g;
      $key =~ s/f[\x{F4}\x{014D}]/ふう/g;
      $key =~ s/fu/ふ/g;
      $key =~ s/ch[\x{F4}\x{014D}]/ちょう/g;
      $key =~ s/ty[\x{F4}\x{014D}]/ちょう/g;
      $key =~ s/sh[\x{F4}\x{014D}]/しょう/g;
      $key =~ s/sy[\x{F4}\x{014D}]/しょう/g;
      $key =~ s/j[\x{F4}\x{014D}]/じょう/g;
      $key =~ s/zy[\x{F4}\x{014D}]/じょう/g;
      $key =~ s/n[\x{F4}\x{014D}]/のう/g;
      $key =~ s/h[\x{F4}\x{014D}]/ほう/g;
      $key =~ s/k[\x{F4}\x{014D}]/こう/g;
      $key =~ s/t[\x{F4}\x{014D}]/とう/g;
      $key =~ s/d[\x{F4}\x{014D}]/どう/g;
      $key =~ s/b[\x{F4}\x{014D}]/ぼう/g;
      $key =~ s/p[\x{F4}\x{014D}]/ぽう/g;
      $key =~ s/r[\x{F4}\x{014D}]/ろう/g;
      $key =~ s/gy[\x{F4}\x{014D}]/ぎょう/g;
      $key =~ s/ky[\x{F4}\x{014D}]/きょう/g;
      $key =~ s/by[\x{F4}\x{014D}]/びょう/g;
      $key =~ s/py[\x{F4}\x{014D}]/ぴょう/g;
      $key =~ s/y[\x{F4}\x{014D}]/よう/g;
      $key =~ s/ch[\x{FB}\x{016B}]/ちゅう/g;
      $key =~ s/ty[\x{FB}\x{016B}]/ちゅう/g;
      $key =~ s/ky[\x{FB}\x{016B}]/きゅう/g;
      $key =~ s/zy[\x{FB}\x{016B}]/じゅう/g;
      $key =~ s/\x{016B}/uu/g;
      #$key =~ s/\x{012B}/ii/g;
      $key =~ s/([kstnhmrgzdbp][aiueo])/$L2K->{$1}/g;
      $key =~ s/([kgsztpbr]y[auo])/$L2K->{$1}/g;
      $key =~ s/(y[auo])/$L2K->{$1}/g;
      $key =~ s/(w[aieo])/$L2K->{$1}/g;
      $key =~ s/([aiueonm])/$L2K->{$1}/g;
      $key =~ s/[\x{F4}\x{014D}]/おう/g;
      $key =~ tr/ゃゅょ/やゆよ/;
    $key =~ s/[ '’-]//g;
    return $key;
  } # to_key
}

sub pattern ($$) {
  my ($v, $list) = @_;
  $v =~ s{^[^()]+ \(([^()]+)\)$}{$1};
  $v = to_key $v;
  if (defined $list->{$v}) {
    return $list->{$v};
  } else {
    return $list->{$v} = 1+keys %$list;
  }
} # pattern

print q{<!DOCTYPE HTML><meta charset=utf-8><title>Era yomis</title>
<!--

Per CC0 <https://creativecommons.org/publicdomain/zero/1.0/>, to the
extent possible under law, the author of this document has waived all
copyright and related or neighboring rights to this document.

-->
<style>
  html {
    font-size: 80%;
  }

  table {
    border-collapse: collapse;
  }

  .kana-old,
  .latin-old {
    background: #eee;
    color: black;
  }
  .wrong {
    background: #fee;
    color: black;
  }

  thead {
    position: sticky;
    top: 0;
    z-index: 100;
  }

  th {
    border: 1px solid white;
    color: white;
    background: black;
    vertical-align: top;
  }

  thead th {
    padding: 5px 1px;
    writing-mode: vertical-lr;
    text-orientation: sideways-right;
    vertical-align: middle;
    text-align: start;
    transform: rotate(180deg);
  }

  thead th:first-child,
  tbody th {
    position: sticky;
    left: 0;
  }

  td {
    border: 1px solid #ccc;
    writing-mode: vertical-lr;
    vertical-align: top;
    max-width: 10em;
    overflow: auto;
  }

  th:last-child {
    position: sticky;
    right: 0;
  }
  
  td:last-child {
    position: sticky;
    right: 0;
    background: #fee;
    color: black;
  }

  th a {
    color: inherit;
    background: transparent;
  }

  .info {
    margin: 0;
    font-weight: normal;
    font-size: 80%;
  }

  td p {
    margin: 0;
  }

  .pattern-1 { background-color: #ffdddd }
  .pattern-2 { background-color: #ffffdd }
  .pattern-3 { background-color: #ddffdd }
  .pattern-4 { background-color: #dde5ff }
  .pattern-5 { background-color: #ffcccc }
  .pattern-6 { background-color: #cc99cc }
  .pattern-7 { background-color: #FFEFD5 }
  .pattern-8 { background-color: #E0FFFF }
  .pattern-9 { background-color: #98FB98 }
  .pattern-10 { background-color: #ADD8E6 }
  .pattern-11 { background-color: #F0E68C }
  .pattern-12 { background-color: #FFA07A }

  .not-equal-primary {
    color: red;
    background: transparent;
  }

</style>
<h1>Era yomis</h1>

<p>[<a href=era-names.html>Names</a> <a href=era-yomis.html>Yomis</a>
<a href=era-kanjions.html>Kanji-ons</a>] [<a
href=https://wiki.suikawiki.org/n/%E5%85%83%E5%8F%B7%E3%81%AE%E8%AA%AD%E3%81%BF%E6%96%B9>Notes</a>]

<p class=info>This document is generated from <a
href=../data/calendar/era-yomi-sources.json><code>data/calendar/era-yomi-sources.json</code></a>.

<table><colgroup>};

print q{<col>};
for my $source_id (@{$Data->{source_ids}}) {
  my @class;
  push @class, 'kana-old' if $Data->{sources}->{$source_id}->{is_kana_old};
  push @class, 'latin-old' if $Data->{sources}->{$source_id}->{is_latin_old};
  push @class, 'wrong' if $Data->{sources}->{$source_id}->{is_wrong} or
                          $Data->{sources}->{$source_id}->{non_native};
  printf q{<col class="%s">}, join ' ', @class;
}
print q{<col class="wrong">};

print q{<thead><tr><th>Era};

for my $source_id (@{$Data->{source_ids}}) {
  printf qq{<th><a href="%s">#%d</a>\n},
      $Data->{sources}->{$source_id}->{suikawiki_url},
      $source_id;
}
printf q{<th>Missing in ours};

print q{<tbody>};

for my $era (sort {
  ($a->{start_year} || 0+"Inf") <=> ($b->{start_year} || 0+"Inf") ||
  $a->{id} <=> $b->{id};
} values %{$Data->{eras}}) {
  printf qq{\x0A<tr><th><a href=https://data.suikawiki.org/e/%d/><code>y~%s</code></a><p class=info>(<code>%s</code>)<p class=info>[%s]\x0A},
      $era->{id},
      $era->{id},
      $era->{key},
      $era->{name};

  my $patterns = {};

  for my $source_id (@{$Data->{source_ids}}) {
    print q{<td>};
    for my $value (@{$era->{yomis}->{$source_id} or []}) {
      my $pp = pattern ($value, $patterns);
      printf q{<p><data class="pattern-%d">%s</data>},
          $pp,
          htescape $value;
      if ($source_id == 6011 and $pp != 1) {
        printf q{ <span class=not-equal-primary>!!</span>};
      } elsif ($source_id == 6031 and $pp != 1) {
        printf q{ <span class=not-equal-primary>!?</span>};
      }
    }
  }

  print q{<td>};
  for my $value (@{$era->{missing_yomis}}) {
    printf q{<p><data class="pattern-%d">%s</data>},
        pattern ($value, $patterns),
        htescape $value;
  }
  if (@{$era->{missing_yomis}}) {
    printf q{ <span class=not-equal-primary>!x</span>};
  }
}

print q{
</table>

<sw-ads normal></sw-ads>
<script src="https://manakai.github.io/js/global.js" async></script>
};

## License: Public Domain.
