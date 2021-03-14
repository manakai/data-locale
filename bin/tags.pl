use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use IDs;

my $RootPath = path (__FILE__)->parent->parent;
$IDs::RootDirPath = $RootPath;
my $Data = {};
my $TagByKey = {};

{
  my $add_item = sub {
    my $item = shift;
    my $key = $item->{key} //= $item->{label} // $item->{name};
    die "No name" unless defined $key;
    my $id = IDs::get_id_by_string 'tags', $key;
    $item->{id} = $id;
    my @key = sort { $a cmp $b } keys %$item;
    for (@key) {
      if (/\Aname(_.+)\z/) {
        $item->{"label$1"} //= $item->{$_};
      }
    }
    $item->{label} //= $item->{name};
    die "Duplicate key |$key|" if defined $TagByKey->{$key};
    $Data->{tags}->{$id} = $item;
    $TagByKey->{$key} = $item;
  }; # $add_item
  
  my $path = $RootPath->child ('src/tags.txt');
  my $item;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(region|country|people|religion|org|person|law)$/) {
      $add_item->($item) if defined $item;
      $item = {type => $1};
    } elsif (defined $item and /^  (name|key)\s+(\S.*\S)\s*$/) {
      $item->{$1} //= $2;
    } elsif (defined $item and /^  (name|label)_(ja|en)\s+(\S.*\S)\s*$/) {
      $item->{$1} //= $3;
      $item->{$1.'_'.$2} //= $3;
      $item->{$1.'s'}->{$3} = 1;
    } elsif (defined $item and /^  (group|period|region)\s*of\s*(\S.*\S)\s*$/) {
      $item->{'_'.$1.'_of'}->{$2} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
  $add_item->($item) if defined $item;
}

for my $x (qw(period group region)) {
  for my $id (keys %{$Data->{tags}}) {
    my $item = $Data->{tags}->{$id};
    for (keys %{$item->{'_'.$x.'_of'} or {}}) {
      die "Tag |$_| not defined" if not defined $TagByKey->{$_};
      $TagByKey->{$_}->{$x.'s'}->{$id} = 1;
      $item->{$x.'_of'}->{$TagByKey->{$_}->{id}} = 1;
    }
    delete $item->{'_'.$x.'_of'};
  } # $id
  {
    my $changed = 0;
    for my $item (values %{$Data->{tags}}) {
      for (keys %{$item->{$x.'s'} or {}}) {
        my $item2 = $Data->{tags}->{$_};
        for (keys %{$item2->{$x.'s'} or {}}) {
          if (not $item->{$x.'s'}->{$_}) {
            $item2->{$x.'_of'}->{$item->{id}} =
            $item->{$x.'s'}->{$_} = 1 + $item2->{$x.'s'}->{$_};
            $changed = 1;
          } elsif ($item->{$x.'s'}->{$_} > 1 + $item2->{$x.'s'}->{$_}) {
            $item2->{$x.'_of'}->{$item->{id}} =
            $item->{$x.'s'}->{$_} = 1 + $item2->{$x.'s'}->{$_};
            $changed = 1;
          }
        }
      }
    }
    last unless $changed;
    redo;
  }
} # $x

IDs::save_id_set 'tags';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
