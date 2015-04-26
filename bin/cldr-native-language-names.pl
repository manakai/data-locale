use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $Data = {};

my @lang;
my $json_by_lang = {};
for (glob path (__FILE__)->parent->parent->child ('local/cldr-core-json/*.json')) {
  my $path = path ($_);
  /([a-zA-Z0-9_]+)\.json$/;
  my $lang = $1;
  $json_by_lang->{$lang} = my $json = json_bytes2perl $path->slurp;
  if (defined $json->{languages}->{$lang}) {
    $Data->{langs}->{$lang} = $json->{languages}->{$lang};
  } else {
    push @lang, $lang;
  }
}

for my $lang (@lang) {
  if ($lang =~ /^([A-Za-z0-9]+)_([A-Z][a-z]{3})_([A-Za-z0-9]+)$/) {
    my $l = $1;
    my $script = $2;
    my $la = $l."_".$script;
    my $region = $3;
    my $lang_json = $json_by_lang->{$lang};
    my $la_json = $json_by_lang->{$la} || {};
    my $l_json = $json_by_lang->{$l} or next;
    my $l_name = $lang_json->{languages}->{$l} //
                 $la_json->{languages}->{$la} //
                 $l_json->{languages}->{$l} //
                 $json_by_lang->{en}->{languages}->{$l} // $l;
    my $script_name = $lang_json->{scripts}->{$script} //
                      $la_json->{scripts}->{$script} //
                      $l_json->{scripts}->{$script} //
                      $json_by_lang->{en}->{scripts}->{$script} // $script;
    my $region_name = $lang_json->{territories}->{$region} //
                      $la_json->{territories}->{$region} //
                      $l_json->{territories}->{$region} //
                      $json_by_lang->{en}->{territories}->{$region} // $region;
    $Data->{langs}->{$lang} = "$l_name ($script_name, $region_name)";
  } elsif ($lang =~ /^([A-Za-z0-9]+)_([A-Z][a-z]{3})$/) {
    my $l = $1;
    my $script = $2;
    my $lang_json = $json_by_lang->{$lang};
    my $l_json = $json_by_lang->{$l} or next;
    my $l_name = $lang_json->{languages}->{$l} // $l_json->{languages}->{$l} // $json_by_lang->{en}->{languages}->{$l} // $l;
    my $script_name = $lang_json->{scripts}->{$script} // $l_json->{scripts}->{$script} // $json_by_lang->{en}->{scripts}->{$script} // $script;
    $Data->{langs}->{$lang} = "$l_name ($script_name)";
  } elsif ($lang =~ /^([A-Za-z0-9]+)_([A-Za-z0-9]+)$/) {
    my $l = $1;
    my $region = $2;
    my $lang_json = $json_by_lang->{$lang};
    my $l_json = $json_by_lang->{$l} or next;
    my $l_name = $lang_json->{languages}->{$l} // $l_json->{languages}->{$l} // $json_by_lang->{en}->{languages}->{$l} // $l;
    my $region_name = $lang_json->{territories}->{$region} // $l_json->{territories}->{$region} // $json_by_lang->{en}->{territories}->{$region} // $region;
    $Data->{langs}->{$lang} = "$l_name ($region_name)";
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
