use strict;
use warnings;
use Encode;
use Path::Tiny;
use JSON::PS;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::DOM::Document;

my $root_path = path (__FILE__)->parent->parent;

my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->manakai_set_url (q<https://en.wikipedia.org/wiki/Template:Japanese_era_names>);

my $html_path = $root_path->child ('local/wp-jp-eras-en.html');
$doc->inner_html ($html_path->slurp_utf8);

my $Data = {};

for my $a_el ($doc->query_selector_all ('table.infobox td:nth-child(2) a')->to_list) {
  my $data = {};
  $data->{name} = $a_el->text_content;
  $data->{url} = $a_el->href;
  if ($data->{url} =~ m{^https://en.wikipedia.org/wiki/([^#?]+)$}) {
    $data->{wref_en} = $1;
    $data->{wref_en} =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
    $data->{wref_en} = decode 'utf-8', $data->{wref_en};
  }
  my $cell = $a_el->parent_node;
  $cell = $cell->parent_node unless $cell->local_name eq 'td';
  my $pre_cell = $cell->previous_element_sibling;
  my $pre_text = $pre_cell->text_content;
  if ($pre_text =~ /^\s*(\d+)\x{2013}(\d+)\s*$/) {
    $data->{start_year} = $1;
    $data->{end_year} = $2;
  } elsif ($pre_text =~ /^\s*(\d+)\x{2013}(?:present|)\s*$/) {
    $data->{start_year} = $1;
  } elsif ($pre_text =~ /^\s*(\d+)\s*$/) {
    $data->{start_year} = $1;
    $data->{end_year} = $1;
  } else {
    warn $pre_text;
  }
  $data->{name} =~ s/^\s+//g;
  $data->{name} =~ s/\s+$//g;

  my $ey = $data->{end_year} // '';
  if ($data->{name} eq 'Eitoku') { # 弘和/永徳
    $ey = 1384.2; # {1381, 1384.2}
  }
  if (defined $Data->{$data->{start_year}, $ey}) {
    warn "Duplicate ($data->{start_year}, $ey)";
  } else {
    $Data->{$data->{start_year}, $ey} = $data;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
