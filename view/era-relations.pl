use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent;
binmode STDOUT, qw(:encoding(utf-8));

print STDERR "\rLoading...";
my $Eras;
my $EraById = {};
{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  $Eras = $json;
  for (values %{$Eras->{eras}}) {
    $EraById->{$_->{id}} = $_;
  }
}
my $EraRels;
{
  my $path = $RootPath->child ('local/calendar-era-relations-0.json');
  my $json = json_bytes2perl $path->slurp;
  $EraRels = $json;
}
print STDERR "\rLoaded!";

sub htescape ($) {
  my $s = shift;
  $s =~ s/&/&amp;/g;
  $s =~ s/</&lt;/g;
  $s =~ s/"/&quot;/g;
  return $s;
} # htescape

print q{<!DOCTYPE html>
<meta charset=utf-8>
<title>Era-to-era relations</title>
<style>
  html {
    line-height: 1.0;
  }

  thead {
    position: sticky;
    top: 0;
  }

  th, td {
    vertical-align: top;
    padding: .5em;
  }

  th {
    background: #eee;
    color: black;
  }

  tbody th {
    text-align: end;
  }

  td p:not([hidden]) {
    display: inline-block;
  }

  td p {
    margin: 0 0.5em;
    min-width: 10em;
    vertical-align: top;
  }

  a {
    text-decoration: none;
    border-bottom: 1px solid currentcolor;
    padding-bottom: 0;
    line-height: 1.5;
  }

  a[href^="#"] {
    border-bottom-style: dashed;
  }

  td p a:not([hidden]) {
    display: block;
  }
  td p a {
    margin-left: .5em;
  }

  .era-key, .era-id {
    font-size: 100%;
    font-family: monospace;
    white-space: pre;
  }

  .era-id {
    font-size: 90%;
  }

  .rel-type:not([hidden]) {
    display: block;
  }
  .rel-type {
    font-size: 90%;
  }
  .rel-type::before {
    content: "\A0\A0";
    font-weight: normal;
   }

  .rel-type-name_equal,
  .rel-type-name_reversed,
  .rel-type-abbr_equal,
  .rel-type-yomi_equal,
  .rel-type-korean_equal,
  .rel-type-alphabetical_equal,
  .rel-type-year_equal,
  .rel-type-cognate_canon {
    font-weight: bolder;
  }
  .rel-type-name_equal::before { content: "=\A0" }
  .rel-type-name_reversed::before { content: "\21C4\A0" }
  .rel-type-abbr_equal::before { content: "=\A0" }
  .rel-type-yomi_equal::before { content: ":\A0" }
  .rel-type-korean_equal::before { content: ":\A0" }
  .rel-type-alphabetical_equal::before { content: "=\A0" }
  .rel-type-year_equal::before { content: "\2261\A0" }
  .rel-type-transition_prev::before { content: "\2190\A0" }
  .rel-type-transition_next::before { content: "\2192\A0" }
  .rel-type-cognate_deviates::before { content: "\219D\A0" }
  .rel-type-cognate_deviated::before { content: "\219C\A0" }
  .rel-type-cognate_canon::before { content: "\21D2\A0" }
  .rel-type-name_reuses::before { content: "\21E0\A0" }
  .rel-type-name_reused::before { content: "\21E2\A0" }

</style>

<h1>Era-to-era relations</h1>

<p class=info>This document is generated from <a
href=../data/calendar/era-defs.json><code>data/calendar/era-defs.json</code></a>
and <a
href=../data/calendar/era-relations.json><code>data/calendar/era-relations.json</code></a>.

};

printf q{
<table>
  <thead>
    <tr><th>Era<th>Related eras
  <tbody>
};

for (sort { $a->[1]->{key} cmp $b->[1]->{key} } map {
  my $data = $EraRels->{eras}->{$_};
  my $def = $Eras->{eras}->{$data->{_key}};
  [$data, $def];
} keys %{$EraRels->{eras}}) {
  my ($data, $def) = @$_;

  printf qq{\x0A<tr id=era-%d><th><a href=https://data.suikawiki.org/e/%d/><code class=era-key>%s</code> [<code class=era-id>y~%d</code>]</a>},
      $def->{id}, $def->{id}, htescape $def->{key}, $def->{id};

  printf q{<td>};
  for my $id2 (sort { $a <=> $b } keys %{$data->{relateds}}) {
    my $rel = $data->{relateds}->{$id2};
    my $def2 = $EraById->{$id2};
    printf qq{\x0A<p><a href=#era-%d><code class=era-key>%s</code> [<code class=era-id>y~%d</code>]</a>},
        $def2->{id}, htescape $def2->{key}, $def2->{id};
    for my $type (sort { $a cmp $b } grep { not /^_/ } keys %$rel) {
      printf q{ <code class="rel-type rel-type-%s">%s</code>},
          htescape $type, htescape $type;
    }
  } # $ids
} # $data

print q{</table>};
print STDERR qq{\n};

## License: Public Domain.
