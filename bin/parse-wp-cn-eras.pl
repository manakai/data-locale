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

my $h1 = $doc->query_selector ('h1');
$Data->{page_name} = $h1->text_content;

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
        $caption =~ /^(新朝)之後，更始至東漢初建立的各政權年號$/ or
        $caption =~ /^(\w+)時期建立的其他政權的年號$/ or
        $caption =~ /^(\w+)統治地區出現的其他割據勢力的年號$/) {
      $caption = $1.'/misc';
    } elsif ($caption =~ /^(\w+)政權年號$/) {
      $caption = $1;
    } elsif ($caption =~ /^(\w+?)之?年號$/) {
      $caption = $1;
    }
  } else {
    $caption = $headline;
  }
  $caption =~ s/^續唐/唐/g;
  $caption = '隋/misc'
      if $caption eq '隋末農民起義時各割據勢力年號' or
         $caption eq '隋末農民起義時各割據勢力';
  my @row = $table_el->rows->to_list;
  shift @row;
  for my $tr (@row) {
    my $cells = $tr->cells->to_a;
    next if @$cells == 1;
    my $data = {};
    $data->{name} = $cells->[0]->text_content;
    next if $data->{name} eq '（停用年號）' or
            $data->{name} eq '（停用年号）';
    $data->{dup} = 1 if $tr->has_attribute ('bgcolor') or
                        $cells->[0]->has_attribute ('bgcolor');
    $data->{might_dup} = 1 if $cells->[-1]->text_content =~ /復/;
    push @{$Data->{eras}}, $data;
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
    if (not defined $data->{wref}) {
      $data->{name} =~ s/\[[^\[\]]+\]$//;
    }
    $data->{caption} = $caption;
    my $time_range = $cells->[1]->text_content;
    if ($time_range =~ /^(前|)(\d+)年(\w+月(\w+日|)|)(?:\x{2014}|\x{FF0D}|\[|[春夏秋冬]|$)/) {
      my $start_year = $1 ? 1 - $2 : $2;
      $data->{offset} = $start_year - 1;
    } elsif ($time_range =~ /^(\d{4})$/) {
      my $start_year = $1;
      $data->{offset} = $start_year - 1;
    } elsif ($time_range =~ /年/) {
      for (@{$cells->[1]->children->to_a}) {
        if ($_->local_name eq 'br') {
          $cells->[1]->replace_child ($doc->create_text_node ("\x{1234}"), $_);
        }
      }
      $time_range = $cells->[1]->text_content;
      my @offset;
      for (split /\x{1234}/, $time_range) {
        if (/(?:^|：)([0-9]+)年(?!代)/) {
          push @offset, $1 - 1;
        }
      }
      $data->{offset} = shift @offset;
      if (@offset) {
        for (@offset) {
          my $data2 = {%$data, offset => $_};
          push @{$Data->{eras}}, $data2;
        }
      }
    } # $time_range
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
