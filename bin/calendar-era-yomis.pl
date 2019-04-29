use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::DOM::Document;
binmode STDOUT, qw(:encoding(utf-8));

my $root_path = path (__FILE__)->parent->parent;
my $json = json_bytes2perl $root_path->child ('local/era-yomi-list.json')->slurp;

my $cols = [
  {key => 'start_year', hidden => 1, info => 1},
  {key => 'south_start_year', hidden => 1, info => 1},
  {key => 'north_start_year', hidden => 1, info => 1},
  {key => 'name', type => 'text', info => 1},
  #{key => 'key', type => 'code', info => 1},
  (map {
    {key => $_, type => 'text'};
  } (6001, 6002, 6011, 6012, 6013..6020, 6031..6036, 6040,
     6041..6046, 6047..6048, 6049..6050, 6071..6083)),
];

my $rows = [];
ERA: for my $era (values %{$json->{eras}}) {
  my @row;
  my $has_data = 0;
  for (@$cols) {
    $has_data = 1 if not $_->{info} and defined $era->{$_->{key}};
    push @row, $era->{$_->{key}};
  }
  next unless $has_data;
  push @$rows, \@row;
} # ERA
{
  no warnings 'uninitialized';
  $rows = [sort {
    ($a->[0] || $a->[1] || $a->[2] || 99999) <=> ($b->[0] || $b->[1] || $b->[2] || 99999);
  } @$rows];
}

my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->inner_html (q[<!DOCTYPE HTML><meta charset=utf-8><title>Era yomis</title>
<style>
  td > span + span {
    margin-left: 1em;
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

</style>
<h1>Era codes</h1><table><thead><tr><tbody></table>]);

{
  my $tr = $doc->query_selector ('thead tr');
  for (@$cols) {
    next if $_->{hidden};
    my $td = $doc->create_element ('th');
    if (defined $_->{label}) {
      $td->text_content ($_->{label});
    } elsif ($_->{key} =~ /^([0-9]+)$/) {
      my $a = $doc->create_element ('a');
      $a->set_attribute (href => q<https://wiki.suikawiki.org/n/%E5%85%83%E5%8F%B7%E3%81%AE%E8%AA%AD%E3%81%BF%E6%96%B9#anchor-> . $1);
      $a->text_content ('#' . $1);
      $td->append_child ($a);
    } else {
      my $e = $doc->create_element ('code');
      $e->text_content ($_->{key});
      $td->append_child ($e);
    }
    $tr->append_child ($td);
  }
}

{
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
    rya りゃ ryu りゅ ryo りょ
    gya ぎゃ gyu ぎゅ gyo ぎょ
    pya ぴゃ pyu ぴゅ pyo ぴょ
  )};
  my $tbody = $doc->query_selector ('tbody');
  for my $row (@$rows) {
    my $tr = $doc->create_element ('tr');
    my $patterns = {};
    my $next_pattern = 1;
    my $pattern = sub {
      use utf8;
      my $key = shift;
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
      $key =~ s/ch[\x{F4}\x{014D}]/ちょう/g;
      $key =~ s/sh[\x{F4}\x{014D}]/しょう/g;
      $key =~ s/n[\x{F4}\x{014D}]/のう/g;
      $key =~ s/h[\x{F4}\x{014D}]/ほう/g;
      $key =~ s/k[\x{F4}\x{014D}]/こう/g;
      $key =~ s/j[\x{F4}\x{014D}]/じょう/g;
      $key =~ s/d[\x{F4}\x{014D}]/どう/g;
      $key =~ s/p[\x{F4}\x{014D}]/ぽう/g;
      $key =~ s/r[\x{F4}\x{014D}]/ろう/g;
      $key =~ s/gy[\x{F4}\x{014D}]/ぎょう/g;
      $key =~ s/ky[\x{F4}\x{014D}]/きょう/g;
      $key =~ s/py[\x{F4}\x{014D}]/ぴょう/g;
      $key =~ s/y[\x{F4}\x{014D}]/よう/g;
      $key =~ s/ch[\x{FB}\x{016B}]/ちゅう/g;
      $key =~ s/ky[\x{FB}\x{016B}]/きゅう/g;
      $key =~ s/([kstnhmrgzdbp][aiueo])/$L2K->{$1}/g;
      $key =~ s/([kgrp]y[auo])/$L2K->{$1}/g;
      $key =~ s/(y[auo])/$L2K->{$1}/g;
      $key =~ s/(w[aieo])/$L2K->{$1}/g;
      $key =~ s/([aiueonm])/$L2K->{$1}/g;
      $key =~ s/[\x{F4}\x{014D}]/おう/g;
      $key =~ tr/ゃゅょ/やゆよ/;
      $key =~ s/[ '-]//g;
      return 'pattern-' . ($patterns->{$key} ||= $next_pattern++);
    };
    for (0..$#$cols) {
      next if $cols->[$_]->{hidden};
      my $td = $doc->create_element ('td');
      if (defined $row->[$_]) {
        if (ref $row->[$_] eq 'ARRAY') {
          for my $x (@{$row->[$_]}) {
            my $e = $doc->create_element ('span');
            $e->set_attribute ('class', $pattern->($x))
                unless $cols->[$_]->{info};
            $e->text_content ($x);
            $td->append_child ($e);
          }
        } else {
          my $e = $doc->create_element ('span');
          $e->set_attribute ('class', $pattern->($row->[$_]))
                unless $cols->[$_]->{info};
          $e->text_content ($row->[$_]);
          $td->append_child ($e);
        }
      }
      $tr->append_child ($td);
    }
    $tbody->append_child ($tr);
  }
}

print $doc->inner_html;

## License: Public Domain.
