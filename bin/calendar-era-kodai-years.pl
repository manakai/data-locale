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
  {key => 'ad, bc/ad, kouki', type => 'text', info => 1},
  {key => 'kanshi', type => 'text', info => 1},
];

my $IndexToKanshi = {map { my $x = $_; $x =~ s/\s+//g; $x =~ s/(\d+)/' '.($1-1).' '/ge;
                           grep { length } split /\s+/, $x } q{
1甲子2乙丑3丙寅4丁卯5戊辰6己巳7庚午8辛未9壬申10癸酉11甲戌12乙亥13丙子
14丁丑15戊寅16己卯17庚辰18辛巳19壬午20癸未21甲申22乙酉23丙戌24丁亥25戊子
26己丑27庚寅28辛卯29壬辰30癸巳31甲午32乙未33丙申34丁酉35戊戌36己亥
37庚子38辛丑39壬寅40癸卯41甲辰42乙巳43丙午44丁未45戊申46己酉47庚戌48辛亥
49壬子50癸丑51甲寅52乙卯53丙辰54丁巳55戊午56己未57庚申58辛酉59壬戌60癸亥
}};

my $YearData = {};
my $RefData;
my $Refs;
{
  $RefData = my $json = json_bytes2perl $RootPath->child ('local/era-kodai.json')->slurp;
  for my $ref (sort {
    ($json->{$a}->{published_year_start} || $json->{$a}->{published_year_end})
        <=>
    ($json->{$b}->{published_year_start} || $json->{$b}->{published_year_end})
        ||
    $a <=> $b;
  } keys %{$json}) {
    my $has_data;
    for my $era (@{$json->{$ref}->{eras}}) {
      if (defined $era->{start_year}) {
        for my $y (1..$era->{length}) {
          my $ady = $era->{start_year} + $y - 1;
          push @{$YearData->{$ady}->{$ref} ||= []}, map {
            [$_ . $y, $_ . $era->{start_year}]
          } @{$era->{names}};
          $has_data = 1;
        }
      } else {
        push @{$YearData->{unknown}->{$ref} ||= []}, map {
          [$_, $_]
        } @{$era->{names}};
      } # start_year
    }
    if ($has_data) {
      push @$cols, {key => $ref};
      $cols->[-1]->{highlighted} = 1 if
          $ref == 6151 or $ref == 6251 or $ref == 6001;
      push @$Refs, $ref;
    }
  }
}

my $rows = [];

{
  my $row = [];
  push @$row, [['', '']], [['', '']];
  for my $ref (@$Refs) {
    push @$row, [[(sprintf '%s-%s',
        $RefData->{$ref}->{published_year_start} // '',
        $RefData->{$ref}->{published_year_end}), '']];
  }
  push @$rows, $row;
}

for my $ady (-666..701, 'unknown') {
  my $row = [];
  push @$row, [[$ady eq 'unknown' ? '?' : $ady, ''],
               [$ady eq 'unknown' ? '?' : $ady > 0 ? $ady : 'BC'.(1-$ady), ''],
               [$ady eq 'unknown' ? '?' : $ady+660, '']];
  push @$row, [[$ady eq 'unknown' ? '?' : $IndexToKanshi->{($ady-4)%60} . ' ' . (($ady-4) % 60), '']];
  for my $ref (@$Refs) {
    push @$row, $YearData->{$ady}->{$ref} || [];
  }
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
  .pattern-0 { background-color: #FFA07A }

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

  my $patterns = {};
  my $next_pattern = 1;
  my $pattern = sub {
    my $key = shift;
    return '' unless length $key;
    use utf8;
    $key =~ s/繩/縄/g;
    $key =~ s/當/当/g;
    $key =~ s/稱/称/g;
    return 'pattern-' . (($patterns->{$key} ||= $next_pattern++) % 12);
  };

  for my $row (@$rows) {
    my $tr = $doc->create_element ('tr');
    for (0..$#$cols) {
      next if $cols->[$_]->{hidden};
      my $td = $doc->create_element ('td');
      if (defined $row->[$_]) {
        for my $x (@{$row->[$_]}) {
          my $e = $doc->create_element ('span');
          $e->set_attribute ('class', $pattern->($x->[1]))
              unless $cols->[$_]->{info};
          $e->text_content ($x->[0]);
          $td->append_child ($e);
          $td->append_child ($doc->create_text_node ("\x0A"));
        }
      }
      $tr->append_child ($td);
    }
    $tbody->append_child ($tr);
  }
}

print $doc->inner_html;

## License: Public Domain.
