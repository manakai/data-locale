use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent;
binmode STDOUT, qw(:encoding(utf-8));

my $Mode = shift or die;

print STDERR "\rLoading...";
my $Eras;
if ($Mode eq 'eras') {
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  $Eras = $json;
}
if ($Mode eq 'eras') {
  my $path = $RootPath->child ('local/calendar-era-labels-0.json');
  my $in_json = json_bytes2perl $path->slurp;
  for my $in_era (values %{$in_json->{eras}}) {
    $Eras->{eras}->{$in_era->{key}}->{label_sets} = $in_era->{label_sets};
  }
}

my $Tags;
{
  my $path = $RootPath->child ('data/tags.json');
  my $json = json_bytes2perl $path->slurp;
  $Tags = $json;
}
if ($Mode eq 'tags') {
  my $path = $RootPath->child ('local/tag-labels-0.json');
  my $in_json = json_bytes2perl $path->slurp;
  for my $in_tag (values %{$in_json->{tags}}) {
    $Tags->{tags}->{$in_tag->{id}}->{label_sets} = $in_tag->{label_sets};
  }
}
print STDERR "\rLoaded!";

sub pattern ($$) {
  my ($v, $list) = @_;
  if (defined $list->{$v}) {
    return $list->{$v};
  } else {
    return $list->{$v} = 1+keys %$list;
  }
} # pattern

sub htescape ($) {
  my $s = shift;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/"/&quot;/g;
  return $s;
} # htescape

print q{<!DOCTYPE html>
<meta charset=utf-8>};

if ($Mode eq 'eras') {
  print q{<title>Era names</title>};
} elsif ($Mode eq 'tags'){
  print q{<title>Tag names</title>};
}

print q{
<style>
  thead {
    position: sticky;
    top: 0;
  }

  th, .summary {
    background: #eee;
    color: black;
  }

  table.all {
  }

  table.all > tbody > tr > td {
  }

  th.era {
    writing-mode: vertical-lr;
    text-align: start;
  }

  th.era .era-id {
    font-weight: bolder;
  }

  th.era .era-key {
    font-weight: normal;
  }

  th.label {
    text-align: start;
  }
  tbody th.label {
    font-weight: normal;
  }

  .era-country a,
  .era-monarch a {
  }

  .form-sets {
    writing-mode: vertical-lr;
    border-collapse: collapse;
    border: 1px solid gray;
  }

  .form-sets tbody {
    border-block-start: 1px solid gray;
    border-block-end: 1px solid gray;
  }

  .form-sets th {
    padding: 4px;
    font-size: 80%;
    font-weight: normal;
    text-align: end;
  }

  th.form-set-header {
    writing-mode: horizontal-tb;
    border-bottom: 1px solid white;
    text-align: center;
  }

  .form-sets tr:not(:first-child) {
    border-block-start: 1px solid #eee;
  }

  .form-sets tr:not(:first-child) > th {
    border-block-start: 1px solid white;
  }

  .form-sets td {
    font-size: 200%;
    min-inline-size: 1em;
    text-align: center;
  }

  .form-sets td {
    border-inline-start: 1px #eee solid;
  }

  .form-type-la td,
  .form-type-es td,
  .form-type-es_old td,
  .form-type-it td,
  .form-type-po td,
  .form-type-en td,
  .form-type-en_la td,
  .form-type-en_old td,
  .form-type-en_others td,
  .form-type-fr td,
  .form-type-fr_old td,
  .form-type-nan_poj td,
  .form-type-nan_tl td,
  .form-type-ja_latin td,
  .form-type-ja_latin_old td,
  .form-type-ja_latin_old_wrongs td,
  .form-type-sinkan td,
  .form-type-vi td,
  .form-type-vi_old td {
    font-size: 140%;
  }

  .form-set-type-yomi td,
  .form-set-type-kana .form-type-hiragana td,
  .form-set-type-kana .form-type-hiragana_modern td,
  .form-set-type-kana .form-type-hiragana_classic td,
  .form-set-type-kana .form-type-hiragana_others td,
  .form-set-type-kana .form-type-hiragana_wrongs td,
  .form-set-type-kana .form-type-katakana td,
  .form-set-type-kana .form-type-katakana_modern td,
  .form-set-type-kana .form-type-katakana_classic td,
  .form-set-type-kana .form-type-katakana_others td,
  .form-set-type-kana .form-type-latin td,
  .form-set-type-kana .form-type-latin_macron td,
  .form-set-type-kana .form-type-latin_normal td,
  .form-set-type-kana .form-type-latin_others td,
  .form-set-type-kana .form-type-ja_latin td,
  .form-type-ja_latin_upper td,
  .form-type-ja_latin_lower td,
  .form-type-ja_latin_capital td,
  .form-type-ja_latin_others td,
  .form-type-ja_latin_lower_others td,
  .form-type-ja_latin_upper_others td,
  .form-type-ja_latin_capital_others td,
  .form-type-ja_latin_old_upper td,
  .form-type-ja_latin_old_lower td,
  .form-type-ja_latin_old_capital td,
  .form-type-en_upper td,
  .form-type-en_lower td,
  .form-type-en_capital td,
  .form-type-en_upper_others td,
  .form-type-en_lower_others td,
  .form-type-en_capital_others td,
  .form-type-la_upper td,
  .form-type-la_lower td,
  .form-type-la_capital td,
  .form-type-en_la_upper td,
  .form-type-en_la_lower td,
  .form-type-en_la_capital td,
  .form-type-en_la_roman td,
  .form-type-en_la_roman_upper td,
  .form-type-en_la_roman_lower td,
  .form-type-en_la_roman_capital td,
  .form-type-en_old_upper td,
  .form-type-en_old_lower td,
  .form-type-en_old_capital td,
  .form-type-it_upper td,
  .form-type-it_lower td,
  .form-type-it_capital td,
  .form-type-fr_upper td,
  .form-type-fr_lower td,
  .form-type-fr_capital td,
  .form-type-fr_old_upper td,
  .form-type-fr_old_lower td,
  .form-type-fr_old_capital td,
  .form-type-es_upper td,
  .form-type-es_lower td,
  .form-type-es_capital td,
  .form-type-es_old_upper td,
  .form-type-es_old_lower td,
  .form-type-es_old_capital td,
  .form-type-po_upper td,
  .form-type-po_lower td,
  .form-type-po_capital td,
  .form-type-bopomofo td,
  .form-type-bopomofo_zuyntn td,
  .form-type-nan_bopomofo td,
  .form-type-zh_alalc td,
  .form-type-pinyin td,
  .form-type-pinyin_upper td,
  .form-type-pinyin_lower td,
  .form-type-pinyin_capital td,
  .form-type-nan_poj_upper td,
  .form-type-nan_poj_lower td,
  .form-type-nan_poj_capital td,
  .form-type-nan_tl_upper td,
  .form-type-nan_tl_lower td,
  .form-type-nan_tl_capital td,
  .form-type-vi_upper td,
  .form-type-vi_lower td,
  .form-type-vi_capital td,
  .form-type-vi_old_upper td,
  .form-type-vi_old_lower td,
  .form-type-vi_old_capital td,
  .form-type-vi_katakana td,
  .form-type-kr_fukui td,
  .form-type-kp_fukui td,
  .form-type-ko_fukui td,
  .form-set-type-manchu .form-type-moellendorff td,
  .form-set-type-manchu .form-type-abkai td,
  .form-set-type-manchu .form-type-xinmanhan td,
  .form-set-type-mongolian .form-type-cyrillic td,
  .form-set-type-mongolian .form-type-vpmc td {
    font-size: 90%;
  }

  td.on-type { writing-mode: horizontal-tb; font-size: 50% }
  .on-type-KG { background: yellowgreen; color: black }
  .on-type-K { background: yellow; color: black }
  .on-type-G { background: green; color: white }

  .abbr_indexes td {
    text-align: center;
  }

  p {
    margin: 0;
  }

  v-item {
    display: inline-block;
    margin: 1px;
    border: gray 1px solid;
    padding: 1px;
  }

  v-expanded {
    display: block;
    margin: .4em;
    border: blue 1px solid;
    padding: .4em;
  }

  mark {
    display: inline-block;
    font-weight: bolder;
    font-size: 120%;
    min-inline-size: 1em;
    text-align: center;
  }

  .info {
    display: block;
    margin: 0;
    font-size: 90% ;
    font-weight: normal;
  }

  v-value {
    font-size: 120%;
  }

  v-error {
    display: block;
    color: red;
    background: transparent;
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

  code.char {
    border: 1px green solid;
    line-height: 1.0;
  }

  .source {
    line-height: 1.0;
    font-size: 70%;
    color: gray;
    background: white;
  }
</style>
};

if ($Mode eq 'eras') {
  print q{
<h1>Era names</h1>

<p>[<a href=era-names.html>Era names</a> <a href=era-yomis.html>Yomis</a>
<a href=era-kanjions.html>Kanji-ons</a>] [<a
href=https://wiki.suikawiki.org/n/%E5%85%83%E5%8F%B7%E3%81%AE%E8%AA%AD%E3%81%BF%E6%96%B9>Notes</a>]
[<a href=tag-names.html>Tag names</a>]

<p class=info>This document is generated from <a
href=../data/calendar/era-defs.json><code>data/calendar/era-defs.json</code></a>
and <a
href=../data/calendar/era-labels.json><code>data/calendar/era-labels.json</code></a>.

};
} elsif ($Mode eq 'tags') {
  print q{
<h1>Tag names</h1>

<p>[<a href=era-names.html>Era names</a>]

<p class=info>This document is generated from <a
href=../data/tags.json><code>data/tags.json</code></a>
and <a
href=../data/tag-labels.json><code>data/tag-labels.json</code></a>.

};
}

printf q{<table class=all>
  <thead>
    <tr>
      <th class=era>%s
      <th><abbr title="Label set">LS</abbr>
      <th class=label>Label
}, {
  eras => 'Era',
  tags => 'Tag',
}->{$Mode};

for my $era (sort { $a->{key} cmp $b->{key} } values %{
  $Mode eq 'eras' ? $Eras->{eras} :
  $Mode eq 'tags' ? $Tags->{tags} : die $Mode
}) {
  my $lses = [@{$era->{label_sets} or []}];
  
  printf qq{\n<tbody><tr id=%d>
    <th class=era rowspan="%d">
      <a href=https://data.suikawiki.org/%s/%d/>
        <code class=era-id>%s%d</code>
      </a>
      <code class=era-key>%s</code>
  },
      $era->{id},
      1+@{[

        map {
          map {
            (1, map { (1, 1) } @{$_->{form_groups}})
          } @{$_->{labels}}
        } @$lses

      ]},
      {tags => 'tag', eras => 'e'}->{$Mode},
      $era->{id},
      ($Mode eq 'eras' ? 'y~' : ''),
      $era->{id}, $era->{key};

  {
    my $patterns = {};
    printf qq{<td colspan=3 class=summary><p>\n};
    for my $key (qw(name name_tw name_ja name_cn name_ko name_vi name_kana
                    name_en name_latn)) {
      printf q{ <code>%s</code>: },
          $key;
      my $v = $era->{$key};
      if (defined $v) {
        printf q{<bdi class="pattern-%d">%s</bdi>},
            pattern ($v, $patterns),
            htescape $v;
      } else {
        printf q{-};
      }
    }
    printf q{<p>Names: };
    print join ', ', map {
      sprintf q{<bdi class="pattern-%d">%s</bdi>},
          pattern ($_, $patterns),
          htescape $_;
    } sort { $a cmp $b } keys %{$era->{names} or {}};
  }
  
  for (0..$#$lses) {
    my $ls = $lses->[$_];
    print qq{\x0A<tr>};
    if (not @{$ls->{labels}}) {
      print q{<v-error>ERROR: <code>labels</code> is empty</v-error>};
    }
    printf q{<th rowspan="%d">#%d},
        0+@{[
          map {
            (1, map { (1, 1) } @{$_->{form_groups}})
          } @{$ls->{labels}}
        ]} || 1,
        $_;
    for (0..$#{$ls->{labels}}) {
      my $label = $ls->{labels}->[$_];
      print qq{\x0A<tr>} unless $_ == 0;
      printf q{<th class=label>%d},
          $_;

      if (keys %{$label->{props}->{country_tag_ids} or {}}) {
        printf q{ <span class=era-country>Country [};
        for my $tag_id (sort {
          !!($label->{props}->{country_tag_ids}->{$b}->{preferred}) <=>
          !!($label->{props}->{country_tag_ids}->{$a}->{preferred}) ||
          $a <=> $b;
        } keys %{$label->{props}->{country_tag_ids}}) {
          my $tag = $Tags->{tags}->{$tag_id}
              or die "Tag |$tag_id| not found";
          print q{ };
          my $p = $label->{props}->{country_tag_ids}->{$tag_id}->{preferred};
          print q{<strong>} if $p;
          printf qq{<a href=tag-names.html#%d>#%s</a>\n },
              $tag->{id}, $tag->{label};
          print q{</strong>} if $p;
        }
        printf q{]</span>};
      }
      if (keys %{$label->{props}->{monarch_tag_ids} or {}}) {
        printf q{ <span class=era-monarch>Monarch [};
        for my $tag_id (sort {
          !!($label->{props}->{monarch_tag_ids}->{$b}->{preferred}) <=>
          !!($label->{props}->{monarch_tag_ids}->{$a}->{preferred}) ||
          $a <=> $b;
        } keys %{$label->{props}->{monarch_tag_ids}}) {
          my $tag = $Tags->{tags}->{$tag_id}
              or die "Tag |$tag_id| not found";
          print q{ };
          my $p = $label->{props}->{monarch_tag_ids}->{$tag_id}->{preferred};
          print q{<strong>} if $p;
          printf qq{<a href=tag-names.html#%d>#%s</a>\n },
              $tag->{id}, $tag->{label};
          print q{</strong>} if $p;
        }
        printf q{]</span>};
      }
      if ($label->{props}->{is_name}) {
        printf q{ Name:};
      } else {
        printf q{ Value:};
      }
      if (defined $label->{abbr}) {
        printf q{ [<code class=label-abbr>abbr:%s</code>]},
            htescape $label->{abbr};
      }
      
      my $names = {};
      my $refnames = {};

      if (@{$label->{form_groups}}) {
        for (0..$#{$label->{form_groups}}) {
          my $rep = $label->{form_groups}->[$_];
          print qq{\x0A<tr>};

          printf q{<td><p>form group [<code>%s</code>]},
              htescape $rep->{form_group_type};
          if (keys %{$rep->{is_preferred} or {}}) { # type:compound
            printf q{ (<mark>%s</mark>)},
                join ', ', map { "<code>$_</code>" } map { htescape $_ } sort { $a cmp $b } keys %{$rep->{is_preferred} or {}};
          }
          print q{</p>};

          my $print_values = sub {
            my ($values, $patterns, $short_patterns) = @_;
            for my $value (@$values) {
              printf qq{\n<tbody class="form-set-type-%s">\n},
                  $value->{form_set_type} // die;
              my $ai = $value->{abbr_indexes} || [];
              my $preferred = $value->{is_preferred} || {};
              my $kmap = {
                kana => {kana => '0'},
                yomi => {han_others => 'hiragana_z'},
                manchu => {manchu => '0'},
                mongolian => {mongolian => '0'},
                vietnamese => {vi_katakana => "vi_\x{A000}"},
              }->{$value->{form_set_type}} || {};
              my @kv = map {
                if ($_->[0] eq 'others' or
                    $_->[0] =~ /_others$/ or
                    $_->[0] =~ /_wrongs$/) {
                  my $key = $_->[0];
                  my $temp = $_->[1];
                  map { [$key => $_, $temp] } @{$value->{$key}};
                } else {
                  [$_->[0] => $value->{$_->[0]}, $_->[1]];
                }
              } sort {
                $a->[1] cmp $b->[1] ||
                $a->[0] cmp $b->[0];
              } map {
                my $key = $kmap->{$_} // $_;
                $key =~ s/normal/\x{0000}/g;
                $key =~ s/_(lower|upper|capital)_others/_others_$1/g;
                $key =~ s/other/\x{10FF0E}/g;
                $key =~ s/wrong/\x{10FF0F}/g;
                $key =~ s/_lower/_\x{5000}/g;
                $key =~ s/_capital/_\x{5001}/g;
                $key =~ s/_upper/_\x{5002}/g;
                $key =~ s/_roman/_\x{6000}/g;
                $key =~ s/vi_katakana/vi_\x{9000}_katakana/g;
                [$_, $key];
              } grep { not {
                abbr_indexes => 1,
                form_set_type => 1,
                segment_length => 1,
                is_preferred => 1,
                origin_lang => 1,
              }->{$_} } keys %$value;
              printf q{<tr class="form-type-%s" data-temp="%s"><th rowspan=%d class=form-set-header>form set <code>%s</code>%s},
                  $kv[0]->[0],
                  $kv[0]->[2],
                  @kv+(defined $short_patterns ? 1 : 0),
                  $value->{form_set_type},
                  (defined $value->{origin_lang} ? sprintf ' [<code>%s</code>]', htescape $value->{origin_lang} : '');
              for my $kv (@kv) {
                my $v = $kv->[1];
                printf qq{<tr class="form-type-%s" data-temp="%s">\n},
                    $kv->[0], $kv->[2] unless $kv eq $kv[0];
                if (ref $v eq 'ARRAY') {
                  printf qq{<th>};
                  print q{<mark>} if $preferred->{$kv->[0]};
                  printf qq{<code>%s</code>\n},
                      htescape $kv->[0];
                  print q{</mark>} if $preferred->{$kv->[0]};

                  if ($kv->[0] eq 'on_types') {
                    for (@$v) {
                      use utf8;
                      my $t = defined $_ ? {
                        KG => '漢~呉',
                        K => '漢',
                        G => '呉',
                      }->{$_} // $_ : '?';
                      printf q{<td class="on-type on-type-%s">}, $_ // '';
                      print $t;
                    }
                    next;
                  }

                  my $i = 0;
                  my $has_segment = 0;
                  for my $segment (@$v) {
                    if ($segment =~ /^\./) {
                      print $has_segment ? ' ' : '<td>';
                      printf q{<bdi>%s</bdi>},
                          htescape $segment;
                      next;
                    } else {
                      print q{<td>};
                    }
                    my $s;
                    if (ref $segment) {
                      $s = join "", map {
                        if (1 < length $_) {
                          sprintf "<code class=char>%s</code>", htescape $_;
                        } else {
                          htescape $_;
                        }
                      } @$segment;
                    } else {
                      $s = htescape $segment;
                    }
                    print q{<mark>} if defined $ai->[$i];
                    my $pp = $patterns->{$i} ||= {};
                    if (defined $ai->[$i]) {
                      $pp = $short_patterns->{$ai->[$i]} ||= {};
                    }
                    printf q{<bdi class="pattern-%d">%s</bdi> },
                        pattern ($s, $pp),
                        $s;
                    print q{</mark>} if defined $ai->[$i];
                    $i++;
                    $has_segment = 1;
                  }
                } else {
                  printf qq{<td colspan=2><v-error>ERROR: Bad value %s: %s</v-error>\n},
                      htescape $kv->[0],
                      htescape $v;
                }
              }
              if (defined $short_patterns) {
                printf q{<tr class=abbr_indexes><th>Abbr.};
                my $has_index = 0;
                for (@$ai) {
                  if (defined $_) {
                    printf q{<td>%d}, $_;
                    $has_index++;
                  } else {
                    print q{<td>-};
                  }
                }
                print q{<v-error>ERROR: No abbr index</v-error>}
                    unless $has_index;
              }
            } # $value
          }; # $print_values

          if ($rep->{form_group_type} eq 'compound') {
            for my $item (@{$rep->{items}}) {
              printf q{<v-item><p>form group [<code>%s</code>]},
                  htescape $item->{form_group_type};

              my $patterns = {};
              print q{<table class=form-sets>};
              $print_values->($item->{form_sets}, $patterns, undef);
              print q{</table>};
              
              printf q{</v-item>};
            }
          } else {
            my $patterns = {};
            print q{<table class=form-sets>};
            $print_values->($rep->{form_sets}, $patterns, undef);
            print q{</table>};

            for my $label (@{$rep->{expandeds} or []}) {
              print qq{<v-expanded><p>Expanded:\n};
              for my $text (@{$label->{form_groups}}) {
                printf qq{<p>form group [<code>%s</code>]\n},
                    htescape $text->{form_group_type};
                
                print q{<table>};
                $print_values->($text->{form_sets}, {}, $patterns);
                print q{</table>};
              }
              print q{</v-expanded>};
            }
          }
          
          printf qq{\x0A<tr><td class=source>%s},
              perl2json_chars_for_record $rep;
        }
      } else {
        print q{<td>-};
      } # $reps

    }
  }
  
  print "\x0A";
}

print q{
  </table>

<sw-ads normal></sw-ads>
<script src="https://manakai.github.io/js/global.js" async></script>

};
print STDERR qq{\n};

## License: Public Domain.
