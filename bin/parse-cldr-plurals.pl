use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::DOM::Document;

my $Data = {};

for my $xml_path (
  path (__FILE__)->parent->parent->child ('local/cldr-plurals.xml'),
  path (__FILE__)->parent->parent->child ('local/cldr-plurals-ordinals.xml'),
) {
  my $doc = new Web::DOM::Document;
  $doc->inner_html ($xml_path->slurp_utf8);
  for my $plurals ($doc->document_element->children->to_list) {
    next unless $plurals->local_name eq 'plurals';
    my $type = $plurals->get_attribute ('type');
    for my $prules ($plurals->children->to_list) {
      next unless $prules->local_name eq 'pluralRules';
      my $locales = $prules->get_attribute ('locales');
      for my $prule ($prules->children->to_list) {
        next unless $prule->local_name eq 'pluralRule';
        my $count = $prule->get_attribute ('count');
        my $def = $prule->text_content;
        $def =~ s/\@integer.*//s;
        $def =~ s/\@decimal.*//s;
        $def =~ s/\s+/ /g;
        $def =~ s/^ //;
        $def =~ s/ $//;
        $Data->{$type}->{$locales}->{$count} = $def;
      }
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
