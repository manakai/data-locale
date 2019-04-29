use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Input = {};
my $Data = {};

for my $file_name (qw(
  era-defs-jp.json
)) {
  my $path = $RootPath->child ('local')->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    if (defined $Data->{eras}->{$key}) {
      die "Duplicate era key |$key|";
    }
    $Input->{eras}->{$key} = $json->{eras}->{$key};
  }
}

for my $file_name (qw(era-defs-dates.json)) {
  my $path = $RootPath->child ('local')->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    my $data = $json->{eras}->{$key};
    for (keys %$data) {
      $Input->{eras}->{$key}->{$_} = $data->{$_};
    }
  }
}

{
  my $path = $RootPath->child ('src/wp-jp-eras-en.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (values %{$Input->{eras}}) {
    next unless $data->{jp_era} or $data->{jp_north_era} or $data->{jp_south_era};
    my $en;
    if (defined $data->{start_year} and defined $data->{end_year}) {
      $en ||= $json->{$data->{start_year}, $data->{end_year}};
    }
    if (defined $data->{north_start_year} and defined $data->{north_end_year}) {
      $en ||= $json->{$data->{north_start_year}, $data->{north_end_year}};
    }
    if (defined $data->{south_start_year} and defined $data->{south_end_year}) {
      $en ||= $json->{$data->{south_start_year}, $data->{south_end_year}};
    }
    if (defined $data->{start_year} and not defined $data->{end_year}) {
      $en ||= $json->{$data->{start_year}, ''};
    }
    use utf8;
    if ($data->{key} eq '宝亀') {
      $en ||= $json->{770, 781};
    }
    if ($data->{key} eq '永延') {
      $en ||= $json->{987, 988};
    }
    if ($data->{key} eq '永祚') {
      $en ||= $json->{988, 990};
    }
    if ($data->{key} eq '文亀') {
      $en ||= $json->{1501, 1521};
    }
    if ($data->{key} eq '永徳') { # 弘和/永徳
      $en = $json->{1381, 1384.2};
    }
    if (defined $en) {
      my $dd = $Data->{eras}->{$data->{key}} ||= {};
      $dd->{name_latn} = $en->{name};
      $dd->{wref_en} = $en->{wref_en} if defined $en->{wref_en};
      for (qw(key name start_year north_start_year south_start_year)) {
        $dd->{$_} = $data->{$_};
      }
    } else {
      warn "Era |$data->{key}| not defined in English Wikipedia";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
