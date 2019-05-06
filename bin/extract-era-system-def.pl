use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::Encoding;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = [];

my $FilterFlags = [split /,/, $ENV{FILTER_FLAGS}];
my $FilterGroups = {map { $_ => 1 } split /,/, decode_web_utf8 ($ENV{FILTER_GROUPS} // '')};
my $FilterExcluded = {map { $_ => 1 } split /,/, decode_web_utf8 ($ENV{FILTER_EXCLUDED} // '')};
my $FilterIncluded = {map { $_ => 1 } split /,/, decode_web_utf8 ($ENV{FILTER_INCLUDED} // '')};

{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;

  my $sn = (grep { $_ eq 'jp_south_era' } @$FilterFlags) ? 'south_' :
           (grep { $_ eq 'jp_north_era' } @$FilterFlags) ? 'north_' : '';
  ERA: for my $era (values %{$json->{eras}}) {
    next if $FilterExcluded->{$era->{key}};
    
    if (keys %$FilterGroups) {
      my $found = 0;
      for (@{$era->{starts}}) {
        if ($FilterGroups->{$_->{group} // ''}) {
          my $day = $_->{day};
          $day = $day->[1] if ref $day eq 'ARRAY';
          my $line = sprintf "# k:%s g:%s\njd:%s %s\n",
              $day->{kyuureki},
              $day->{gregorian},
              $day->{jd},
              $era->{key};
          push @$Data, [$day->{jd}, $line];
          $found = 1;
        }
      }
      next ERA if $found;
    }

    my $matched = $FilterIncluded->{$era->{key}};
    for (@$FilterFlags) {
      ($matched = 1, last) if $era->{$_};
    }
    next ERA unless $matched;
    
    my $day = $era->{$sn.'start_day'} || $era->{start_day};
    if (defined $day) {
      my $line = sprintf "# k:%s g:%s\njd:%s %s\n",
          $day->{kyuureki},
          $day->{gregorian},
          $day->{jd},
          $era->{key};
      push @$Data, [$day->{jd}, $line];
    }
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
