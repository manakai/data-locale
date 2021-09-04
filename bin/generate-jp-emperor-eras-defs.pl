use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $Data = {};

my $src_path = $root_path->child ('src/jp-emperor-eras.txt');
for (split /\x0D?\x0A/, $src_path->slurp_utf8) {
  if (/^(BC|)(\d+)\s+(\w+)\s+([\w|]+)\s+([\w-]+)$/) {
    my $data = $Data->{eras}->{$3} ||= {};
    $data->{key} = $3;
    $data->{name} = $3;
    $data->{name_ja} = $3;
    $data->{name_kana} = $4;
    $data->{name_kanas}->{$4} = 1;
    $data->{name_latn} = $5;
    $data->{offset} = ($1 ? -$2 + 1 : $2) - 1;
    $data->{jp_emperor_era} = 1
        unless $3 eq '弘文天皇' or $3 eq '孝徳天皇';
    $data->{wref_ja} = $3;
    $data->{wref_en} = "Emperor_$5";
    $data->{name_kana} =~ s/\|/ /g;
    $data->{wref_ja} =~ s/摂政$//;
    $data->{wref_en} =~ s/-tenn.$//;
    $data->{wref_en} = 'Empress_Jingū'
        if $data->{name} eq '神功皇后摂政';
  } elsif (/\S/) {
    die "Bad line |$_|";
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
