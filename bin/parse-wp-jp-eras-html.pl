use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::DOM::Document;
use Web::HTML::Table;

my $path = path (__FILE__)->parent->parent->child ('local/wp-jp-eras.html');
my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->inner_html ($path->slurp_utf8);
$doc->manakai_set_url (q<https://ja.wikipedia.org/wiki/%E5%85%83%E5%8F%B7%E4%B8%80%E8%A6%A7_(%E6%97%A5%E6%9C%AC)>);

my $Data = {};

my $tables = $doc->get_elements_by_tag_name ('table');

my $impl = Web::HTML::Table->new;
for my $table_el (grep { $_->class_list->contains ('wikitable') } @$tables) {
  my $table = $impl->form_table ($table_el);
  my $Table = [];

  my $w = $table->{width};
  my $h = $table->{height};
  for my $r (0..($h-1)) {
    for my $c (0..($w-1)) {
      my $cell = $table->{cell}->[$c]->[$r];
      if (defined $cell and @$cell) {
        my $v = [$cell->[0]->{element}->text_content];
        my $link = $cell->[0]->{element}->get_elements_by_tag_name ('a')->[0];
        if (defined $link) {
          push @$v, $link->href;
        }
        $Table->[$r]->[$c] = $v;
      }
    }
  }

  push @{$Data->{tables} ||= []}, $Table;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
