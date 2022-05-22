use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::Encoding;

my $RootPath = path (__FILE__)->parent->parent;

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

my $TagsIncluded = [map { get_tag_id decode_web_utf8 $_ } split /,/, $ENV{TAGS_INCLUDED} // ''];
my $TagsIncluded2 = [map { get_tag_id decode_web_utf8 $_ } split /,/, $ENV{TAGS_INCLUDED2} // ''];
my $TagsExcluded = [map { get_tag_id decode_web_utf8 $_ } split /,/, $ENV{TAGS_EXCLUDED} // ''];

my $StartEraKey = decode_web_utf8 shift or die;

my $EraData;
my $EraById;
my $Transitions;
{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  $EraData = json_bytes2perl $path->slurp;
  for my $item (values %{$EraData->{eras}}) {
    $EraById->{$item->{id}} = $item;
  }
}
{
  my $path = $RootPath->child ('data/calendar/era-transitions.json');
  my $json = json_bytes2perl $path->slurp;
  $Transitions = $json->{transitions};
}

sub has_tag ($$) {
  my ($tr, $tags) = @_;
  return !!grep { $_ } map { $tr->{tag_ids}->{$_} } @$tags;
} # has_tag

sub get_transition ($$$) {
  my ($era, $mjd, $direction) = @_;

  my $fys;
  my $fd;
  my $matched1 = [];
  my $matched2 = [];
  my $matched3 = [];
  my $matched4 = [];
  my $matched_others = [];
  my $matched_others2 = [];
  my $matched_others3 = [];

  for my $tr (grep { $_->{relevant_era_ids}->{$era->{id}} } @$Transitions) {
    if (defined $tr->{day}) {
      next if $tr->{day}->{mjd} < $mjd;
    } elsif (defined $tr->{day_start}) {
      next if $tr->{day_end}->{mjd} < $mjd;
    } else {
      die "Bad transition";
    }

    if (do {
      ($direction eq 'incoming' and $tr->{next_era_ids}->{$era->{id}})
          or
      ($direction eq 'outgoing' and $tr->{prev_era_ids}->{$era->{id}})
    }) {
      my $fd_matched = 0;
      if (($tr->{type} eq 'firstday' || $tr->{type} eq 'renamed') &&
          (!$tr->{tag_ids}->{2107} or # 分離
           $direction eq 'incoming')) {
        $fd_matched = 1;
        if (has_tag $tr, $TagsIncluded and not has_tag $tr, $TagsExcluded) {
          push @$matched2, $tr;
        }
        if (not has_tag $tr, $TagsExcluded) {
          $fd //= $tr;
        }
      }

      if ($tr->{type} eq 'commenced' or $tr->{type} eq 'administrative'){
        if ($tr->{tag_ids}->{2107}) { # 分離
          if (has_tag $tr, $TagsIncluded and not has_tag $tr, $TagsExcluded) {
            push @$matched1, $tr;
          } else {
            if ($direction eq 'incoming' or defined $era->{end_year}) {
              push @$matched_others, $tr;
            }
          }
        } else {
          if (has_tag $tr, $TagsIncluded and not has_tag $tr, $TagsExcluded) {
            push @$matched1, $tr;
          } else {
            push @$matched_others, $tr;
          }
        }
      }
      
      if (($tr->{type} eq 'wartime' or
           $tr->{type} eq 'received' or
           $tr->{type} eq 'firstday' or
           $tr->{type} eq 'renamed') and
          not $fd_matched) {
        if (has_tag $tr, $TagsIncluded and not has_tag $tr, $TagsExcluded) {
          push @$matched2, $tr;
        } else {
          if (!$tr->{tag_ids}->{2107} or # 分離
              $direction eq 'incoming' or
              defined $era->{end_year}) {
            push @$matched_others, $tr;
          }
        }
      }
      if ($tr->{type} eq 'wartime/possible' or
          $tr->{type} eq 'received/possible' or
          $tr->{type} eq 'firstday/possible' or
          $tr->{type} eq 'renamed/possible') {
        if (has_tag $tr, $TagsIncluded and not has_tag $tr, $TagsExcluded) {
          push @$matched3, $tr;
        } else {
          if (!$tr->{tag_ids}->{2107} or # 分離
              $direction eq 'incoming' or
              defined $era->{end_year}) {
            push @$matched_others2, $tr;
          }
        }
      }
      if ($tr->{type} eq 'wartime/incorrect' or
          $tr->{type} eq 'administrative/incorrect' or
          $tr->{type} eq 'received/incorrect' or
          $tr->{type} eq 'firstday/incorrect' or
          $tr->{type} eq 'renamed/incorrect') {
        if (has_tag $tr, $TagsIncluded2 and not has_tag $tr, $TagsExcluded) {
          push @$matched4, $tr;
        } else {
          if (!$tr->{tag_ids}->{2107} or # 分離
              $direction eq 'incoming' or
              defined $era->{end_year}) {
            push @$matched_others3, $tr;
          }
        }
      }
      
      if ($tr->{type} eq 'firstyearstart' and
          $tr->{tag_ids}->{2108}) { # 即位元年年始
        $fys //= $tr;
      }
    } # direction matched

    if (@$matched1 or @$matched2 or @$matched3 or @$matched4) {
      if (do {
        ($direction eq 'outgoing' and $tr->{next_era_ids}->{$era->{id}})
            or
        ($direction eq 'incoming' and $tr->{prev_era_ids}->{$era->{id}})
      }) {
        last;
      }
    }
  } # $tr

  return $matched1->[0] if @$matched1;
  return $matched2->[0] if @$matched2;
  return $matched3->[0] if @$matched3;
  return $matched4->[0] if @$matched4;
  return $fd if defined $fd;
  return $matched_others->[-1] if @$matched_others;
  return $matched_others2->[-1] if @$matched_others2;
  return $matched_others3->[-1] if @$matched_others3;
  return $fys if defined $fys;
  return undef;
} # get_transition

my $items = [];
my $has_error = 0;


my $start_era = $EraData->{eras}->{$StartEraKey}
    or die "Era |$StartEraKey| not found";
my $tr = get_transition ($start_era, 0-"Inf", 'incoming');
die "No start era |$StartEraKey|'s incoming transition" unless defined $tr;
push @$items, my $last_item = {
  era => $start_era,
  transition => $tr,
  day => $tr->{day} // $tr->{day_end},
  delta => 0,
};

my $seen = {};
while (1) {
  my $tr = get_transition ($last_item->{era}, $last_item->{day}->{mjd}, 'outgoing');
  last unless defined $tr;
  if ($seen->{$tr}++) {
    printf STDOUT "# Transition loop found!\n";
    last;
  }
  my $next_era_ids = [sort { $a <=> $b } keys %{$tr->{next_era_ids}}];
  #die "Multiple nexts" if @$next_era_ids != 1;
  if (@$next_era_ids != 1) {
    printf STDOUT "# y~%d has multiple nexts: %s\n",
        $last_item->{era}->{id},
        join ',', @$next_era_ids;
    last unless @$next_era_ids;
  }
  my $delta = 0;
  if ($tr->{type} eq 'wartime' and
      $tr->{tag_ids}->{1226}) { # 陥落
    $delta = 1;
  }
  push @$items, $last_item = {
    era => $EraById->{$next_era_ids->[0]},
    transition => $tr,
    day => $tr->{day} // $tr->{day_end},
    delta => $delta,
  };
  if (@$items > 1000) {
    printf "Too many items!\n";
    $has_error = 1;
    last;
  }
}

binmode STDOUT, qw(:encoding(utf-8));
for my $item (@$items) {
  printf "# g:%s+%d y~%d %s\nmjd:%s %s\n",
      $item->{day}->{gregorian},
      $item->{delta},
      $item->{era}->{id},
      $item->{transition}->{type},
      $item->{day}->{mjd} + $item->{delta},
      $item->{era}->{key};
}

exit 1 if $has_error;

## License: Public Domain.
