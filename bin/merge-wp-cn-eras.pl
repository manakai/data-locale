use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Langs = [qw(cn hk mo my sg tw)];

my $Inputs = {};
for my $lang (@$Langs) {
  my $path = $RootPath->child ("local/wp-cn-eras-$lang.json");
  $Inputs->{$lang} = json_bytes2perl $path->slurp;
}

my $IDMap = {};
{
  my $path = $RootPath->child ('src/wp-zh-era-id-map.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)\s+([0-9]+)\s+(\S+)$/) {
      if (defined $IDMap->{$1}) {
        die "Duplicate ukey |$1|";
      }
      $IDMap->{$1} = [$2, $3];
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

my $Data = $Inputs->{tw};

for my $i (0..$#{$Data->{eras}}) {
  for my $lang (@$Langs) {
    my $c = $Inputs->{$lang}->{eras}->[$i];
    my $t = $Data->{eras}->[$i];
    die if defined $t->{wref} and defined $c->{wref} and not $t->{wref} eq $c->{wref};
    die if defined $t->{offset} and defined $c->{offset} and not $t->{offset} == $c->{offset};
    $t->{$lang} = $c->{name};
  }
}

my $found = {};
for my $data (@{$Data->{eras}}) {
  if (defined $data->{offset}) {
    $data->{ukey} = $data->{tw} . ',' . $data->{offset};
  } else {
    $data->{ukey} = $data->{tw};
    use utf8;
    if ($data->{ukey} eq '天定') {
      $data->{ukey} .= '[' . $data->{caption} . ']';
    }
  }
  my $dup_key = defined $data->{offset} ? 'dup_offsets' : 'dups';
  if ($found->{$data->{ukey}}) {
    push @{$Data->{$dup_key}->{$data->{ukey}} ||= [$found->{$data->{ukey}}]},
        perl2json_chars_for_record $data;
  } else {
    $found->{$data->{ukey}} = perl2json_chars_for_record $data;

    if (defined $IDMap->{$data->{ukey}}) {
      $data->{era_id} = $IDMap->{$data->{ukey}}->[0];
      $data->{era_key} = $IDMap->{$data->{ukey}}->[1];
    } else {
      push @{$Data->{_errors} ||= []},
          ["Era not found", $data->{ukey}];
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
