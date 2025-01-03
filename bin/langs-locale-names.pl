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
  for (
    ['ja-jpm' => 'ja-jp-mac'],
    ['x-klingon' => 'tlh'],
  ) {
    my $lt = Web::LangTag->new;
    $lt->onerror (sub { });
    my $canon = $lt->canonicalize_tag ($lt->normalize_tag ($_->[1]));
    $canon =~ tr/A-Z/a-z/;
    $Data->{preferred_tags}->{$_->[0]} = $canon;
    $Data->{tags}->{$_->[0]} ||= {};
    $Data->{tags}->{$canon} ||= {};
  }
}

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
      $tag = {
        sb => 'wen',
        sx => 'st',
      }->{$tag} || $tag;
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
  my $path = $local_path->child ('fx-locales.json');
  my $json = json_bytes2perl $path->slurp;
  for (keys %{$json->{locales}}) {
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
  my $path = $src_path->child ('facebook-locales.json');
  my $json = json_bytes2perl $path->slurp;
  for my $locale (keys %{$json->{locales}}) {
    my $lang = $locale;
    $lang =~ tr/A-Z_/a-z-/;
    $lang = {
      'ar-ar' => 'ar', # <https://developers.facebook.com/docs/internationalization>
      'bp-in' => 'bho-in', # Bhojpuri
      'cb-iq' => 'ckb-iq',
      'ck-us' => 'chr-us',
      'cx-ph' => 'ceb-ph',
      'eo-eo' => 'eo',
      'es-la' => 'es-419', # <https://developers.facebook.com/docs/internationalization>
      'qc-gt' => 'quc-gt',
      'gx-gr' => 'grc-gr',
      'ja-ks' => 'ja-jp-kansai',
      'sy-sy' => 'syc-sy',
      'sz-pl' => 'szl-pl',
      'tl-ph' => 'fil-ph',
      'tl-st' => 'tlh',
      'tz-ma' => 'ber-ma',
      'zz-tr' => 'zza-tr',
    }->{$lang} // $lang;
    next if {
      'en-pi' => 1,
      'en-ud' => 1,
      'fb-lt' => 1,
    }->{$lang}; # no BCP 47 language tag...
    $Data->{tags}->{$lang}->{facebook} = $locale;
  }
}

{
  my $path = $local_path->child ('mediawiki-locales.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^([a-zA-Z0-9-]+)$/) {
      my $code = $1;
      my $tag = $code;
      $tag =~ tr/A-Z_/a-z-/;
      $tag = {
        ## <http://meta.wikimedia.org/wiki/List_of_Wikipedias#Nonstandard_language_codes>
        'simple' => 'en-simple',
        #map-bms
        'roa-rup' => 'rup',
        'bat-smg' => 'sgs',
        #cbk-zam
        #roa-tara
        #ksh
        #nds-NL => nds
        'nrm' => 'nrf',
        'fiu-vro' => 'vro',
        'zh-yue' => 'yue',
        'zh-min-nan' => 'nan',
        'zh-classical' => 'lzh',
        'be-x-old' => 'be-tarask',
      }->{$tag} || $tag;
      $Data->{tags}->{$tag}->{mediawiki} = $code;
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

{
  my $path = $local_path->child ('cldr-native-language-names.json');
  my $json = json_bytes2perl $path->slurp;
  my $name = {};
  for (keys %{$json->{langs}}) {
    my $v = $_;
    $v =~ tr/A-Z_/a-z-/;
    $name->{$v} = $json->{langs}->{$_};
  }
  for my $tag (keys %{$Data->{tags}}) {
    my $name = $name->{$tag};
    $Data->{tags}->{$tag}->{native_name} = $name if defined $name;
  }
}

{
  my $path = $src_path->child ('rss2-language-codes.txt');
  for (split /\x0A/, $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^(.+?\S)\s+([a-zA-Z0-9-]+)$/) {
      my $code = $2;
      my $tag = $code;
      $tag =~ tr/A-Z/a-z/;
      $Data->{tags}->{$tag}->{rss2} = $code;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $src_path->child ('lang-names-additional.txt');
  for (split /\x0A/, $path->slurp_utf8) {
    my ($tag, $name) = split /\s+/, $_, 2;
    $Data->{tags}->{$tag}->{native_name} = $name;
  }
}

{
  my $tags = {};
  for my $tag (keys %{$Data->{tags}}) {
    if ($tag =~ /\A([a-z]{2})-[a-z]{2}\z/) {
      my $tag_short = $1;
      my $score = 0;
      do {$score++ if $Data->{tags}->{$tag}->{$_} } for qw(
        chrome_web_store firefox java ms mysql
      );
      next unless $score;

      next unless $Data->{tags}->{$tag_short};
      my $score_short = 0;
      do { $score_short++ if $Data->{tags}->{$tag_short}->{$_} } for qw(
        chrome_web_store firefox java ms mysql
      );
      next unless $score_short;

      #warn "$tag=$score / $tag_short=$score_short";
      $tags->{$tag_short}->{$tag} = 1;
    }
  }

  my $preferred = {};
  for my $tag_short (keys %$tags) {
    if (1 == keys %{$tags->{$tag_short}}) {
      $preferred->{[keys %{$tags->{$tag_short}}]->[0]} = $tag_short;
    } elsif ($tags->{$tag_short}->{"$tag_short-$tag_short"}) {
      $preferred->{"$tag_short-$tag_short"} = $tag_short;
    } elsif ($tags->{$tag_short}->{my $tag = {
      bn => 'bn-bd',
      en => 'en-us',
      sr => 'sr-rs',
      sv => 'sv-se',
      el => 'el-gr',
    }->{$tag_short} // ''}) {
      $preferred->{$tag} = $tag_short;
    } elsif ($tag_short eq 'ar') {
      #
    } else {
      for my $tag (keys %{$tags->{$tag_short}}) {
        warn "$tag_short $tag";
      }
    }
  }
  $Data->{countryless_tags} = $preferred;
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

  $lt->onerror (undef);
  my $canon = $lt->canonicalize_tag ($lt->normalize_tag ($Data->{preferred_tags}->{$tag} // $tag));
  $canon =~ s/^([a-z]+)-[A-Z][a-z]{3}\b/$1/ if $suppress;
  $Data->{tags}->{$tag}->{bcp47_canonical} = $canon;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
