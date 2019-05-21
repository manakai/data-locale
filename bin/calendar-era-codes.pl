use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::URL::Encoding;
use Web::DOM::Document;
binmode STDOUT, qw(:encoding(utf-8));

my $root_path = path (__FILE__)->parent->parent;
my $json = json_bytes2perl $root_path->child ('data/calendar/era-defs.json')->slurp;

my $cols = [
  {key => 'start_year', hidden => 1, info => 1},
  {key => 'south_start_year', hidden => 1, info => 1},
  {key => 'north_start_year', hidden => 1, info => 1},
  {key => 'name', type => 'text', info => 1},
  {key => 'key', type => 'key', info => 1},
  {key => 'abbr', type => 'text', label => '#7 (abbr)', id => 7},
  {key => 'abbr_latn', type => 'text', label => '#2 (abbr_latn)', id => 2},
  {key => 'id', type => 'int', label => '#8 (id)', info => 1, id => 8},
  {key => 'code1', type => 'int', id => 1},
  {key => 'code17', type => 'int', id => 1},
  {key => 'code16', type => 'int', id => 1},
  {key => 'code4', type => 'int', id => 4},
  {key => 'code5', type => 'int', id => 5},
  {key => 'code6', type => 'int', id => 6},
  {key => 'code9', type => 'int', id => 9},
  {key => 'code15', type => 'code', label => '#15 (森本)', id => 15},
  {key => 'code14', type => 'int', label => '#14 (所)', id => 14},
  {key => 'code10', type => 'int', label => '#10 (CLDR)', id => 10},
  {key => 'unicode', label => 'Unicode', type => 'unicode', id => 3},
  {key => 'code11', label => 'AJ1 (横)', type => 'int', id => 11},
  {key => 'code12', label => 'AJ1 (縦)', type => 'int', id => 12},
  {key => 'code13', label => 'SJIS', type => 'hex', id => 13},
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
    ($a->[0] || $a->[1] || $a->[2] || 99999) <=> ($b->[0] || $b->[1] || $b->[2] || 99999) ||
    $a->[14] <=> $b->[14] || # 14
    $a->[7] <=> $b->[7]; # #8
  } @$rows];
}

my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->inner_html (q{<!DOCTYPE HTML><meta charset=utf-8><title>Era codes</title><!--

Per CC0 <https://creativecommons.org/publicdomain/zero/1.0/>, to the
extent possible under law, the author of this document has waived all
copyright and related or neighboring rights to this document.

--><h1>Era codes</h1><table><thead><tr><tbody></table>});

{
  my $tr = $doc->query_selector ('thead tr');
  for (@$cols) {
    next if $_->{hidden};
    my $td = $doc->create_element ('th');
    if (defined $_->{label}) {
      $td->text_content ($_->{label});
    } elsif ($_->{key} =~ /^code([0-9]+)$/) {
      $td->text_content ('#' . $1);
    } else {
      my $e = $doc->create_element ('code');
      $e->text_content ($_->{key});
      $td->append_child ($e);
    }
    if (defined $_->{id}) {
      my $a = $doc->create_element ('a');
      while (defined $td->first_child) {
        $a->append_child ($td->first_child);
      }
      $a->href ('https://wiki.suikawiki.org/n/%E5%85%83%E5%8F%B7%E3%82%B3%E3%83%BC%E3%83%89#anchor-' . (8000 + $_->{id}));
      $td->append_child ($a);
    }
    $tr->append_child ($td);
  }
}

{
  my $tbody = $doc->query_selector ('tbody');
  for my $row (@$rows) {
    my $tr = $doc->create_element ('tr');
    for (0..$#$cols) {
      next if $cols->[$_]->{hidden};
      my $td = $doc->create_element ('td');
      if (defined $row->[$_]) {
        if ($cols->[$_]->{type} eq 'unicode') {
          my $e = $doc->create_element ('code');
          $e->text_content (sprintf 'U+%04X (%s)', ord $row->[$_], $row->[$_]);
          $td->append_child ($e);
        } elsif ($cols->[$_]->{type} eq 'hex') {
          my $e = $doc->create_element ('code');
          $e->text_content (sprintf '0x%X', $row->[$_]);
          $td->append_child ($e);
        } elsif ($cols->[$_]->{type} eq 'key') {
          my $e = $doc->create_element ('a');
          $e->href ('https://data.suikawiki.org/era/' . percent_encode_c $row->[$_]);
          $e->text_content ($row->[$_]);
          $td->append_child ($e);
        } else {
          my $e = $doc->create_element ({
            text => 'span',
            code => 'code',
            int => 'data',
          }->{$cols->[$_]->{type}} // 'code');
          $e->text_content ($row->[$_]);
          $td->append_child ($e);
        }
      }
      $tr->append_child ($td);
      $tr->append_child ($doc->create_text_node ("\n"));
    }
    $tbody->append_child ($tr);
  }
}

print $doc->inner_html;

## License: Public Domain.
