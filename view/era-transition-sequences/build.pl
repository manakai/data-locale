use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('bin/modules/*/lib');
use JSON::PS;
use Web::Encoding;

my $ThisPath = path (__FILE__)->parent;
my $RootPath = $ThisPath->parent->parent;

my $EraByKey;
{
  my $path = $RootPath->child ('data/calendar/era-defs.json');
  my $json = json_bytes2perl $path->slurp;
  $EraByKey = $json->{eras};
}
my $TagByKey = {};
{
  my $path = $RootPath->child ('data/tags.json');
  my $json = json_bytes2perl $path->slurp;
  for (values %{$json->{tags}}) {
    $TagByKey->{$_->{key}} = $_;
  }
}

for (do {
  use utf8;
  (
    ['神武天皇', ['日本南朝'], []], # jp-south
    ['神武天皇', ['日本北朝'], ['日本南朝']], # jp-north
    ['神武天皇', ['平氏', '日本南朝'], []], # jp-heishi
    ['神武天皇', ['京都'], ['日本南朝']], # jp-kyoto
    ['神武天皇', ['関東'], ['日本南朝']], # jp-east
  );
}) {
  use utf8;
  my $era = $EraByKey->{$_->[0]} // die "Bad era key |$_->[0]|";
  my $ti = [map { $TagByKey->{$_} // die "Bad tag key |$_->[1]|" } @{$_->[1]}];
  my $tx = [map { $TagByKey->{$_} // die "Bad tag key |$_->[1]|" } @{$_->[2]}];
  
  local $ENV{TAGS_INCLUDED} = join ',', map { encode_web_utf8 $_->{key} } @$ti;
  local $ENV{TAGS_EXCLUDED} = join ',', map { encode_web_utf8 $_->{key} } @$tx;

  my $out_name = $era->{id};
  $out_name .= '_' . $_->{id} for @$ti;
  $out_name .= '-' . $_->{id} for @$tx;
  my $out_path = $ThisPath->child ("era-ts-$out_name.txt");
  
  my $start = encode_web_utf8 $era->{key};
  my $perl_path = $RootPath->child ('perl');
  my $pl_path = $RootPath->child ('bin/extract-era-transitions.pl');
  (system "\Q$perl_path\E \Q$pl_path\E \Q$start\E > \Q$out_path\E") == 0
      or die $?;
}


## License: Public Domain.
