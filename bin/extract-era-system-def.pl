use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::Encoding;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = [];

my $Tags;
my $TagByKey = {};
{
  my $path = $RootPath->child ('data/tags.json');
  $Tags = (json_bytes2perl $path->slurp)->{tags};
  for my $item (values %$Tags) {
    $TagByKey->{$item->{key}} = $item;
  }

  sub get_tag_id ($) {
    my $tag = $TagByKey->{$_[0]} or die "Unknown tag key |$_[0]|";
    return $tag->{id};
  } # get_tag_id
}

my $EraTags = [map { get_tag_id decode_web_utf8 $_ } split /,/, $ENV{ERA_TAGS} // ''];
my $TransitionTags = [map { get_tag_id decode_web_utf8 $_ } split /,/, $ENV{TRANSITION_TAGS} // ''];
my $EraIncluded = {map { $_ => 1 } split /,/, decode_web_utf8 ($ENV{ERA_INCLUDED} // '')};
my $EraExcluded = {map { $_ => 1 } split /,/, decode_web_utf8 ($ENV{ERA_EXCLUDED} // '')};

{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;

   ERA: for my $era (values %{$json->{eras}}) {
    {
      last if $EraIncluded->{$era->{key}};
      next ERA if $EraExcluded->{$era->{key}};
      next ERA unless !!grep { $_ } map { $era->{tag_ids}->{$_} } @$EraTags;
    }

    my $matched1 = [];
    my $matched2 = [];
    my $fday;
    my $fystart;
    for my $tr (@{$era->{transitions}}) {
      if ($tr->{direction} eq 'incoming') {
        if ($tr->{type} eq 'commenced') {
          if (!!grep { $_ } map { $tr->{tag_ids}->{$_} } @$TransitionTags) {
            push @$matched1, $tr;
          }
        }
        if ($tr->{type} eq 'wartime' or
            $tr->{type} eq 'received') {
          if (!!grep { $_ } map { $tr->{tag_ids}->{$_} } @$TransitionTags) {
            push @$matched2, $tr;
          }
        }
        $fday = $tr if $tr->{type} eq 'firstday';
        $fystart = $tr if $tr->{type} eq 'firstyearstart';
      }
    }

    my @tr = @$matched1 ? @$matched1 : @$matched2 ? @$matched2 : $fday || $fystart || ();
    die "Empty transition" unless @tr;
    for my $tr (@tr) {
      my $day = $tr->{day} // $tr->{day_end};
      my $line;
      if ($tr->{tag_ids}->{1226}) { # 陥落
        $line = sprintf "# k:%s+1 g:%s+1\njd:%s %s\n",
            $day->{kyuureki},
            $day->{gregorian},
            $day->{jd}+1,
            $era->{key};
      } else {
        $line = sprintf "# k:%s g:%s\njd:%s %s\n",
            $day->{kyuureki},
            $day->{gregorian},
            $day->{jd},
            $era->{key};
      }
      push @$Data, [$day->{jd}, $line];
    } # $tr
  } # ERA
}

binmode STDOUT, qw(:encoding(utf-8));
my $name = $ENV{ERA_SYSTEM_NAME};
print '*'.$name.":\n";
print '+$DEF-'.$name."\n";
print '$DEF-'.$name.":\n";
my $found = {};
print join '', #grep { not $found->{$_}++ }
    map { $_->[1] } sort { $a->[0] <=> $b->[0] } @$Data;

## License: Public Domain.
