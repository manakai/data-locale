use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $RootPath = path (__FILE__)->parent->parent->parent;
my $TempPath = $RootPath->child ('local/wikimedia');

my $Data = {};

sub extract_source ($) {
  my $html = $_[0];
  $html =~ s{^.+<textarea[^<>]*>}{}s;
  $html =~ s{</textarea>.*$}{}s;
  $html =~ s/&lt;/</g;
  $html =~ s/&amp;/&/g;

  $html = decode_web_utf8 $html;
  $html =~ s/&#x([0-9a-f]+);/chr hex $1/ge;
  $html =~ s/&#([0-9]+);/chr $1/ge;
  return $html;
} # extract_source

$Data->{source_type} = shift or die;

{
  local $/ = undef;
  my $bytes = scalar <>;

  my $data = [];
  my @filler;
  for (split /\x0D?\x0A/, extract_source $bytes) {
    if (/^\|-/) {
      if ($Data->{source_type} eq 'table5' and
          @$data and
          $data->[0] =~ /143/) {
        splice @$data, 16, 0, ('');
      }
      
      $data = [];
      push @{$Data->{rows}}, $data;
    } elsif (/^\|\}$/) {
      if ($Data->{source_type} eq 'table7') {
        push @filler, '';
      } else {
        last;
      }
    } elsif (/^\|/) {
      s{^\|}{};

      if ($Data->{source_type} eq 'table3') {
        s{^colspan="\d+"\|}{} and push @$data, '';
      }
      if (@$data == 2) {
        push @$data, @filler;
      }

      s{<ref[^<>]*>.*?</ref>}{}g;
      s{<ref[^<>]*/>}{}g;
      s{-\{(\w)\}-}{$1}g;
      
      push @$data, $_;
    } elsif (/^\!/) {
      push @$data, $_;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
