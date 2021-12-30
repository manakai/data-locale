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

my @set = (do {
  use utf8;
  (
    ['神武天皇', ['日本南朝'], [], '日本'], # jp-south
    ['神武天皇', ['日本北朝'], ['日本南朝'], '日本'], # jp-north
    ['神武天皇', ['平氏', '日本南朝'], [], '日本'], # jp-heishi
    ['神武天皇', ['京都'], ['日本南朝'], '日本'], # jp-kyoto
    ['神武天皇', ['関東'], ['日本南朝'], '日本'], # jp-east

    ['建安', [], [], '三国時代'],
    ['建安', ['蜀漢'], [], '三国時代'],
    ['建安', ['孫呉'], [], '三国時代'],

    ['神元皇帝', [], ['中部拓跋部'], '魏晋南北朝時代'],
    ['神元皇帝', ['東魏'], ['曹弐竜', '中部拓跋部'], '魏晋南北朝時代'],

    ['乾符', ['朱梁'], ['荊南'], '五代十国'],
    ['乾符', ['後唐'], ['後晋'], '五代十国'],
    ['乾符', ['後唐', '後晋'], ['燕雲十六州'], '五代十国'],
    ['乾符', ['後唐', '後晋', '五代漢'], ['燕雲十六州', '遼'], '五代十国'],
    ['乾符', ['後唐', '後晋', '五代漢', '後周'], ['燕雲十六州', '遼'], '五代十国'],
    ['乾符', ['楊呉'], [], '五代十国'],
    ['乾符', ['呉越'], [], '五代十国'],
    ['乾符', ['朱梁', '馬楚'], [], '五代十国'],
    ['乾符', ['十国閩'], [], '五代十国'],
    ['乾符', ['南漢'], [], '五代十国'],
    ['乾符', ['蜀'], [], '五代十国'],
    ['乾符', ['荊南'], [], '五代十国'],

    ['天復', ['契丹 (耶律阿保機)', '耶律阿果'], [], '契丹国'],
    ['天復', ['契丹 (耶律阿保機)', '耶律大石', '屈出律'], ['外蒙古'], '契丹国'],
    ['完顔盈歌', [], [], '金'],
  );
});
my $i = 0;
for (@set) {
  printf STDERR "\r%d/%d", ++$i, 0+@set;
  my $era = $EraByKey->{$_->[0]} // die "Bad era key |$_->[0]|";
  my $ti = [map { $TagByKey->{$_} // die "Bad tag key |$_->[1]|" } @{$_->[1]}];
  my $tx = [map { $TagByKey->{$_} // die "Bad tag key |$_->[2]|" } @{$_->[2]}];
  my $ref_tag = $TagByKey->{$_->[3]} // die "Bad tag key |$_->[3]|";
  
  local $ENV{TAGS_INCLUDED} = join ',', map { encode_web_utf8 $_->{key} } @$ti;
  local $ENV{TAGS_EXCLUDED} = join ',', map { encode_web_utf8 $_->{key} } @$tx;

  my $out_name = $era->{id};
  $out_name .= '_' . $_->{id} for @$ti;
  $out_name .= '-' . $_->{id} for @$tx;
  my $out_path = $ThisPath->child ("era-ts-$out_name.txt");

  my $header = join "\x0A",
      (sprintf q{# y~%d %s}, $era->{id}, $era->{key}),
      (map { sprintf q{# + tag %d #%s}, $_->{id}, $_->{key} } @$ti),
      (map { sprintf q{# - tag %d #%s}, $_->{id}, $_->{key} } @$tx),
      (sprintf q{# <https://data.suikawiki.org/tag/%d/graph?sequence=%s>},
           $ref_tag->{id},
           join '', $era->{id}, (map { '%2B' . $_->{id} } @$ti), (map { '-' . $_->{id} } @$tx)),
      '';
  $out_path->spew (encode_web_utf8 $header);
  
  my $start = encode_web_utf8 $era->{key};
  my $perl_path = $RootPath->child ('perl');
  my $pl_path = $RootPath->child ('bin/extract-era-transitions.pl');
  (system "\Q$perl_path\E \Q$pl_path\E \Q$start\E >> \Q$out_path\E") == 0
      or die $?;
}
print STDERR "\n";

## License: Public Domain.
