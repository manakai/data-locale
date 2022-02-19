use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent;
binmode STDOUT, qw(:encoding(utf-8));

my $Data;
{
  my $path = $RootPath->child ('local/calendar-era-defs-0.json');
  $Data = json_bytes2perl $path->slurp;
}

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

sub htescape ($) {
  my $s = shift;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/"/&quot;/g;
  return $s;
} # htescape

  sub on_html ($$) {
    my ($on, $ons) = @_;
    if (defined $ons) {
      my $on2 = to_contemporary_kana $on;
      my $v = sprintf '<span class="%s %s %s %s">%s</span>',
          $ons->{kans}->{$on} ? 'kan' : '',
          $ons->{gos}->{$on} ? 'go' : '',
          ($ons->{kan_cs}->{$on} or $ons->{kan_cs}->{$on2}) ? 'kan-contemporary' : '',
          ($ons->{go_cs}->{$on} or $ons->{go_cs}->{$on2}) ? 'go-contemporary' : '',
          $on;
      if (not $ons->{kans}->{$on} and
          not $ons->{gos}->{$on} and
          not $ons->{kan_cs}->{$on} and
          not $ons->{go_cs}->{$on} and
          not $ons->{kan_cs}->{$on2} and
          not $ons->{go_cs}->{$on2}) {
        $v .= q{ <v-error>(no match)</v-error>};
      }
      return $v;
    } else {
      return sprintf '%s <v-error>(no data)</v-error>',
          $on;
    }
  } # on_html

print q{
<!DOCTYPE HTML>
<meta charset=utf-8>
<title>Yomi</title>
<style>

  table {
    border-collapse: collapse;
  }

  th {
    border: 1px solid white;
    color: white;
    background: black;
    vertical-align: top;
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

  body > table > tbody > td {

  }

  .form-group {
    display: inline-table;
    margin: .5em;
    border-collapse: collapse;
    writing-mode: vertical-lr;
    line-height: 1.0;
    vertical-align: top;
  }

  .form-set {
    border: 1px solid gray;
  }

  .form-set-hanzi {
    background: #eee;
    color: black;
  }

  .form-set th {
    padding: .5em;
    background: black;
    color: white;
    border-color: white;
    text-align: end;
  }

  .form-set td {
    min-height: 3em;
    text-align: center;
  }

  .kan-contemporary { background: #ffffad; color: black }
  .go-contemporary { background: #01d301; color: black }
  .kan-contemporary.go-contemporary { background: #e9ffbd; color: black }
  .kan { background: yellow; color: black }
  .go { background: green; color: white }
  .kan.go { background: yellowgreen; color: black }

  .on-type td {
    writing-mode: horizontal-tb;
  }

  .on-counts span {
    writing-mode: horizontal-tb;
  }

  v-error {
    display: block;
    color: red;
    background: white;
  }
</style>

<p>[<a href=era-names.html>Names</a> <a href=era-yomis.html>Yomis</a>
<a href=era-kanjions.html>Kanji-ons</a>] [<a
href=https://wiki.suikawiki.org/n/%E5%85%83%E5%8F%B7%E3%81%AE%E8%AA%AD%E3%81%BF%E6%96%B9>Notes</a>]

<p class=info>This document is generated from <a
href=../data/calendar/era-defs.json><code>data/calendar/era-defs.json</code></a>.

<table>
  <tbody>
};

for my $era (sort {
  ($a->{offset} || 0+"Inf") <=> ($b->{offset} || 0+"Inf") ||
  $a->{id} <=> $b->{id};
} values %{$Data->{eras}}) {
  next unless @{$era->{_FORM_GROUP_ONS} or []};

  printf qq{<tr><th><a href=https://data.suikawiki.org/e/%d/><code>y~%s</code></a><p class=info>(<code>%s</code>)<p class=info>[%s]\n},
      $era->{id},
      $era->{id},
      $era->{key},
      $era->{name};

  print q{<td>};
  for my $fg_data (@{$era->{_FORM_GROUP_ONS}}) {
    print q{<table class=form-group>};
    my $onses = $fg_data->{onses};

    for my $fs_data (@{$fg_data->{hanzis}}) {
      print qq{\n};
      print q{<tbody class="form-set form-set-hanzi"><tr><th>Kanji};

      for (@{$fs_data->{chars}}) {
        print q{<td>};
        print htescape $_;
      }
      
      my $fs_onses = $fs_data->{onses};
      for (
        ['kans', 'Kan-on'],
        ['kan_cs', 'Kan-on(c)'],
        ['gos', 'Go-on'],
        ['go_cs', 'Go-on(c)'],
      ) {
        my ($ons_key, $label) = @$_;
        print qq{\n};
        print q{<tr><th>}, $label;
        for (0..$#{$fs_data->{chars}}) {
          my $fs_ons = $fs_onses->[$_];
          my $ons = $onses->[$_];
          if (defined $fs_ons) {
            print q{<td>};
            for (sort { $a cmp $b } keys %{$fs_ons->{$ons_key}}) {
              print ' ' . on_html $_, $ons;
            }
          } else {
            print q{<td><v-error>(no data)</v-error>};
          }
        }
      }
    } # $fs_data

    for my $fs_data (@{$fg_data->{yomis}}) {
      print qq{<tbody class="form-set form-set-yomi">\n};
      
      for (@{$fs_data->{fields}}) {
        my ($type, $kanas) = @$_;
        my $tt = {
          hiragana_modern => q{Modern},
          hiragana_classic => q{Classic},
          hiragana_others => q{Other},
          hiragana_wrongs => q{Wrong},
        }->{$type} // $type;
        print q{<tr><th>}, $tt;
        for (0..$#$kanas) {
          my $ons = $onses->[$_];
          print q{<td>};
          print on_html $kanas->[$_], $ons;
        }
      }

      print qq{\n};
      print q{<tr class=on-counts><th>Counts};
      my $x = q{<tr class=on-type><th>Types};
      for (0..$#$onses) {
        my $count = $fs_data->{counts}->[$_];
        my $ons = $onses->[$_];
        print q{<td>};
        if (defined $ons and $ons->{kan_eq_go}) {
          printf q{<span>K/G:%d</span>},
              $count->{kans} if $count->{kans};
        } else {
          printf q{<span>K:%d</span>},
              $count->{kans} if $count->{kans};
          printf q{<span>G:%d</span>},
              $count->{gos} if $count->{gos};
        }
        if (defined $ons and $ons->{kan_c_eq_go_c}) {
          printf q{<span>Kc/Gc:%d</span>},
              $count->{kan_cs} if $count->{kan_cs};
        } else {
          printf q{<span>Kc:%d</span>},
              $count->{kan_cs} if $count->{kan_cs};
          printf q{<span>Gc:%d</span>},
              $count->{go_cs} if $count->{go_cs};
        }
        if (($count->{kans} or $count->{kan_cs}) and
            ($count->{gos} or $count->{go_cs})) {
          unless ($ons->{kan_eq_go}) {
            print q{<span>(mixed)</span>};
          }
        }
        my $type = $fs_data->{types}->[$_] // '';
        use utf8;
        if ($type eq 'KG') {
          $x .= q{<td class="kan go">漢~呉};
        } elsif ($type eq 'K') {
          $x .= q{<td class=kan>漢};
        } elsif ($type eq 'G') {
          $x .= q{<td class=go>呉};
        } else {
          $x .= q{<td><v-error>?</v-error>};
        }
      }
      print $x;
    } # $fs_data
    
    print qq{</table>\n};
  }
} # $era

print q{
</table>

<section>
  <h1>Kanji-on data not found</h1>
};

for my $c (sort { $a cmp $b } keys %{$Data->{_ONS}->{_errors}->{not_found_chars}}) {
  printf q{ %s},
      $c;
}

print q{</section>
<!--

Per CC0 <https://creativecommons.org/publicdomain/zero/1.0/>, to the
extent possible under law, the author of this document has waived all
copyright and related or neighboring rights to this document.

-->
};

## License: Public Domain.
