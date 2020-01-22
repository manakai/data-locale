use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::URL::Encoding;
use Web::DOM::Document;
binmode STDOUT, qw(:encoding(utf-8));

my $RootPath = path (__FILE__)->parent->parent;

my $cols = [
  {key => 'name', type => 'text', info => 1},
  {key => 'summary', type => 'text'},
];

{
  use utf8;
  my $IndexToKanshi = {map { my $x = $_; $x =~ s/\s+//g; $x =~ s/(\d+)/' '.($1-1).' '/ge;
                           grep { length } split /\s+/, $x } q{
1甲子2乙丑3丙寅4丁卯5戊辰6己巳7庚午8辛未9壬申10癸酉11甲戌12乙亥13丙子
14丁丑15戊寅16己卯17庚辰18辛巳19壬午20癸未21甲申22乙酉23丙戌24丁亥25戊子
26己丑27庚寅28辛卯29壬辰30癸巳31甲午32乙未33丙申34丁酉35戊戌36己亥
37庚子38辛丑39壬寅40癸卯41甲辰42乙巳43丙午44丁未45戊申46己酉47庚戌48辛亥
49壬子50癸丑51甲寅52乙卯53丙辰54丁巳55戊午56己未57庚申58辛酉59壬戌60癸亥
}};
  sub year2kanshi ($) { $IndexToKanshi->{($_[0]-4)%60} }
}

my $EraData = {};
my $RefData;
my $Refs = [];
{
  $RefData = my $json = json_bytes2perl $RootPath->child ('local/era-kodai.json')->slurp;
  for my $ref (sort {
    ($json->{$a}->{published_year_start} || $json->{$a}->{published_year_end})
        <=>
    ($json->{$b}->{published_year_start} || $json->{$b}->{published_year_end})
        ||
    $a <=> $b;
  } keys %{$json}) {
    for my $era (@{$json->{$ref}->{eras}}) {
      if (defined $era->{start_year}) {
        $EraData->{$_}->{$ref}->{$era->{start_year}} = 1 for @{$era->{names}};
      } else {
        $EraData->{$_}->{$ref}->{'x'} = 1 for @{$era->{names}};
      } # start_year
    }
    push @$cols, {key => $ref};
    $cols->[-1]->{highlighted} = 1 if
        $ref == 6151 or $ref == 6251 or $ref == 6001;
    push @$Refs, $ref;
  }
}

my $CommonEraYear = {};
for my $name (sort { $a cmp $b } keys %$EraData) {
  my $found = {};
  for my $ref (sort { $a <=> $b } keys %{$EraData->{$name}}) {
    for my $year (sort { $a cmp $b } keys %{$EraData->{$name}->{$ref}}) {
      $found->{$year}++;
    }
  }
  delete $found->{x};
  $CommonEraYear->{$name} = [sort { $found->{$b} <=> $found->{$a} || $a <=> $b } keys %$found]->[0]; # or undef
}
my $EraNames = do {
  use utf8;
  [sort {
    ($a =~ /天皇|皇后/ ? 1 : 0) <=> ($b =~ /天皇|皇后/ ? 1 : 0) ||
    ($CommonEraYear->{$a} // 9999) <=> ($CommonEraYear->{$b} // 9999) ||
    $a cmp $b;
  } keys %{$EraData}];
};

my $rows = [];

{
  my $row = [];
  push @$row, [''], [''];
  for my $ref (@$Refs) {
    push @$row, [(sprintf '%s--%s',
        $RefData->{$ref}->{published_year_start} // '',
        $RefData->{$ref}->{published_year_end}), ''];
  }
  push @$rows, $row;
}

for my $name (@$EraNames) {
  my $row = [];
  my $summary = [];
  for my $ref (@$Refs) {
    push @$row, [sort {
      ($a eq 'x') cmp ($b eq 'x') ||
      $a <=> $b;
    } keys %{$EraData->{$name}->{$ref} or {}}];
    push @$summary, keys %{$EraData->{$name}->{$ref} or {}};
  }
  my $found = {x => 1};
  unshift @$row, [sort { $a <=> $b } grep { not $found->{$_}++ } @$summary];
  unshift @$row, [$name];
  push @$rows, $row;
}

my $doc = new Web::DOM::Document;
$doc->manakai_is_html (1);
$doc->inner_html (q[<!DOCTYPE HTML><meta charset=utf-8><title>Eras</title>
<!--

Per CC0 <https://creativecommons.org/publicdomain/zero/1.0/>, to the
extent possible under law, the author of this document has waived all
copyright and related or neighboring rights to this document.

-->
<style>
  html {
    font-size: 80%;
  }

  td > span + span::before {
    content: " ";
  }

  .highlighted {
    background: #eee;
  }

  .pattern-1 { background-color: #ffdddd }
  .pattern-2 { background-color: #ffffdd }
  .pattern-3 { background-color: #ddffdd }
  .pattern-4 { background-color: #dde5ff }
  .pattern-5 { background-color: #ffcccc }
  .pattern-6 { background-color: #cc99cc }
  .pattern-7 { background-color: #FFEFD5 }
  .pattern-8 { background-color: #E0FFFF }
  .pattern-9 { background-color: #98FB98 }
  .pattern-10 { background-color: #ADD8E6 }
  .pattern-11 { background-color: #F0E68C }
  .pattern-12 { background-color: #FFA07A }

</style>
<h1>Eras</h1><table><colgroup><thead><tr><tbody></table>]);

{
  my $tr = $doc->query_selector ('colgroup');
  for (@$cols) {
    next if $_->{hidden};
    my $td = $doc->create_element ('col');
    if (defined $_->{highlighted}) {
      $td->set_attribute ('class', 'highlighted');
    }
    $tr->append_child ($td);
  }
}

{
  my $tr = $doc->query_selector ('thead tr');
  for (@$cols) {
    next if $_->{hidden};
    my $td = $doc->create_element ('th');
    if (defined $_->{label}) {
      $td->text_content ($_->{label});
    } elsif ($_->{key} =~ /^([0-9]+)$/) {
      my $a = $doc->create_element ('a');
      $a->set_attribute (href => q<https://wiki.suikawiki.org/n/%E5%8F%A4%E4%BB%A3%E5%B9%B4%E5%8F%B7#anchor-> . $1);
      $a->text_content ('#' . $1);
      $td->append_child ($a);
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

  my $patterns = {};
  my $next_pattern = 1;
  my $pattern = sub {
    my $key = shift;
    return '' unless length $key;
    return '' if $key eq 'x';
    use utf8;
    $key =~ s/繩/縄/g;
    $key =~ s/當/当/g;
    $key =~ s/稱/称/g;
    return 'pattern-' . (($patterns->{$key} ||= $next_pattern++));
  };
  
    my $tr = $doc->create_element ('tr');
    for (0..$#$cols) {
      next if $cols->[$_]->{hidden};
      my $td = $doc->create_element ('td');
      if (defined $row->[$_]) {
        for my $x (@{$row->[$_]}) {
          my $e = $doc->create_element ('span');
          $e->set_attribute ('class', $pattern->($x))
              unless $cols->[$_]->{info};
          if ($x =~ /^-?[0-9]+$/) {
            $e->text_content ($x . ' ' . year2kanshi $x);
          } else {
            $e->text_content ($x);
          }
          $td->append_child ($e);
          $td->append_child ($doc->create_text_node ("\x0A"));
        }
        if ($cols->[$_]->{key} eq 'name') {
          # DEBUG
          #$td->append_child ($doc->create_text_node ($CommonEraYear->{$row->[$_]->[0]} // 9999));
        }
      }
      $tr->append_child ($td);
    }
    $tbody->append_child ($tr);
  }
}

print $doc->inner_html;

## License: Public Domain.
