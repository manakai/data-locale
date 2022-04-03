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
$doc->manakai_set_url (q<https://ko.wikipedia.org/wiki/>);
$doc->inner_html ($input);

my $Data = {eras => []};

my $h1 = $doc->query_selector ('h1');
$Data->{page_name} = $h1->text_content;
$Data->{wref_key} = 'wref_ko';

sub process_list ($$) {
  my ($headline, $list_el) = @_;

  return if $headline eq '같이 보기' or
            $headline eq '각주' or
            $headline eq '외부 링크';
  
  for my $li_el ($list_el->children->to_list) {
    next unless $li_el->local_name eq 'li';
    my $text = $li_el->text_content;
    my $link = $li_el->first_element_child;
    my $wref;
    if (defined $link and
        $link->local_name eq 'a' and
        $link->href =~ m{^https://ko.wikipedia.org/wiki/([^?#]+)}) {
      my $name = $1;
      $wref = percent_decode_c $name;
    }
    if ($text =~ m{^(\p{Hang}+)\s*\((\p{Hani}+)\)\s*([0-9]+)년}) {
      my $data = {
        caption => $headline,
        hangul => $1,
        tw => $2,
        offset => $3 - 1,
        wref => $wref,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^(\p{Hang}+)\s*\((\p{Hani}+)[:)] [^()]+?, ([0-9]+)\s*[~)]}) {
      my $data = {
        caption => $headline,
        hangul => $1,
        tw => $2,
        offset => $3 - 1,
        wref => $wref,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^(\p{Hang}+)\s*\((\p{Hani}+)\s*[,:]\s*([0-9]+)\s*[~.]}) {
      my $data = {
        caption => $headline,
        hangul => $1,
        tw => $2,
        offset => $3 - 1,
        wref => $wref,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^(\p{Hang}+)$}) {
      my $data = {
        caption => $headline,
        hangul => $1,
        wref => $wref,
      };
      push @{$Data->{eras}}, $data;
    } elsif ($text =~ m{^(\p{Hang}+)\s*\((\p{Hani}+):\s*([0-9]+년(?:(?:,| 또는) [0-9]+년)*)}) {
      my $hang = $1;
      my $hani = $2;
      my $years = $3;
      my @offset;
      while ($years =~ /([0-9]+)/g) {
        push @offset, $1 - 1;
      }
      for (@offset) {
        my $data = {
          caption => $headline,
          hangul => $hang,
          tw => $hani,
          offset => $_,
          wref => $wref,
        };
        push @{$Data->{eras}}, $data;
      }
    } elsif ($text =~ m{^(\p{Hang}□)\s*\((\p{Hani}□)\)}) {
      my $data = {
        caption => $headline,
        hangul => $1,
        tw => $2,
        wref => $wref,
      };
      push @{$Data->{eras}}, $data;
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
    $t =~ s/\s+/ /;
    $t =~ s/^ //;
    $t =~ s/ $//;
    $t .= '~' while $found->{$t}++;
    push @$headers, $t;
  }

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

    my @map;
    if (defined $input->{"서기"} and defined $input->{"조선기년법"}) {
      push @map, [$input->{"서기"}, $input->{"조선기년법"}];
      push @map, [$input->{"서기~"}, $input->{"조선기년법~"}]
          if defined $input->{"서기~"};
      push @map, [$input->{"서기~~"}, $input->{"조선기년법~~"}]
          if defined $input->{"서기~~"};
    }
    for my $map (@map) {
      for (split /,\s*/, $map->[1]) {
        my $data = {caption => $caption};
        if ($map->[0] =~ /^([0-9]+)년$/) {
          $data->{offset} = $1 - 0;
        }
        if (/^(\p{Hang}+)\s*원년$/) {
          $data->{hangul} = $1;
          $data->{offset} -= 1;
          $HangulToOffset->{$data->{hangul}} = $data->{offset};
        } elsif (/^(\p{Hang}+)\s*([0-9]+)년$/) {
          $data->{hangul} = $1;
          $data->{offset} -= $2;
        } else {
          push @{$Data->{_errors}},
              ["Year parse error", $_];
        }
        push @{$Data->{eras}}, $data;
      }
    }
    next if @map;

    my $data = {};
    my @hang;
    my @hani;
    if (defined $input->{"연호"}) {
      if ($input->{"연호"} =~ /^(\p{Hang}+)$/) {
        push @hang, $1;
      } else {
        push @{$Data->{_errors} ||= []},
            ["Parse error 1", $input->{"연호"}];
      }
    }
    if (defined $input->{"연호 이름"}) {
      if ($input->{"연호 이름"} =~ /^(\p{Hang}+)$/) {
        push @hang, $1;
      } elsif ($input->{"연호 이름"} =~ /^(\p{Hang}+)\s*\((\p{Hang}+)\)$/) {
        push @hang, $1, $2;
      } elsif ($input->{"연호 이름"} =~ m{^(\p{Hang}+)\s*\((\p{Hang}+)/(\p{Hang}+)\)$}) {
        push @hang, $1, $2, $3;
      } elsif ($input->{"연호 이름"} =~ m{^(\p{Hang}+)\s*\((\p{Hang}+)/(\p{Hang}+)/(\p{Hang}+)\)$}) {
        push @hang, $1, $2, $3, $4;
      } elsif ($input->{"연호 이름"} =~ m{^\(미개원\)$} or
               $input->{"연호 이름"} =~ m{천황 붕어로 사용정지}) {
        next;
      } else {
        push @{$Data->{_errors} ||= []},
            ["Parse error 2", $input->{"연호 이름"}];
      }
    }
    if (defined $input->{"한자"}) {
      if ($input->{"한자"} =~ /^(\p{Hani}+)$/) {
        push @hani, $1;
      } elsif ($input->{"한자"} =~ m{^(\p{Hani}+)\s*\((\p{Hani}+)\)$}) {
        push @hani, $1, $2;
      } elsif ($input->{"한자"} =~ m{^(\p{Hani}+)\s*\((\p{Hani}+)/(\p{Hani}+)\)$}) {
        push @hani, $1, $2, $3;
      } elsif ($input->{"한자"} =~ m{^(\p{Hani}+)\s*\((\p{Hani}+)/(\p{Hani}+)/(\p{Hani}+)\)$}) {
        push @hani, $1, $2, $3, $4;
      } else {
        push @{$Data->{_errors} ||= []},
            ["Parse error 3", $input->{"한자"}];
      }
    }
    if (defined $input->{"한자 표기(일본식/번체)"}) {
      if ($input->{"한자 표기(일본식/번체)"} =~ m{^(\p{Hani}+)$}) {
        $data->{ja} = $1;
        push @hani, $1;
      } elsif ($input->{"한자 표기(일본식/번체)"} =~ m{^(\p{Hani}+)\((\p{Hani}+)\)$}) {
        $data->{ja} = $1;
        push @hani, $2;
      } else {
        push @{$Data->{_errors} ||= []},
            ["Han parse errror", $input->{"한자 표기(일본식/번체)"}];
      }
    }
    if (defined $input->{"한국 한자음"}) {
      $data->{ja_hanguls} = \@hang;
      @hang = ();
      if ($input->{"한국 한자음"} =~ m{^(\p{Hang}+)$}) {
        push @hang, $1;
      } elsif ($input->{"한국 한자음"} =~ m{^(\p{Hang}+)\s*\((\p{Hang}+)\)$}) {
        push @hang, $1, $2;
      } else {
        push @{$Data->{_errors} ||= []},
            ["Hangul parse errror", $input->{"한국 한자음"}];
      }
    }
    if (defined $input->{"한글"}) {
      $data->{vn_hanguls} = \@hang;
      @hang = ();
      if ($input->{"한글"} =~ m{^(\p{Hang}+)$}) {
        push @hang, $1;
      } else {
        push @{$Data->{_errors} ||= []},
            ["Hangul parse error 2", $input->{"한글"}];
      }
    }
    if (defined $input->{"베트남어"}) {
      if ($input->{"베트남어"} =~ m{^(\p{Latn}+(?:\s+\p{Latn}+)+)$}) {
        $data->{vi} = $1;
      } else {
        push @{$Data->{_errors} ||= []},
            ["Vietnamese parse error", $input->{"베트남어"}];
      }
    }
    if (defined $input->{"가나 표기"}) {
      if ($input->{"가나 표기"} =~ m{^(\p{Hira}+)$}) {
        push @{$data->{kanas} ||= []}, $1;
      } elsif ($input->{"가나 표기"} =~ m{^(\p{Hira}+)\s*\(([\p{Hira}]+)\)$}) {
        push @{$data->{kanas} ||= []}, $1, $2;
      } elsif ($input->{"가나 표기"} =~ m{^(\p{Hira}+)\s*\(([\p{Hira}]+)/(\p{Hira}+)\)$}) {
        push @{$data->{kanas} ||= []}, $1, $2, $3;
      } else {
        push @{$Data->{_errors} ||= []},
            ["Kana parse errror", $input->{"가나 표기"}];
      }
    }
    if (@hang == 1 and @hani > 1) {
      for (1..$#hani) {
        $hang[$_] = $hang[0];
      }
    }
    if (@{$data->{kanas} or []} and @hang == 2 and @hani == 1) {
      $hani[1] = $hani[0];
    }
    push @{$Data->{_errors} ||= []},
        ["Inconsistent #Hang and #Hani", [@hang], [@hani]]
        unless @hang == @hani;
    
    $data->{_range} = $input->{"사용 기간"} if defined $input->{"사용 기간"};

    my $time_range = $input->{"사용기간(음력/양력)"} // $input->{"사용기간(음력)"} // $input->{"사용년도(음력/양력)"};
    if (defined $time_range) {
      if ($time_range =~ m{^기원전 ([0-9]+)년}) {
        $data->{offset} = 1 - $1 - 1;
      } elsif ($time_range =~ m{^([0-9]+)년}) {
        $data->{offset} = $1 - 1;
      }
    }

    my $link;
    if (defined $tds->{"연호 이름"}) {
      $link = $tds->{"연호 이름"}->query_selector ('a');
    }
    if (defined $link and
        $link->local_name eq 'a' and
        $link->href =~ m{^https://ko.wikipedia.org/wiki/([^?#]+)}) {
      my $name = $1;
      $data->{wref} = percent_decode_c $name;
    }

    next unless keys %$data;
    $data->{caption} = $caption;

    if (@hang == @hani) {
      for (0..$#hang) {
        my $data2 = {%$data};
        $data2->{hangul} = $hang[$_];
        $data2->{tw} = $hani[$_];
        push @{$Data->{eras}}, $data2;
      }
    } else {
      {
        my $data2 = {%$data};
        $data2->{hangul} = $hang[0];
        $data2->{tw} = $hani[0];
        push @{$Data->{eras}}, $data2;
      }
      shift @hang;
      shift @hani;
      for (@hang) {
        my $data2 = {%$data};
        $data2->{hangul} = $_;
        push @{$Data->{eras}}, $data2;
      }
      for (@hani) {
        my $data2 = {%$data};
        $data2->{tw} = $_;
        push @{$Data->{eras}}, $data2;
      }
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
