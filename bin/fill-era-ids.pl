use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $InputName = shift;
my $InputFile = path ($InputName);

my $Data = json_bytes2perl $InputFile->slurp;

my $RootPath = path (__FILE__)->parent->parent;

my $OldData = {};
my $OldById = {};
{
  my $path = $RootPath->child ('local/old-ced.json');
  my $json = json_bytes2perl $path->slurp;
  for my $era (sort { $a->{id} <=> $b->{id} } values %{$json->{eras}}) {
    $OldById->{$era->{id}} = $era;
    if ($era->{tag_ids}->{1813}) { # 元号名不詳
      use utf8;
      $era->{names}->{'？？'} = 1;
    }
    for (sort { $a cmp $b } keys %{$era->{names}}) {
      push @{$OldData->{$_, $era->{offset} // ''} ||= []}, $era;
      push @{$OldData->{$_, ''} ||= []}, $era;
    }
  }
}

my $Mapped = {};
{
  my $path = $RootPath->child ('intermediate/wikimedia/era-id-map.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)\s+([^\s,]+),(-?[0-9]+|-)\s+y~([0-9]+)\s*$/) {
      my ($cc, $n, $o, $y) = ($1, $2, $3, $4);
      $cc =~ s/_/ /g;
      for my $c (split /\|/, $cc) {
        $Mapped->{$c, $n, $o} = 0+$y;
      }
    } elsif (/^(\S+)\s+(\S+)\s+y~([0-9]+)\s*$/) {
      my ($cc, $n, $y) = ($1, $2, $3);
      $cc =~ s/_/ /g;
      for my $c (split /\|/, $cc) {
        $Mapped->{$c, $n} = 0+$y;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

my $Langs = [qw(cn hk mo my sg tw ja)];
ERA: for my $era (@{$Data->{eras}}) {
  {
    my $mapped = $Mapped->{$era->{caption}, $era->{name}, $era->{offset} // '-'};
    if (defined $mapped) {
      my $data = $OldById->{$mapped} or die "Bad era ID |$mapped|";
      $era->{era_id} = $data->{id};
      $era->{era_key} = $data->{key};
      next ERA;
    }
  }
  
  my @d1;
  my @d2;
  for my $lang (@$Langs) {
    next unless defined $era->{$lang};
    push @d1, @{$OldData->{$era->{$lang}, $era->{offset}} or []}
        if defined $era->{offset};
    push @d2, @{$OldData->{$era->{$lang}, ''} or []};
  }
  my $found = {};
  @d2 = grep { not $found->{$_->{id}}++ } @d2;
  my $errors = [];
  if (@d1) {
    $era->{era_id} = $d1[0]->{id};
    $era->{era_key} = $d1[0]->{key};
  } elsif (@d2 == 1 and not defined $era->{offset}) {
    $era->{era_id} = $d2[0]->{id};
    $era->{era_key} = $d2[0]->{key};
  } elsif (@d2) {
    $era->{_possibles} = [map {
      [$_->{id}, $_->{key}, $_->{offset}];
    } @d2];
  } elsif ($era->{dup}) {
    #
  } else {
    push @$errors, ["Era not found", $era->{ukey}];
  }

  {
    my $mapped = $Mapped->{$era->{caption}, $era->{name}};
    if (defined $mapped) {
      my $data = $OldById->{$mapped} or die "Bad era ID |$mapped|";
      $era->{era_id} = $data->{id};
      $era->{era_key} = $data->{key};
      next ERA;
    }
  }

  push @{$Data->{_errors} ||= []}, @$errors;

  if (not $era->{dup} and $era->{_possibles}) {
    if ($era->{might_dup}) {
      $era->{dup} = 1;
    } else {
      $era->{caption} =~ s/ /_/g;
      push @{$Data->{_errors} ||= []},
          ["Era mapping is missing", $era->{ukey}, $era->{caption}];
    }
  }
} # ERA

print perl2json_bytes_for_record $Data;

## License: Public Domain.
