use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {transitions => []};

{
  #my $path = $RootPath->child ('local/calendar-era-defs-0.json');
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;

  $Data->{transitions} = $json->{_TRANSITIONS};

=pod
  
  for my $era (sort {
    $a->{id} <=> $b->{id};
  } values %{$json->{eras}}) {
    for my $tr (@{$era->{transitions} or []}) {
      $tr->{relevant_era_ids}->{$era->{id}} = 1;
      if ($tr->{direction} eq 'incoming') {
        $tr->{next_era_ids}->{$era->{id}} = 1;
        delete $tr->{direction};
      } elsif ($tr->{direction} eq 'outgoing') {
        $tr->{prev_era_ids}->{$era->{id}} = 1;
        delete $tr->{direction};
      } elsif ($tr->{direction} eq 'other') {
        delete $tr->{direction};
      } else {
        die "Bad direction |$tr->{direction}|";
      }
      push @{$Data->{transitions}}, $tr;
    }
  }

=cut

}

=pod

$Data->{transitions} = [map { $_->[0] } sort {
  $a->[1] <=> $b->[1] ||
  $a->[2] <=> $b->[2] ||
  $a->[3] cmp $b->[3] ||
  $a->[0]->{type} cmp $b->[0]->{type};
} map {
  [$_,
   ($_->{day} || $_->{day_start})->{mjd},
   ($_->{day} || $_->{day_end})->{mjd},
   (join $;, sort { $a <=> $b } keys %{$_->{relevant_era_ids}})];
} @{$Data->{transitions}}];

=cut

print perl2json_bytes_for_record $Data;

## License: Public Domain.
