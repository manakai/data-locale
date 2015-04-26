use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::DOM::Document;
use JSON::PS;

my $Data = {};

{
  my $path = path (__FILE__)->parent->parent->child ('local/facebook-locales.xml');
  my $doc = new Web::DOM::Document;
  $doc->inner_html ($path->slurp_utf8);
  for my $locale ($doc->document_element->children->to_list) {
    next unless $locale->local_name eq 'locale';
    my $el = $locale->query_selector ('standard > representation') or next;
    my $code = $el->text_content;
    $Data->{locales}->{$code} = 1;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
