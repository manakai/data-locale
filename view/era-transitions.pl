use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent;

my $Transitions;
{
  my $path = $RootPath->child ('data/calendar/era-transitions.json');
  my $json = json_bytes2perl $path->slurp;
  $Transitions = $json->{transitions};
}

my $Eras = {};
{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  for my $era (values %{$json->{eras}}) {
    $Eras->{$era->{id}} = $era;
  }
}

my $Tags;
{
  my $path = $RootPath->child ('data/tags.json');
  my $json = json_bytes2perl $path->slurp;
  $Tags = $json->{tags};
}

binmode STDOUT, qw(:encoding(utf-8));

sub print_day ($) {
  my $day = shift;
  print q{<dt-item>};
  printf qq{<p><a href=https://data.suikawiki.org/datetime/jd:%.1f>JD:%.1f</a> MJD:%d %s (%d)</p>},
      $day->{jd}, $day->{jd}, $day->{mjd},
      $day->{kanshi_label}, $day->{kanshi0};
  for my $key (qw(gregorian julian kyuureki
                  nongli_tiger nongli_ox nongli_rat nongli_qin nongli_wuzhou
                  year)) {
    if (defined $day->{$key}) {
      printf qq{<p>%s: %s</p>\n},
          $key, $day->{$key};
    }
  }
  print q{</dt-item>};
} # print_day

sub print_eras ($) {
  my $era_ids = shift || {};
  for my $era_id (sort { $a <=> $b } keys %$era_ids) {
    my $era = $Eras->{$era_id}
        or die "Era |$era_id| not found";
    printf qq{<p><a href=https://data.suikawiki.org/e/%d/>y~%d</a> (%s)\n},
        $era->{id}, $era->{id}, $era->{key};
  }
} # print_eras

sub print_tags ($) {
  my $tag_ids = shift || {};
  for my $tag_id (sort { $a <=> $b } keys %$tag_ids) {
    my $tag = $Tags->{$tag_id}
        or die "Tag |$tag_id| not found";
    printf qq{<p><a href=https://data.suikawiki.org/tag/%d/>#%s</a>\n},
        $tag->{id}, $tag->{label};
  }
} # print_tags

print q{<!DOCTYPE HTML>
<meta charset=utf-8>
<title>Era transition events</title>
<style>
  table {
    border-collapse: collapse;
    border: 1px solid gray;
    font-size: 80%;
  }

  th, td {
    padding: .3em;
  }

  th {
    background: black;
    color: white;
    border: 1px solid white;
  }

  td {
    border: 1px solid gray;
  }

  thead th {
    position: sticky;
    top: 0;
  }

  p {
    margin: 0;
  }

  dt-range {
    display: block;
  }

  dt-item {
    display: block;
  }

  dt-item + dt-item::before {
    content: ":";
    display: block;
    text-align: center;
  }
</style>

<h1>Era transition events</h1>

<p class=info>This document is generated from <a
href=../data/calendar/era-defs.json><code>data/calendar/era-defs.json</code></a>
and <a
href=../data/calendar/era-transitions.json><code>data/calendar/era-transitions.json</code></a>.
};

print q{<table>
<thead>
<tr>
  <th>Eras
  <th>Time
  <th>Transition type
  <th>From
  <th>To
  <th>Action
  <th>Tags
<tbody>};
for my $tr (@$Transitions) {
  print qq{\n<tr>};
  print q{<td>};
  print_eras $tr->{relevant_era_ids};
  print q{<td>};
  if (defined $tr->{day}) {
    print_day $tr->{day};
  } else {
    print q{<dt-range>};
    print_day $tr->{day_start};
    print_day $tr->{day_end};
    print q{</dt-range>};
  }
  printf q{<td>%s},
      $tr->{type};
  print q{<td>};
  print_eras $tr->{prev_era_ids};
  print q{<td>};
  print_eras $tr->{next_era_ids};
  print q{<td>};
  if (defined $tr->{action_tag_id}) {
    print q{<p>Action: };
    print_tags {$tr->{action_tag_id} => 1};
  }
  if (defined $tr->{event_tag_id}) {
    print q{<p>Event: };
    print_tags {$tr->{event_tag_id} => 1};
  }
  if (defined $tr->{authority_tag_id}) {
    print q{<p>Authority: };
    print_tags {$tr->{authority_tag_id} => 1};
  }
  if (defined $tr->{position_tag_id}) {
    print q{<p>Position: };
    print_tags {$tr->{position_tag_id} => 1};
  }
  if (keys %{$tr->{subject_tag_ids} or {}}) {
    print q{<p>Subject: };
    print_tags $tr->{subject_tag_ids};
  }
  if (keys %{$tr->{object_tag_ids} or {}}) {
    print q{<p>Object: };
    print_tags $tr->{object_tag_ids};
  }
  print q{<td>};
  print_tags $tr->{tag_ids};
}

print q{
</table>

<sw-ads normal></sw-ads>
<script src="https://manakai.github.io/js/global.js" async></script>
};

## License: Public Domain.
