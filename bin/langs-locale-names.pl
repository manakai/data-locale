use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::LangTag;

my $local_path = path (__FILE__)->parent->parent->child ('local');
my $src_path = path (__FILE__)->parent->parent->child ('src');

my $Data = {};

{
  my $path = $local_path->child ('cldr-locales.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^([0-9A-Za-z_]+)$/) {
      my $id = $1;
      my $tag = $id;
      $tag =~ tr/A-Z_/a-z-/;
      $tag = 'und' if $tag eq 'root';
      $tag =~ s/-posix$/-u-va-posix/;
      $Data->{tags}->{$tag}->{cldr} = $id;
    }
  }
}

{
  my $path = $src_path->child ('ms-locales.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^([a-z0-9-]+) ([0-9]+)$/) {
      my $tag = $1;
      $tag =~ tr/A-Z/a-z/;
      $Data->{tags}->{$tag}->{ms} = $2;
    }
  }
}

{
  my $path = $src_path->child ('chromewebstore-locales.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^([a-zA-Z0-9_]+)\s/) {
      my $code = $1;
      my $tag = $code;
      $tag =~ tr/A-Z_/a-z-/;
      $Data->{tags}->{$tag}->{chrome_web_store} = $code;
    }
  }
}

{
  my $path = $local_path->child ('fx-locales.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^([a-zA-Z0-9-]+)$/) {
      my $code = $1;
      my $tag = $code;
      $tag =~ tr/A-Z/a-z/;
      $Data->{tags}->{$tag}->{firefox} = $code;
    }
  }
}

{
  my $path = $src_path->child ('mysql-locales.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^([a-zA-Z0-9_]+)$/) {
      my $code = $1;
      my $tag = $code;
      $tag =~ tr/A-Z_/a-z-/;
      $Data->{tags}->{$tag}->{mysql} = $code;
    }
  }
}

{
  my $path = $src_path->child ('java-locales.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^([a-zA-Z0-9_]+)$/) {
      my $code = $1;
      my $tag = $code;
      $tag =~ tr/A-Z_/a-z-/;
      $tag = {
        'ja-jp-jp' => 'ja-jp-u-ca-japanese',
        'no-no' => 'nb',
        'no-no-ny' => 'nn',
        'th-th-th' => 'th-th-u-nu-thai',
      }->{$tag} || $tag;
      $Data->{tags}->{$tag}->{java} = $code;
    }
  }
}

for my $tag (keys %{$Data->{tags}}) {
  my @error;
  my $lt = Web::LangTag->new;
  my $suppress = 0;
  $lt->onerror (sub {
    my $error = {@_};
    return if $error->{level} eq 'w' or $error->{level} eq 'i';
    return if $error->{level} eq 's' and $error->{type} =~ /:case$/;
    if ($error->{type} eq 'langtag:script:suppress') {
      $suppress = 1;
    }
    push @error, $error;
  });
  my $parsed = $lt->parse_tag ($tag);
  $lt->check_parsed_tag ($parsed);
  $Data->{tags}->{$tag}->{bcp47_errors} = \@error if @error;

  my $canon = $lt->canonicalize_tag ($lt->normalize_tag ($tag));
  $canon =~ s/^([a-z]+)-[A-Z][a-z]{3}\b/$1/ if $suppress;
  $Data->{tags}->{$tag}->{bcp47_canonical} = $canon;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
