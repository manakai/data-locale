use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;

my $Data;
{
  my $path = $RootPath->child ('local/calendar-era-relations-0.json');
  $Data = json_bytes2perl $path->slurp;
}

my $Eras;
my $EraById = {};
{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  $Eras = [sort { $a->{id} <=> $b->{id} } values %{$json->{eras}}];
  for my $era (@$Eras) {
    $EraById->{$era->{id}} = $era;
  }
}

{
  my $offset_eras = {};
  my $year_era_ids = {};
  my $ThisYear = [gmtime]->[5]+1900;
  for my $era (values %$EraById) {
    if (defined $era->{offset}) {
      push @{$offset_eras->{$era->{offset}} ||= []}, $era;
    }
    if (defined $era->{start_year}) {
      my $end = $era->{end_year} // ($ThisYear + 10);
      for my $y ($era->{start_year} .. $end) {
        push @{$year_era_ids->{$y} ||= []}, $era->{id};
      }
    }
  } # $era
  for my $offset (sort { $a <=> $b } keys %$offset_eras) {
    my @era = @{$offset_eras->{$offset}};
    for my $era1 (@era) {
      for my $era2 (@era) {
        next if $era1->{id} == $era2->{id};
        $Data->{eras}->{$era1->{id}}->{relateds}->{$era2->{id}}->{year_equal} = 1;
        $Data->{eras}->{$era2->{id}}->{relateds}->{$era1->{id}}->{year_equal} = 1;
      }
    }
  } # $offset
  for my $era (values %$EraById) {
    if (defined $era->{start_year}) {
      my $end = $era->{end_year} // ($ThisYear + 10);
      for my $y ($era->{start_year} .. $end) {
        for my $id2 (@{$year_era_ids->{$y} || []}) {
          next if $era->{id} == $id2;
          $Data->{eras}->{$era->{id}}->{relateds}->{$id2}->{year_range_overlap} = 1;
        }
      }
    }
  } # $era
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
