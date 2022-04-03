use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Langs = [qw(cn hk mo my sg tw)];

my $Key = shift;

my $Inputs = {};
for my $lang (@$Langs) {
  my $path = $RootPath->child ("local/wikimedia/wp-$Key-$lang.json");
  $Inputs->{$lang} = json_bytes2perl $path->slurp;
}

my $Data = $Inputs->{tw};
$Data->{file_key} = $Key;
$Data->{page_name} = $Inputs->{tw}->{page_name};
$Data->{wref_key} = 'wref_zh';

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
  }
} # $data

for my $era (@{$Data->{eras}}) {
  for (
    ['cn', 'my'],
    ['cn', 'sg'],
    ['tw', 'hk'],
    ['tw', 'mo'],
  ) {
    my ($l1, $l2) = @$_;
    push @{$Data->{_errors} ||= []}, "$l1 != $l2: $era->{$l1} $era->{$l2}"
        if $era->{$l1} ne $era->{$l2};
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
