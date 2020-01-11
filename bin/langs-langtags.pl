use strict;
use warnings;
use Path::Class;
use lib glob file (__FILE__)->dir->subdir ('modules', '*', 'lib')->stringify;
use Encode;
use Web::DOM::Document;
use JSON::PS qw(file2perl perl2json_bytes_for_record);

my $full = 1;
my $subtags;

{
  my $langreg_source_file_name = shift;
  open my $langreg_source_file, '<', $langreg_source_file_name or
      die "$0: $langreg_source_file_name: $!";
  local $/ = undef;

  ## NOTE: Based on RFC 4646 3.1.'s syntax, but more error-tolerant.
  for (split /\x0D?+\x0A%%[\x20\x09]*\x0D?+\x0A/, decode 'utf-8', <$langreg_source_file>) {
    my $fields = [['' => '']];
    for (split /\x0D?+\x0A/, $_) {
      if (/^\s/) { ## Part of continuous line
        $fields->[-1]->[1] .= $_;
      } elsif (s/^([^:\s]++)\s*+:\s*+//) { ## The first line of a |field|
        push @$fields, [$1 => $_];
      } else { ## An errorneous line
        push @$fields, ['' => $_];
      }
    }
    my $subtag;
    shift @$fields if $fields->[0]->[1] eq ''; # remove dummy if unused
    for (@$fields) {
      $subtag->{$_->[0]} ||= [];
      my $v = $_->[1];
      $v =~ s/&#x([0-9A-Fa-f]++);/chr hex $1/ge;
      push @{$subtag->{$_->[0]}}, $v;
    }
    if ($subtags) {
      my $tag_name_start = $subtag->{Subtag}->[0] || $subtag->{Tag}->[0];
      if ($tag_name_start =~ /^[A-Z][a-z]++(?>\.\.[A-Z][a-z]++)?+$/) {
        $subtag->{_canon} = '_titlecase';
      } elsif ($tag_name_start =~ /^[A-Z]++(?>\.\.[A-Z]++)?+$/) {
        $subtag->{_canon} = '_uppercase';
      } elsif ($tag_name_start =~ /^[a-z]++(?>\.\.[a-z-]++)?+$/) {
        #$subtag->{_canon} = '_lowercase';
      } else {
        $subtag->{_canon} = $tag_name_start;
      }
      $subtag->{_registry}->{iana} = 1;
      $tag_name_start =~ tr/A-Z/a-z/;
      my $tag_name_end;
      if ($tag_name_start =~ /^(.+)\.\.(.+)$/) {
        $tag_name_start = $1;
        $tag_name_end = $2;
      } else {
        $tag_name_end = $tag_name_start;
      }
      for my $tag_name (
        $tag_name_start eq $tag_name_end
          ? ($tag_name_start) # for 'nan'
          : ($tag_name_start .. $tag_name_end)
      ) {
        if ($subtags->{$subtag->{Type}->[0]}->{$tag_name}) {
          warn "Duplicate tag: $tag_name\n";
        } else {
          $subtags->{$subtag->{Type}->[0]}->{$tag_name} = $subtag;
        }
      }
    } else { ## The first record
      $subtags->{header} = $subtag;
    }
  }
}

## Extensions
if ($full) {
  my $langreg_source_file_name = shift;
  open my $langreg_source_file, '<', $langreg_source_file_name or
      die "$0: $langreg_source_file_name: $!";
  local $/ = undef;

  ## NOTE: Based on RFC 4646 3.1.'s syntax, but more error-tolerant.
  for (split /\x0D?+\x0A%%[\x20\x09]*\x0D?+\x0A/, decode 'utf-8', <$langreg_source_file>) {
    my $fields = [['' => '']];
    for (split /\x0D?+\x0A/, $_) {
      if (/^\s/) { ## Part of continuous line
        $fields->[-1]->[1] .= $_;
      } elsif (s/^([^:\s]++)\s*+:\s*+//) { ## The first line of a |field|
        push @$fields, [$1 => $_];
      } else { ## An errorneous line
        push @$fields, ['' => $_];
      }
    }
    my $subtag;
    shift @$fields if $fields->[0]->[1] eq ''; # remove dummy if unused
    for (@$fields) {
      $subtag->{$_->[0]} ||= [];
      my $v = $_->[1];
      $v =~ s/&#x([0-9A-Fa-f]++);/chr hex $1/ge;
      push @{$subtag->{$_->[0]}}, $v;
    }
    if ($subtags->{extension}) {
      my $tag_name = $subtag->{Identifier}->[0];
      #$subtag->{_canon} = '_lowercase';
      $subtag->{_registry}->{iana} = 1;
      if ($subtags->{extension}->{$tag_name}) {
        warn "Duplicate tag: $tag_name\n";
      } else {
        $subtags->{extension}->{$tag_name} = $subtag;
      }
    } else { ## The first record
      $subtags->{extheader} = $subtag;
      $subtags->{extension} = {};
    }
  }
}

for my $xml_file_name (@ARGV) {
  local $/ = undef;
  open my $file, '<', $xml_file_name or die "$0: $xml_file_name: $!";

  my $doc = new Web::DOM::Document;
  $doc->inner_html (decode 'utf-8', scalar <$file>);

  my $keys = $doc->query_selector_all ('key');
  for my $key (@$keys) {
    my $key_ext = $key->get_attribute ('extension') || 'u';
    $key_ext =~ tr/A-Z/a-z/;
    my $key_name = $key->get_attribute ('name');
    $key_name =~ tr/A-Z/a-z/;
    my $key_desc = $key->get_attribute ('description');
    $subtags->{$key_ext . '_key'}->{$key_name} = {
      Description => [$key_desc],
      _registry => {unicode => 1},
    };
    my $types = $key->query_selector_all ('type');
    for my $type (@$types) {
      my $type_name = $type->get_attribute ('name');
      if ($type_name =~ /[A-Z]/) {
        $subtags->{$key_ext . '_key'}->{$key_name}->{_value_type} = $type_name;
      } else {
        my $type_desc = $type->get_attribute ('description');
        my $def = $subtags->{$key_ext . '_' . $key_name}->{$type_name} = {
          Description => [$type_desc],
          _registry => {unicode => 1},
        };
        if (($type->get_attribute ('deprecated') // '') eq 'true') {
          $def->{_deprecated} = 1;
        }
        my $preferred = $type->get_attribute ('preferred');
        $def->{_preferred} = lc $preferred if defined $preferred;
      }
    }
  }
}

## Remove unused data

$subtags->{_file_date} = $subtags->{header}->{'File-Date'}->[0];
delete $subtags->{header};
if ($full) {
  $subtags->{_ext_file_date} = $subtags->{extheader}->{'File-Date'}->[0];
  delete $subtags->{extheader};
}

for my $type (grep {!/^_/} keys %{$subtags}) {
  for my $tag (keys %{$subtags->{$type}}) {
    my $subtag = $subtags->{$type}->{$tag};

    if ($full) {
      $subtag->{_added} = $subtag->{Added}->[0]
          if $subtag->{Added}->[0];
      $subtag->{_macro} = $subtag->{Macrolanguage}->[0]
          if $subtag->{Macrolanguage};
    } else {
      delete $subtag->{Comments};
      delete $subtag->{Description};
      delete $subtag->{Scope};
    }
    delete $subtag->{Added};
    delete $subtag->{Tag};
    delete $subtag->{Subtag};
    delete $subtag->{Type};
    delete $subtag->{Macrolanguage};
    delete $subtag->{Identifier};
    delete $subtag->{RFC};
    delete $subtag->{Authority};
    delete $subtag->{Contact_Email};
    delete $subtag->{Mailing_List};
    delete $subtag->{URL};

    $subtag->{_deprecated} = 1 if $subtag->{Deprecated};
    delete $subtag->{Deprecated};

    if (defined $subtag->{'Preferred-Value'}->[0]) {
      $subtag->{_preferred} = $subtag->{'Preferred-Value'}->[0];
      #$subtag->{_preferred} =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
    }
    delete $subtag->{'Preferred-Value'};

    if (defined $subtag->{'Suppress-Script'}->[0]) {
      $subtag->{_suppress} = $subtag->{'Suppress-Script'}->[0];
      $subtag->{_suppress} =~ tr/A-Z/a-z/;
    }
    delete $subtag->{'Suppress-Script'};

    for (@{$subtag->{Prefix} or []}) {
      tr/A-Z/a-z/;
    }

    ## Sort for the ease of validation process
    $subtag->{Prefix} = [sort {length $b <=> length $a or $a cmp $b}
                             @{$subtag->{Prefix}}] if $subtag->{Prefix};
  }
}

## Resolve transitive relationship of Preferred-Value field

for my $type (grep {!/^_/} keys %{$subtags}) {
  for my $tag (keys %{$subtags->{$type}}) {
    my $subtag = $subtags->{$type}->{$tag};
    my $preferred_subtag = $subtag;
    my $preferred = $tag;
    while (1) {
      $preferred = $preferred_subtag->{_preferred} || $tag;
      $preferred =~ tr/A-Z/a-z/; ## ASCII case-insensitive.
      last if $preferred eq $tag;
      $preferred_subtag = $subtags->{$type}->{$preferred};
    }
    $subtag->{_preferred} = $preferred if $preferred ne $tag;
  }
}

{
  my $scripts = file2perl file (__FILE__)->dir->parent->file ('local', 'chars-scripts.json');
  for (values %{$scripts->{scripts}}) {
    next unless defined $_->{collation_reorder};
    my $code = lc $_->{collation_reorder};
    $subtags->{u_kr}->{$code} = {
      _registry => {unicode => 1},
    };
    $subtags->{u_kr}->{$code}->{Description} = $_->{desc} if $_->{desc};
    if (defined $_->{iso} and not $_->{collation_reorder} eq $_->{iso}) {
      $subtags->{u_kr}->{lc $_->{iso}} = {
        _registry => {unicode => 1},
      };
      $subtags->{u_kr}->{lc $_->{iso}}->{_preferred} = $code;
    }
  }
}

print perl2json_bytes_for_record $subtags;

__END__

=head1 SEE ALSO

RFC 4646: Tags for Identifying Languages
<http://tools.ietf.org/html/rfc4646>.

RFC 5646: Tags for Identifying Languages
<http://tools.ietf.org/html/rfc5646>.

RFC 6067: BCP 47 Extension U <http://tools.ietf.org/html/rfc6067>.

RFC 6497: BCP 47 Extension T - Transformed Content
<http://tools.ietf.org/html/rfc6497>.

IANA Language Subtag Registry
<http://www.iana.org/assignments/language-subtag-registry>.

IANA Language Tag Extensions Registry
<http://www.iana.org/assignments/language-tag-extensions-registry/language-tag-extensions-registry>.

UTS #35: Unicode Locale Data Markup Language
<http://unicode.org/reports/tr35/>.

Unicode Locale Extensions for BCP 47
<http://cldr.unicode.org/index/bcp47-extension>,
<http://unicode.org/repos/cldr/trunk/common/bcp47/>.

=head1 AUTHOR

Wakaba <wakaba@suikawiki.org>.

=head1 LICENSE

C<langtags.pl> is derived from C<mklangreg.pl> in the manakai-core
package <https://github.com/wakaba/manakai>.

The C<mklangreg.pl> is in the Public Domain.

=cut
