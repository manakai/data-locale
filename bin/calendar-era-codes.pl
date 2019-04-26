use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::DOM::Document;
binmode STDOUT, qw(:encoding(utf-8));

my $root_path = path (__FILE__)->parent->parent;
my $json = json_bytes2perl $root_path->child ('data/calendar/era-defs.json')->slurp;

my $cols = [
  {key => 'name', type => 'text', info => 1},
  {key => 'key', type => 'code', info => 1},
  {key => 'abbr', type => 'text', label => '#7 (abbr)'},
  {key => 'abbr_latn', type => 'text', label => '#2 (abbr_latn)'},
  {key => 'id', type => 'int', label => '#8 (id)', info => 1},
  {key => 'code1', type => 'int'},
  {key => 'code4', type => 'int'},
  {key => 'code5', type => 'int'},
  {key => 'code6', type => 'int'},
  {key => 'code9', type => 'int'},
  {key => 'code15', type => 'code', label => '#14 (森本)'},
  {key => 'code14', type => 'int', label => '#14 (所)'},
  {key => 'code10', type => 'int', label => '#10 (CLDR)'},
  {key => 'unicode', label => 'Unicode', type => 'unicode'},
  {key => 'code11', label => 'AJ1 (横)', type => 'int'},
  {key => 'code12', label => 'AJ1 (縦)', type => 'int'},
  {key => 'code13', label => 'SJIS', type => 'hex'},
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
    $a->[11] <=> $b->[11] || # #14
    $a->[4] <=> $b->[4]; # #8
  } @$rows];
}

my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->inner_html (q{<!DOCTYPE HTML><meta charset=utf-8><title>Era codes</title><h1>Era codes</h1><table><thead><tr><tbody></table>});

{
  my $tr = $doc->query_selector ('thead tr');
  for (@$cols) {
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
    $tr->append_child ($td);
  }
}

{
  my $tbody = $doc->query_selector ('tbody');
  for my $row (@$rows) {
    my $tr = $doc->create_element ('tr');
    for (0..$#$cols) {
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
    }
    $tbody->append_child ($tr);
  }
}

print $doc->inner_html;

## License: Public Domain.
