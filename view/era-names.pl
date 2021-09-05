use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent;
binmode STDOUT, qw(:encoding(utf-8));

print STDERR "\rLoading...";
my $Eras;
{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  $Eras = $json;
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
<meta charset=utf-8>
<title>Era names</title>
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

  .text-values {
    writing-mode: vertical-lr;
    border-collapse: collapse;
    border: 1px solid gray;
  }

  .text-values tbody {
    border-block-start: 1px solid gray;
    border-block-end: 1px solid gray;
  }

  .text-values th {
    padding: 4px;
    font-size: 80%;
    font-weight: normal;
    text-align: end;
  }

  th.value-header {
    writing-mode: horizontal-tb;
    border-bottom: 1px solid white;
    text-align: center;
  }

  .text-values tr:not(:first-child) {
    border-block-start: 1px solid #eee;
  }

  .text-values tr:not(:first-child) > th {
    border-block-start: 1px solid white;
  }

  .text-values td {
    font-size: 200%;
    min-inline-size: 1em;
    text-align: center;
  }

  .text-values td {
    border-inline-start: 1px #eee solid;
  }

  .value-type-on td {
    font-size: 90%;
  }

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

  .source {
    line-height: 1.0;
    font-size: 70%;
    color: gray;
    background: white;
  }
</style>

<h1>Era names</h1>

<p class=info>This document is generated from <a
href=../data/calendar/era-defs.json><code>data/calendar/era-defs.json</code></a>.

};
printf q{<table class=all>
  <thead>
    <tr>
      <th>Era
      <th><abbr title="Label set">LS</abbr>
      <th><abbr title=Label>L</abbr>
      <th>Value
};

for my $era (sort { $a->{key} cmp $b->{key} } values %{$Eras->{eras}}) {
  my $lses = [@{$era->{label_sets} or []}];
  
  printf q{<tbody><tr><th rowspan="%d"><code>y~%d</code><p class=info><code>%s</code>},
      1+@{[map { (1,1) } map { @{$_->{texts}} } map { @{$_->{labels}} } @$lses]} || 1,
      $era->{id}, $era->{key};

  {
    my $patterns = {};
    printf qq{<td colspan=3 class=summary><p>\n};
    for my $key (qw(name name_tw name_ja name_cn name_ko name_en name_kana)) {
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
    printf q{<p>Names:};
    print join ', ', map {
      sprintf q{<bdi class="pattern-%d">%s</bdi>},
          pattern ($_, $patterns),
          htescape $_;
    } sort { $a cmp $b } keys %{$era->{names} or {}};
  }
  
  for (0..$#$lses) {
    my $ls = $lses->[$_];
    print q{<tr>};
    if (not @{$ls->{labels}}) {
      print q{<v-error>ERROR: <code>labels</code> is empty</v-error>};
    }
    printf q{<th rowspan="%d">#%d},
        0+@{[map { (1,1) } map { @{$_->{texts}} } @{$ls->{labels}}]} || 1,
        $_;
    for (0..$#{$ls->{labels}}) {
      my $label = $ls->{labels}->[$_];
      print q{<tr>} unless $_ == 0;
      printf q{<th rowspan="%d">%d},
          0+@{[ map { (1,1) } @{$label->{texts}} ]},
          $_;

      my $names = {};
      my $refnames = {};

      if (@{$label->{texts}}) {
        for (0..$#{$label->{texts}}) {
          my $rep = $label->{texts}->[$_];
          print q{<tr>} unless $_ == 0;

          printf q{<td><p>[<code>%s</code>]},
              htescape $rep->{type};
          if (defined $rep->{abbr}) {
            printf q{ (<code>abbr:%s</code>)},
                htescape $rep->{abbr};
          }
          if (keys %{$rep->{is_preferred} or {}}) { # type:compound
            printf q{ (%s)},
                join ', ', map { "<code>$_</code>" } map { htescape $_ } sort { $a cmp $b } keys %{$rep->{is_preferred} or {}};
          }
          print q{</p>};

          my $print_values = sub {
            my ($values, $patterns, $short_patterns) = @_;
            for my $value (@$values) {
              printf qq{<tbody class="value-type-%s">\n},
                  $value->{type} // '';
              my $ai = $value->{abbr_indexes} || [];
              my $preferred = $value->{is_preferred} || {};
              my @kv = map {
                if ({
                  kana_others => 1,
                  latin_others => 1,
                  values => 1,
                }->{$_}) {
                  my $key = $_;
                  map { [$key => $_] } @{$value->{$_}};
                } else {
                  [$_ => $value->{$_}];
                }
              } sort { $a cmp $b } grep { not {
                abbr_indexes => 1,
                type => 1,
                segment_length => 1,
                is_preferred => 1,
              }->{$_} } keys %$value;
              printf q{<tr><th rowspan=%d class=value-header><code>%s</code>},
                  @kv+(defined $short_patterns ? 1 : 0),
                  $value->{type} // '-';
              for my $kv (@kv) {
                my $v = $kv->[1];
                print qq{<tr>\n} unless $kv eq $kv[0];
                if (ref $v eq 'ARRAY') {
                  printf qq{<th>};
                  print q{<mark>} if $preferred->{$kv->[0]};
                  printf qq{<code>%s</code>\n},
                      htescape $kv->[0];
                  print q{</mark>} if $preferred->{$kv->[0]};
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
                      $s = join ", ", map { "<code>$_</code>" } map { htescape $_ } @$segment;
                    } else {
                      $s = join '', map { "<code>$_</code>" } htescape $segment;
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

          if ($rep->{type} eq 'compound') {
            for my $item (@{$rep->{items}}) {
              printf q{<v-item><p>[<code>%s</code>]},
                  htescape $item->{type};

              my $patterns = {};
              print q{<table class=text-values>};
              $print_values->($item->{values}, $patterns, undef);
              print q{</table>};
              
              printf q{</v-item>};
            }
          } else {
            my $patterns = {};
            print q{<table class=text-values>};
            $print_values->($rep->{values}, $patterns, undef);
            print q{</table>};

            for my $label (@{$rep->{expandeds} or []}) {
              print qq{<v-expanded><p>Expanded:\n};
              for my $text (@{$label->{texts}}) {
                printf qq{<p>[<code>%s</code>]\n},
                    htescape $text->{type};
                
                print q{<table>};
                $print_values->($text->{values}, {}, $patterns);
                print q{</table>};
              }
              print q{</v-expanded>};
            }
          }
          
          printf q{<tr><td class=source>%s},
              perl2json_chars_for_record $rep;
        }
      } else {
        print q{<td>-};
      } # $reps

    }
  }
  
  print "\x0A";
}

print q{</table>};
print STDERR qq{\n};

## License: Public Domain.
