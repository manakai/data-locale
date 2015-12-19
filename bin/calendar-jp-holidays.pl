use strict;
use warnings;
use JSON::PS;
use Path::Tiny;

my $Data;
my $RootPath = path (__FILE__)->parent->parent;

{
  my $path = $RootPath->child ('local/calendar-new-jp-holidays.json');
  $Data = json_bytes2perl $path->slurp;
}

{
  my $path = $RootPath->child ('local/calendar-old-jp-holidays.json');
  my $json = json_bytes2perl $path->slurp;
  my $map_path = $RootPath->child ('data/calendar/kyuureki-map.txt');
  my $map = {};
  for (split /\n/, $map_path->slurp) {
    if (/^(\S+)\s+(\S+)/) {
      $map->{$2} = $1;
    }
  }
  for (keys %$json) {
    my $day = $map->{$_};
    die "Kyuureki |$_| not found" unless defined $day;
    $Data->{$day} = $json->{$_};
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
