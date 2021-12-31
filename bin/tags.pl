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
  
  for my $path (
    $RootPath->child ('src/tags.txt'),
    $RootPath->child ('local/era-data-tags.txt'),
  ) {
    my $item;
    for (split /\x0D?\x0A/, $path->slurp_utf8) {
      if (/^\s*#/) {
        #
      } elsif (/^(region|country|people|religion|org|person|law|action|calendar|position|event|source|tag)$/) {
        $add_item->($item) if defined $item;
        $item = {type => $1};
      } elsif (defined $item and /^  (name|key)\s+(\S.*\S|\S)\s*$/) {
        $item->{$1} //= $2;
      } elsif (defined $item and /^  (name|label)_(ja|en|tw|cn)\s+(\S.*\S|\S)\s*$/) {
        $item->{$1} //= $3;
        $item->{$1.'_'.$2} //= $3;
        $item->{$1.'s'}->{$3} = 1;
      } elsif (defined $item and /^  (group|period|region)\s*of\s*(\S.*\S|\S)\s*$/) {
        $item->{'_'.$1.'_of'}->{$2} = 1;
      } elsif (defined $item and /^  name\([a-z]+\)/) {
        #XXX
      } elsif (/\S/) {
        die "$path: Bad line |$_|";
      }
    }
    $add_item->($item) if defined $item;
  } # $path
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
} # $x
{
  my $changed = 0;
  for my $x (qw(period group region)) {
    for my $y ($x, 'group', 'period', 'region') {
      for my $item1 (values %{$Data->{tags}}) {
        for (keys %{$item1->{$y.'s'} or {}}) {
          my $l1 = $item1->{$y.'s'}->{$_};
          my $item2 = $Data->{tags}->{$_};
          for (keys %{$item2->{$x.'s'} or {}}) {
            my $l2 = $item2->{$x.'s'}->{$_};
            my $item3 = $Data->{tags}->{$_};
            ## 1 child 2 and 2 child 3 -> 1 child 3 and 3 parent 1
            if (not $item1->{$x.'s'}->{$item3->{id}}) {
              $item3->{$x.'_of'}->{$item1->{id}} =
              $item1->{$x.'s'}->{$item3->{id}} =
                  $l1 + $item2->{$x.'s'}->{$item3->{id}};
              $changed = 1;
            } elsif ($item1->{$x.'s'}->{$item3->{id}}
                         > $l1 + $item2->{$x.'s'}->{$item3->{id}}) {
              $item3->{$x.'_of'}->{$item1->{id}} =
              $item1->{$x.'s'}->{$item3->{id}} =
              $l1 + $item2->{$x.'s'}->{$item3->{id}};
              $changed = 1;
            }
          }
        }
      }
    } # $y
  } # $x
  last unless $changed;
  redo;
} # $changed

IDs::save_id_set 'tags';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
