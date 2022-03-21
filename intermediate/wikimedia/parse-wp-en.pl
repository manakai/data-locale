use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use Web::Encoding;
use Web::URL::Encoding;
use Web::DOM::Document;
use Web::HTML::Table;
use JSON::PS;

local $/ = undef;
my $input = decode_web_utf8 <>;
my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->manakai_set_url (q<https://en.wikipedia.org/wiki/>);
$doc->inner_html ($input);

my $Data = {eras => []};

my $h1 = $doc->query_selector ('h1');
$Data->{page_name} = $h1->text_content;
$Data->{wref_key} = 'wref_en';

sub process_list ($$) {
  my ($headline, $list_el) = @_;

  return if $headline eq 'See also' or
            $headline eq 'Notes' or
            $headline eq 'Bibliography' or
            $headline eq 'References' or
            $headline eq 'Citations';
  
  for my $li_el ($list_el->children->to_list) {
    next unless $li_el->local_name eq 'li';
    my $text = $li_el->text_content;
    my $link = $li_el->first_element_child;
    my $wref;
    if (defined $link and
        $link->local_name eq 'a' and
        $link->href =~ m{^https://en.wikipedia.org/wiki/([^?#]+)}) {
      my $name = $1;
      $wref = percent_decode_c $name;
    }
    if ($text =~ m{^(\p{Latn}[\p{Latn}\s-]+\p{Latn})\s*\((\p{Hang}+),\s*(\p{Hani}+)[^():]+?[:,]\s*([0-9]+)}) {
      my $data = {
        caption => $headline,
        en => $1,
        hangul => $2,
        tw => $3,
        offset => $4 - 1,
        wref => $wref,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^Reign of Emperor }) {
      my $data = {};
      if ($text =~ m{([0-9]+)–[0-9]+\[[0-9]+\] \.\.\. \p{Latn}+ \(period\) or (\p{Latn}+)\[[0-9]+\]\s*\(or (\p{Latn}+)\)}) {
        $data->{offset} = $1 - 1;
        $data->{romaji} = $2;
        $data->{romajis} = [$3];
      } elsif ($text =~ m{([0-9]+)–[0-9]+\[[0-9]+\] \.\.\. \p{Latn}+ \(period\) or (\p{Latn}+) period}) {
        $data->{offset} = $1 - 1;
        $data->{romaji} = $2;
      }
      if (keys %$data) {
        $data->{caption} = $headline;
        $data->{wref} = $wref;
        push @{$Data->{eras}}, $data;
      }
    } elsif ($text =~ m{^Reign of Empress }) {
      #
    } elsif ($text =~ m{^Regency of Empress }) {
      #
    } else {
      push @{$Data->{_errors} ||= []},
          ['List item parse error', $text];
    }
  }
} # process_list

my $HangulToOffset = {};
sub process_table ($$) {
  my ($caption, $table_el) = @_;

  my $impl = Web::HTML::Table->new;
  my $table = $impl->form_table ($table_el);

  my $headers = [];
  my $found = {};
  for my $x (0..$#{$table->{column}}) {
    my $cell = $table->{cell}->[$x]->[0];
    next unless defined $cell and @$cell;
    my $th = $cell->[0]->{element};
    next unless defined $th;
    my $t = $th->text_content;
    $t =~ s/\s+/ /g;
    $t =~ s/^ //;
    $t =~ s/ $//;
    $t .= '~' while $found->{$t}++;
    push @$headers, $t;
  }

  my $latin_key = '_X'.'XX';
  $latin_key = 'en_pinyin' if $Data->{page_name} =~ /Chinese/;
  $latin_key = 'en' if $Data->{page_name} =~ /Korean/;
  $latin_key = 'vi' if $Data->{page_name} =~ /Vietnamese/;
  $latin_key = 'romaji' if $Data->{page_name} =~ /Japanese/;

  for my $y (1..$#{$table->{row}}) {
    my $input = {};
    my $tds = {};
    for my $x (0..$#{$table->{column}}) {
      my $cell = $table->{cell}->[$x]->[$y];
      next unless defined $cell and @$cell;
      my $td = $cell->[0]->{element};
      next unless defined $td;
      $input->{$headers->[$x]} = $td->text_content;
      $tds->{$headers->[$x]} = $td;
    }

    next if @{$table->{cell}->[0]->[$y] or []} and
            @{$table->{cell}->[-1]->[$y] or []} and
            $table->{cell}->[0]->[$y]->[0]->{element} eq $table->{cell}->[-1]->[$y]->[0]->{element};

    my $data = {};

    my $name_all = $input->{"Era name"} // '';
    if ($name_all =~ m{^([\p{Latn}'-]+(?:\s+\p{Latn}+)*)(\p{Hani}+)$}) {
      $data->{$latin_key} = $1;
      $data->{tw} = $2;
    } elsif ($name_all =~ m{^([\p{Latn}'-]+)(\p{Hani}+)(\p{Hang}+)$}) {
      $data->{$latin_key} = $1;
      $data->{tw} = $2;
      $data->{hangul} = $3;
    } elsif ($name_all =~ m{^([\p{Latn}'-]+)\s*\(([\p{Latn}']+)\)(\p{Hani}+)(\p{Hang}+)$}) {
      $data->{$latin_key} = $1;
      $data->{en2} = $2;
      $data->{tw} = $3;
      $data->{hangul} = $4;
    } elsif ($name_all =~ m{^Era names not known$}) {
      $data->{name} = $data->{tw} = '？？';
    } else {
      push @{$Data->{_errors} ||= []},
          ["Name parse error", $name_all];
    }

    my $note = $input->{"Remark"} // '';
    my @other;
    if ($note =~ m{^((?:(?:Or|,|(?:\.\s*|)Sometimes erroneously referred to as) [\p{Latn}']+(?:\s+\p{Latn}+)*\s*\(\p{Hani}+\))+)}) {
      my $n = $1;
      while ($n =~ /([\p{Latn}']+(?:\s+\p{Latn}+)*)\s*\((\p{Hani}+)\)/g) {
        my $x = $1;
        my $y = $2;
        $x =~ s/^Or //;
        $x =~ s/^Sometimes erroneously referred to as //;
        push @other, [$x, $y];
      }
    }
    if ($note =~ m{^((?:(?:Also rendered as|and|, and|,) [\p{Latn}']+(?:-\p{Latn}+)*\s*)+)}) {
      my $n = $1;
      for (split /Also rendered as|, and|and|,/, $n) {
        my $v = $_;
        $v =~ s/\s+/ /;
        $v =~ s/^ //;
        $v =~ s/ $//;
        push @{$data->{romajis} ||= []}, $v if length $v;
      }
    }
    $data->{dup} = 1 if $note =~ /Restored/;
    
    my $range = $input->{"Period of use"} // '';
    if ($range =~ m{^([0-9]+)–([0-9]+) BCE$}) {
      $data->{offset} = 1 - $1 - 1;
    } elsif ($range =~ m{^([0-9]+) BCE$}) {
      $data->{offset} = 1 - $1 - 1;
    } elsif ($range =~ m{^([0-9]+)–([0-9]+) (?:CE|AD)}) {
      $data->{offset} = $1 - 1;
    } elsif ($range =~ m{^([0-9]+) (?:CE|AD)}) {
      $data->{offset} = $1 - 1;
    } elsif ($range =~ m{^Unknown$} or
             $range =~ m{^\?} or
             $range =~ m{^Late } or
             $range =~ m{^Did not use$}) {
      #
    } else {
      push @{$Data->{_errors} ||= []},
          ["Range parse error", $range];
    }

    my $link;
    if (defined $tds->{"Era name"}) {
      $link = $tds->{"Era name"}->query_selector ('a');
    }
    if (defined $link and
        $link->local_name eq 'a' and
        $link->href =~ m{^https://en.wikipedia.org/wiki/([^?#]+)}) {
      my $name = $1;
      $data->{wref} = percent_decode_c $name;
    }

    next unless keys %$data;
    $data->{caption} = $caption;

    $data->{dup} = 1 if ($table->{row}->[$y]->{element}->get_attribute ('style') // '') eq 'background:#DAF2FF;';

    push @{$Data->{eras}}, $data;
    for (@other) {
      my $data2 = {%$data};
      $data2->{$latin_key} = $_->[0];
      $data2->{tw} = $_->[1];
      push @{$Data->{eras}}, $data2;
    }
  }
} # process_table

my $headline;
my @ul;
my @ol;
my $has_table = 0;
for my $table_el ($doc->query_selector_all ('.wikitable, .mw-headline, ul, ol')->to_list) {
  if ($table_el->local_name eq 'table') {
    $has_table = 1;
  } elsif ($table_el->local_name eq 'ul') {
    push @ul, $table_el;
    next;
  } elsif ($table_el->local_name eq 'ol') {
    push @ol, $table_el;
    next;
  } else {
    if ((@ul or @ol) and not $has_table and defined $headline) {
      if (@ol) {
        process_list $headline, $_ for @ol;
      } else {
        process_list $headline, $_ for @ul;
      }
    }
    $has_table = 0;
    @ul = @ol = ();
    $headline = $table_el->text_content;
    next;
  }
  
  my $caption;
  my $cap_el = $table_el->caption;
  if (defined $cap_el) {
    $caption = $cap_el->text_content;
  } else {
    $caption = $headline;
  }
  $caption =~ s{^Other regimes contemporaneous with (.+)$}{$1/misc}g;

  process_table $caption, $table_el;
}

for my $data (@{$Data->{eras}}) {
  if (defined $data->{_range}) {
    if ($data->{_range} =~ m{^(\p{Hang}+)\s*([0-9]+)년}) {
      my $hang = $1;
      my $year = $2;
      if (defined $HangulToOffset->{$hang}) {
        $data->{offset} = $HangulToOffset->{$hang} + $year - 1;
        delete $data->{_range};
      } else {
        push @{$Data->{_errors}},
            ["Unknown year", $data->{_range}];
      }
    } else {
      push @{$Data->{_errors}},
          ["Range parse error", $data->{_range}];
    }
  }
  
  $data->{name} //= $data->{tw} // $data->{ja} // $data->{romaji} // $data->{hangul};
  if (defined $data->{offset}) {
    $data->{ukey} = ($data->{ja} // $data->{tw} // $data->{vi} // $data->{name}) . ',' . $data->{offset};
  } else {
    $data->{ukey} = ($data->{ja} // $data->{tw} // $data->{vi} // $data->{name});
  }
  unless (defined $data->{caption}) {
    push @{$Data->{_errors}},
        ['Caption missing', $data->{ukey}];
  }
} # $data

print perl2json_bytes_for_record $Data;

## License: Public Domain.
