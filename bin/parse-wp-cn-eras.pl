use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::Encoding;
use Web::URL::Encoding;
use Web::DOM::Document;
use JSON::PS;

local $/ = undef;
my $input = decode_web_utf8 <>;
my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->manakai_set_url (q<https://zh.wikipedia.org/wiki/%E4%B8%AD%E5%9B%BD%E5%B9%B4%E5%8F%B7%E5%88%97%E8%A1%A8>);
$doc->inner_html ($input);

my $Data = {eras => []};

my $headline;
for my $table_el ($doc->query_selector_all ('.wikitable, .mw-headline')->to_list) {
  unless ($table_el->local_name eq 'table') {
    $headline = $table_el->text_content;
    next;
  }
  my $caption;
  my $cap_el = $table_el->caption;
  if (defined $cap_el) {
    $caption = $cap_el->text_content;
    if ($caption =~ /^(\w+)統治地區出現的其他勢力年號$/ or
        $caption =~ /^(\w+)統治地區其他不詳的年號$/ or
        $caption =~ /^(\w+)統治地區出現過的其他年號$/ or
        $caption =~ /^(\w+)統治地區出現的其他勢力的年號$/ or
        $caption =~ /^(\w+)統治地區出現的其他年號$/ or
        $caption =~ /^(\w+)統治地區其他勢力的年號$/ or
        $caption =~ /^(\w+)統治地區其他勢力年號$/ or
        $caption =~ /^新朝之後，更始至東漢初建立的各政權年號$/ or
        $caption =~ /^(\w+)時期建立的其他政權的年號$/ or
        $caption =~ /^(\w+)統治地區出現的其他割據勢力的年號$/) {
      $caption = 'misc';
    } elsif ($caption =~ /^(\w+)政權年號$/) {
      $caption = $1;
    } elsif ($caption =~ /^(\w+)年號$/) {
      $caption = $1;
    }
  } else {
    $caption = $headline;
  }
  $caption =~ s/^續唐/唐/g;
  $caption = 'misc'
      if $caption eq '隋末農民起義時各割據勢力年號' or
         $caption eq '隋末農民起義時各割據勢力';
  my @row = $table_el->rows->to_list;
  shift @row;
  for my $tr (@row) {
    my $cells = $tr->cells->to_a;
    next if @$cells == 1;
    my $data = {};
    push @{$Data->{eras}}, $data;
    $data->{dup} = 1 if $tr->has_attribute ('bgcolor');
    $data->{name} = $cells->[0]->text_content;
    my $link = $cells->[0]->get_elements_by_tag_name ('a')->[0];
    if (defined $link and
        $link->href =~ m{^https://zh.wikipedia.org/wiki/([^?#]+)}) {
      my $name = $1;
      $name = percent_decode_c $name;
      if ($link->text_content =~ /^\w+$/) {
        $data->{wref} = $name;
        $data->{name} = $link->text_content;
      }
    }
    if ($cells->[1]->text_content =~ /^(前|)(\d+)年(\w+月(\w+日|)|)(?:\x{2014}|\x{FF0D}|\[|[春夏秋冬]|$)/) {
      my $start_year = $1 ? 0 - $2 : $2;
      $data->{offset} = $start_year - 1;
    } elsif ($cells->[1]->text_content =~ /^(\d{4})$/) {
      my $start_year = $1;
      $data->{offset} = $start_year - 1;
    }
    $data->{caption} = $caption;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
