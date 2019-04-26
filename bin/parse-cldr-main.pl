use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use Web::DOM::Document;
use JSON::PS;

my $json_dir_path = path (__FILE__)->parent->parent->child ('local/cldr-core-json');
$json_dir_path->mkpath;

sub generate_json ($) {
  my $xml_path = $_[0];
  $xml_path =~ /([a-zA-Z0-9_]+)\.xml$/;
  warn "$xml_path...\n";
  my $locale = $1;
  my $json_path = $json_dir_path->child ("$locale.json");
  my $data = {};

  my $doc = Web::DOM::Document->new;
  $doc->inner_html ($xml_path->slurp_utf8);

  for my $el ($doc->document_element->children->to_list) {
    if ($el->local_name eq 'localeDisplayNames') {
      for my $el ($el->children->to_list) {
        my $col_name = $el->local_name;
        if ($col_name eq 'languages' or
            $col_name eq 'territories' or
            $col_name eq 'scripts' or
            $col_name eq 'variants' or
            $col_name eq 'keys' or
            $col_name eq 'transformNames' or
            $col_name eq 'mesaurementSystemNames') {
          for my $leaf_el ($el->children->to_list) {
            my $leaf_type = $leaf_el->local_name;
            if ($leaf_type eq 'language' or
                $leaf_type eq 'territory' or
                $leaf_type eq 'script' or
                $leaf_type eq 'variant' or
                $leaf_type eq 'key' or
                $leaf_type eq 'transformName' or
                $leaf_type eq 'measurementSystemName') {
              my $type = $leaf_el->get_attribute ('type');
              my $value = $leaf_el->text_content;
              $data->{$col_name}->{$type} = $value;
            }
          }
        }
      }
    } elsif ($el->local_name eq 'dates') {
      for (@{$el->query_selector_all ('calendar[type=japanese] > eras > eraAbbr > era')}) {
        $data->{dates_calendar_japanese_era}->[$_->get_attribute ('type')] = $_->text_content;
      }
    }
  }

  $json_path->spew (perl2json_bytes_for_record $data);
} # generate_json

for (glob path (__FILE__)->parent->parent->child ('local/cldr-core/common/main/*.xml')) {
  generate_json path ($_);
}
