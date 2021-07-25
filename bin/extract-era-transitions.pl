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
my $TagsExcluded = [map { get_tag_id decode_web_utf8 $_ } split /,/, $ENV{TAGS_EXCLUDED} // ''];

my $StartEraKey = decode_web_utf8 shift or die;

my $EraData;
my $EraById;
{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  $EraData = json_bytes2perl $path->slurp;
  for my $item (values %{$EraData->{eras}}) {
    $EraById->{$item->{id}} = $item;
  }
}

sub get_transition ($$$) {
  my ($era, $mjd, $direction) = @_;

  my $fys;
  my $fd;
  my $matched1 = [];
  my $matched2 = [];

  for my $tr (@{$era->{transitions}}) {
    if (defined $tr->{day}) {
      next if $tr->{day}->{mjd} <= $mjd;
    } elsif (defined $tr->{day_start}) {
      next if $tr->{day_end}->{mjd} <= $mjd;
    } else {
      die "Bad transition";
    }
    
    if ($tr->{direction} eq $direction) {
      if ($tr->{type} eq 'firstyearstart') {
        if ((!!grep { $_ } map { $tr->{tag_ids}->{$_} } @$TagsIncluded) or
            (!grep { $_ } map { $tr->{tag_ids}->{$_} } @$TagsExcluded)) {
          $fys //= $tr;
        }
      }
      if ($tr->{type} eq 'firstday') {
        if ((!!grep { $_ } map { $tr->{tag_ids}->{$_} } @$TagsIncluded) or
            (!grep { $_ } map { $tr->{tag_ids}->{$_} } @$TagsExcluded)) {
          $fd //= $tr;
        }
      }

      if ($tr->{type} eq 'commenced') {
        if (!!grep { $_ } map { $tr->{tag_ids}->{$_} } @$TagsIncluded) {
          push @$matched1, $tr;
        }
      }
      if ($tr->{type} eq 'wartime' or
          $tr->{type} eq 'received') {
        if (!!grep { $_ } map { $tr->{tag_ids}->{$_} } @$TagsIncluded) {
          push @$matched2, $tr;
        }
      }
    }
  }

  return $matched1->[0] if @$matched1;
  return $matched2->[0] if @$matched2;
  return $fd if defined $fd;
  return $fys if defined $fys;
  return undef;
} # get_transition

my $items = [];


my $start_era = $EraData->{eras}->{$StartEraKey}
    or die "Era |$StartEraKey| not found";
my $tr = get_transition ($start_era, 0-"Inf", 'incoming');
die "Start era |$StartEraKey|'s incoming transition" unless defined $tr;
push @$items, my $last_item = {
  era => $start_era,
  transition => $tr,
  day => $tr->{day} // $tr->{day_end},
  delta => 0,
};

while (1) {
  my $tr = get_transition ($last_item->{era}, $last_item->{day}->{mjd}, 'outgoing');
  last unless defined $tr;
  my $next_era_ids = [keys %{$tr->{next_era_ids}}];
  die "Multiple nexts" if @$next_era_ids != 1;
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
}

binmode STDOUT, qw(:encoding(utf-8));
for my $item (@$items) {
  printf "# k:%s g:%s%s\njd:%s %s\n",
      $item->{day}->{kyuureki},
      $item->{day}->{gregorian},
      $item->{delta} ? ' +' . $item->{delta} : '',
      $item->{day}->{jd} + $item->{delta},
      $item->{era}->{key};
}
if (0) {
binmode STDERR, qw(:encoding(utf-8));
for my $item (@$items) {
  warn sprintf "g:%s+%d y~%d (%s) %s\n",
      $item->{day}->{gregorian},
      $item->{delta},
      $item->{era}->{id},
      $item->{era}->{key},
      $item->{transition}->{type};
}
}

__END__

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
