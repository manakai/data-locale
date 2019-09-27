use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

my $EraDefs;
{
  my $json_path = $RootPath->child ('data/calendar/era-defs.json');
  $EraDefs = json_bytes2perl $json_path->slurp;
}

my $EraSystems;
{
  my $json_path = $RootPath->child ('data/calendar/era-systems.json');
  $EraSystems = json_bytes2perl $json_path->slurp;
}

sub dclone ($) {
  return json_chars2perl perl2json_chars $_[0];
} # dclone

{
  my $jp = $EraSystems->{systems}->{jp} or die;
  my $jpn = $EraSystems->{systems}->{'jp-north'} or die;
  my $def = $Data->{dts}->{dtsjp1} = {};
  my $patterns = [];
  $def->{patterns} = [];
  {
    use utf8;
    my $era_def = $EraDefs->{eras}->{AD} or die 'AD';
    push @{$def->{patterns}}, [undef, [['グレゴリオ暦'.$era_def->{name_ja}, 0]]];
  }
  {
    use utf8;
    push @{$def->{patterns}}, [1477837.5, [['グレゴリオ暦神武天皇即位前', 'k']]]; # k:-0666-01-01
  }
  my $g_done = 0;
  for my $pt (@{$jp->{points}}) {
    die $pt->[0] unless $pt->[0] eq 'jd';
    if (not $g_done and $pt->[1] >= 2405159.5) { # M6.1.1
      push @$patterns, [2405159.5, dclone $patterns->[-1]->[1]];
      for (0..($#$patterns-1)) {
        use utf8;
        unshift @{$patterns->[$_]->[1]}, 'グレゴリオ暦';
      }
      $g_done = 1;
    }
    my $era_def = $EraDefs->{eras}->{$pt->[2]} or die $pt->[2];
    push @$patterns, [$pt->[1], [[$era_def->{name_ja} || die, $era_def->{offset} // die $pt->[2]]]];
  }
  my $north;
  my $south;
  for my $pt (@{$jpn->{points}}) {
    die $pt->[0] unless $pt->[0] eq 'jd';
    while (@$patterns and $patterns->[0]->[0] < $pt->[1]) {
      $south = $patterns->[0]->[1]->[-1];
      if ('/'.$south->[0] eq $north->[0] and
          $south->[1] == $north->[1]) {
        push @{$def->{patterns}}, shift @$patterns;
      } else {
        use utf8;
        push @{$def->{patterns}}, [$patterns->[0]->[0], ['グレゴリオ暦', $south, $north]];
        shift @$patterns;
      }
    }
    if (@$patterns and $patterns->[0]->[0] == $pt->[1]) {
      $south = $patterns->[0]->[1]->[-1];
      $north = dclone $south;
      $north->[0] = '/' . $north->[0];
      push @{$def->{patterns}}, shift @$patterns;
      next;
    }
    if (@$patterns and $pt->[1] < $patterns->[0]->[0]) {
      my $era_def = $EraDefs->{eras}->{$pt->[2]} or die $pt->[2]; 
      $north = ['/' . ($era_def->{name_ja} || die), $era_def->{offset} // die $pt->[2]];
      $south = $def->{patterns}->[-1]->[1]->[1];
      use utf8;
      if ('/'.$south->[0] eq $north->[0] and
          $south->[1] == $north->[1]) {
        push @{$def->{patterns}}, [$pt->[1], ['グレゴリオ暦', $south]];
      } else {
        push @{$def->{patterns}}, [$pt->[1], ['グレゴリオ暦', $south, $north]];
      }
    }
  }
  push @{$def->{patterns}}, @$patterns;
  for (1..$#{$def->{patterns}}) {
    push @{$def->{patterns}->[$_]->[1]}, ['(', 0], ')';
  }
  for (@{$def->{patterns}}) {
    my $x = [''];
    for (@{$_->[1]}) {
      if (ref $_ eq 'ARRAY') {
        if (ref $x->[-1]) {
          push @$x, $_->[0];
        } else {
          $x->[-1] .= $_->[0];
        }
        if ($_->[1] eq 'k') {
          push @$x, ['k'];
        } else {
          push @$x, ['y', $_->[1]];
        }
      } else {
        if (ref $x->[-1]) {
          push @$x, $_;
        } else {
          $x->[-1] .= $_;
        }
      }
    }
    $_->[1] = $x;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
