use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use Web::Encoding;
use Web::URL::Encoding;
use Web::DOM::Document;
use JSON::PS;

local $/ = undef;
my $input = decode_web_utf8 <>;
my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->manakai_set_url (q<https://vi.wikipedia.org/wiki/>);
$doc->inner_html ($input);

my $Data = {eras => []};

my $h1 = $doc->query_selector ('h1');
$Data->{page_name} = $h1->text_content;
$Data->{wref_key} = 'wref_vi';

sub process_list ($$) {
  my ($headline, $list_el) = @_;

  return if $headline eq 'Xem thêm' or
            $headline eq 'Chú thích' or
            $headline eq 'Tham khảo' or
            $headline eq 'Thống kê';

  for my $li_el ($list_el->children->to_list) {
    next unless $li_el->local_name eq 'li';
    my $text = $li_el->text_content;
    if ($text =~ m{^(\p{Latn}+\s\p{Latn}+)\s*\((\p{Hang}+), (\p{Hani}+):\s*([0-9]+)\s*[,-]}) {
      my $data = {
        caption => $headline,
        vi => $1,
        hangul => $2,
        tw => $3,
        offset => $4 - 1,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^(\p{Latn}+)\s*\((\p{Latn}+\s\p{Latn}+)\)\s*\((\p{Hang}+), (\p{Hani}+):\s*([0-9]+)\s*[-,]}) {
      my $data = {
        caption => $headline,
        kr_latin => $1,
        vi => $2,
        hangul => $3,
        tw => $4,
        offset => $5 - 1,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^(\p{Latn}[\p{Latn}-]+)\s*\((\p{Hang}+), (\p{Hani}+):\s*([0-9]+)\s*[-,)]}) {
      my $data = {
        caption => $headline,
        kr_latin => $1,
        hangul => $2,
        tw => $3,
        offset => $4 - 1,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^(\p{Latn}+)\s*\((\p{Hang}+), (\p{Hani}+):\s*[\p{Latn}\s]+,\s*([0-9]+)\s*[-,]}) {
      my $data = {
        caption => $headline,
        kr_latin => $1,
        hangul => $2,
        tw => $3,
        offset => $4 - 1,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^Triều đại Thiên hoàng \p{Latn}+, [0-9]+(?: [TS]CN|)–[0-9]+(?: [TS]CN|)(?:\[[0-9]+\]|)(?:\.\.\.\s*\p{Latn}+\s*\([^()]+\)(?:\[[0-9]+\]|)|)$}) {
      #
    } elsif ($text =~ m{^Triều đại Thiên hoàng \p{Latn}+, ([0-9]+)–[0-9]+\[[0-9]+\]\.\.\. \p{Latn}+ \(thời kỳ\) hay(?: thời kỳ|) (\p{Latn}+)(?:\[[0-9]+\]|)\s\(a/k/a\s+(\p{Latn}+)\)$}) {
      my $data = {
        caption => $headline,
        offset => $1 - 1,
        romaji => $2,
        romajis => [$3],
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^Triều đại Thiên hoàng \p{Latn}+, ([0-9]+)–[0-9]+\[[0-9]+\]\.\.\. \p{Latn}+ \(thời kỳ\) hay(?: thời kỳ|) (\p{Latn}+)(?:\[[0-9]+\]|)$}) {
      my $data = {
        caption => $headline,
        offset => $1 - 1,
        romaji => $2,
      };
      push @{$Data->{eras}}, $data;
    } else {
      push @{$Data->{_errors} ||= []},
          ['List item parse error', $text];
    }
  }
} # process_list

my $headline;
my @list;
my $has_table = 0;
for my $table_el ($doc->query_selector_all ('.wikitable, .mw-headline, ul')->to_list) {
  if ($table_el->local_name eq 'table') {
    $has_table = 1;
  } elsif ($table_el->local_name eq 'ul') {
    push @list, $table_el;
    next;
  } else {
    if (@list and not $has_table and defined $headline) {
      process_list $headline, $_ for @list;
    }
    $has_table = 0;
    @list = ();
    $headline = $table_el->text_content;
    next;
  }
  my $caption;
  my $cap_el = $table_el->caption;
  if (defined $cap_el) {
    $caption = $cap_el->text_content;
    if ($caption =~ /^Niên hiệu thế lực thống trị địa phương tại (\S.*\S)$/ or
        $caption =~ /^Niên hiệu thế lực thống trị địa phương thời (?:nhà |)(\S.*\S)$/ or
        $caption =~ /^Niên hiệu (?:nhà |)(\S.*\S)$/) {
      $caption = $1.'/misc';
    } elsif ($caption =~ /^Khác$/) {
      $caption = 'misc';
    }
  } else {
    $caption = $headline;
  }
  my @row = $table_el->rows->to_list;
  shift @row;
  for my $tr (@row) {
    my $cells = $tr->cells->to_a;
    next if @$cells == 1;
    my $data = {};

    push @{$Data->{eras}}, $data;

    $data->{dup} = 1 if $tr->has_attribute ('style');
    $data->{caption} = $caption;

    my $name_all = $cells->[0]->text_content;
    my $time_range = $cells->[1]->text_content;
    my @dup_name_tw;
    my @dup_name_vi;
    my $ja_table = 0;
    if (not $time_range =~ /[0-9]/ and
        $time_range =~ /\p{Hani}/) {
      my $name2 = $time_range;
      $time_range = $cells->[2]->text_content;

      if ($name2 =~ /^(\p{Hani}+)$/) {
        $data->{tw} //= $1;
        $data->{cn} //= $1;
      } elsif ($name2 =~ /^(\p{Hani}+)\s*\(hay\s+(\p{Hani}+)\)$/) {
        $data->{tw} //= $1;
        $data->{cn} //= $1;
        push @dup_name_tw, $2;
      }
    } elsif (not $time_range =~ /[0-9]/ and
             $time_range =~ m{^(\p{Latn}[\s\p{Latn}]*\p{Latn})$}) {
      $data->{vi} //= $1;
      $time_range = $cells->[2]->text_content;
      $ja_table = 1;
    } # $name2

    my $link = $cells->[0]->get_elements_by_tag_name ('a')->[0];
    if (defined $link and
        $link->href =~ m{^https://vi.wikipedia.org/wiki/([^?#]+)}) {
      my $name = $1;
      $name = percent_decode_c $name;
      if ($link->text_content =~ /^\w+$/) {
        $data->{wref} = $name;
        if ($ja_table) {
          $data->{romaji} = $link->text_content;
        } else {
          $data->{vi} = $link->text_content;
        }
      }
    }
    $name_all =~ s{大宝 \(后理}{大宝};
    $name_all =~ s{\[[0-9]+\]$}{};
    $name_all =~ s{\]$}{};
    $name_all =~ s{\{(囯)\}}{$1};
    $name_all =~ s{^(\p{Latn}[\s\p{Latn}]*\p{Latn})\s+\(\p{Latn}[\s\p{Latn}]*\p{Latn}\s*\(}{$1 (};
    $name_all =~ s{(興安)(兴安)}{$1/$2};
    $name_all =~ s{(聖明)(圣明)}{$1/$2};
    $name_all =~ s{(嘉慶)(嘉庆)}{$1/$2};
    if ($name_all =~ m{^(\p{Latn}[\s\p{Latn}]*\p{Latn})\s*\((\w+)/(\w+)\)?$}) {
      $data->{vi} //= $1;
      $data->{tw} = $2;
      $data->{cn} = $3;
    } elsif ($name_all =~ m{^(\p{Latn}[\s\p{Latn}'-]*\p{Latn})\s*\((\w+)\)?$}) {
      if ($ja_table) {
        $data->{romaji} //= $1;
        $data->{ja} //= $2;
      } else {
        $data->{vi} //= $1;
        $data->{tw} = $data->{cn} = $2;
      }
    } elsif ($name_all =~ m{^(\p{Latn}[\s\p{Latn}]*\p{Latn})$}) {
      $data->{vi} //= $1;
    } elsif ($name_all =~ m{^(\p{Latn}[\s\p{Latn}]*\p{Latn})\s*\(hay\s*(\p{Latn}[\s\p{Latn}]*\p{Latn})\)$}) {
      $data->{vi} //= $1;
      push @dup_name_vi, $2;
    } elsif ($name_all =~ m{^([\p{Latn}'-]+)\s*\(([\p{Hani}]+)\)\s*còn gọi là ([\p{Latn}'-]+)$}) {
      $data->{romaji} //= $1;
      $data->{ja} //= $2;
      push @{$data->{romajis} ||= []}, $3;
    } elsif ($name_all =~ m{^([\p{Latn}'-]+)\s*\(([\p{Hani}]+)\)\s*còn gọi là ([\p{Latn}'-]+) hay ([\p{Latn}'-]+)$}) {
      $data->{romaji} //= $1;
      $data->{ja} //= $2;
      push @{$data->{romajis} ||= []}, $3, $4;
    } elsif ($name_all =~ m{^([\p{Latn}'-]+)\s*\(([\p{Hani}]+)\)\s*còn gọi là ([\p{Latn}'-]+)(?: hay|,) ([\p{Latn}'-]+) hay ([\p{Latn}'-]+)$}) {
      $data->{romaji} //= $1;
      $data->{ja} //= $2;
      push @{$data->{romajis} ||= []}, $3, $4, $5;
    } elsif ($name_all =~ m{^([\p{Latn}'-]+)\s*\(([\p{Hani}]+)\)\s*còn gọi là ([\p{Latn}'-]+) hay ([\p{Latn}'-]+) hay ([\p{Latn}'-]+) hay ([\p{Latn}'-]+)$}) {
      $data->{romaji} //= $1;
      $data->{ja} //= $2;
      push @{$data->{romajis} ||= []}, $3, $4, $5, $6;
    } else {
      push @{$Data->{_errors}},
          ["Name parse error", $name_all];
    }
    $data->{vi} =~ s/( \p{Latn})/uc $1/e
        if {
          'Chính trị' => 1,
          'Hội đồng' => 1,
        }->{$data->{vi}};
    $data->{name} //= $data->{ja} // $data->{tw} // $data->{vi} // $data->{romaji};

    for my $time_range (split /\s+hay\s+/, $time_range) {
      $time_range =~ s/^có thể //;
      if ($time_range =~ m{^(?:[0-9]+/|)([0-9]+)\s+TCN}) {
        my $start_year = 1 - $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^([0-9]+)[—].+TCN}) {
        my $start_year = 1 - $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^(?:(?:tháng |)[0-9]+(?: nhuận|)/|)([0-9]+)(?:—|–|$)}) {
        my $start_year = $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^tháng [0-9]+-tháng [0-9]+/([0-9]+)$}) {
        my $start_year = $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^([0-9]+)\[[0-9]+\]:[0-9]+[—]}) {
        my $start_year = $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^[0-9]+- [0-9]+/([0-9]+) TCN}) {
        my $start_year = 1 - $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^[0-9]+-[0-9]+/([0-9]+)(?:$|—)}) {
        my $start_year = $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^[0-9]+-[0-9]+, [0-9]+/([0-9]+)(?:$|—)}) {
        my $start_year = $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^[0-9]-[0-9]([0-9]{4})(?:$|—)}) {
        my $start_year = $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^[0-9]+-[0-9]+ nhuận/([0-9]+)(?:$|—)}) {
        my $start_year = $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ m{^([0-9]+)\[[0-9]+\](?:—|$)}) {
        my $start_year = $1;
        $data->{offset} = $start_year - 1;
      } elsif ($time_range =~ /^？/) {
        #
      } elsif ($time_range eq '-') {
        #
      } elsif ($time_range =~ /\S/) {
        push @{$Data->{_errors} ||= []},
            ['Time range parse error', $time_range];
      } # $time_range
    }

    for my $i (0..$#dup_name_vi) {
      my $data2 = {%$data};
      $data2->{tw} = $data2->{cn} = $dup_name_tw[$i];
      $data2->{vi} = $dup_name_vi[$i];
      $data2->{name} = $data2->{ja} // $data2->{tw} // $data2->{cn} // $data2->{vi};
      push @{$Data->{eras}}, $data2;
    }
  }
}

for my $data (@{$Data->{eras}}) {
  $data->{name} //= $data->{tw} // $data->{ja} // $data->{romaji};
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
