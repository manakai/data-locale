use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $Data = {};

for my $file_name (qw(
  era-defs-jp.json era-defs-jp-emperor.json
)) {
  my $path = $root_path->child ('local')->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    if (defined $Data->{eras}->{$key}) {
      die "Duplicate era key |$key|";
    }
    $Data->{eras}->{$key} = $json->{eras}->{$key};
  }
}

for my $file_name (qw(era-defs-dates.json)) {
  my $path = $root_path->child ('local')->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    my $data = $json->{eras}->{$key};
    for (keys %$data) {
      $Data->{eras}->{$key}->{$_} = $data->{$_};
    }
  }
}

{
  my $path = $root_path->child ('src/wp-jp-eras-en.json');
  my $json = json_bytes2perl $path->slurp;
  for my $data (values %{$Data->{eras}}) {
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
    if ($data->{name} eq '宝亀') {
      $en ||= $json->{770, 781};
    }
    if ($data->{name} eq '永延') {
      $en ||= $json->{987, 988};
    }
    if ($data->{name} eq '永祚') {
      $en ||= $json->{988, 990};
    }
    if ($data->{name} eq '文亀') {
      $en ||= $json->{1501, 1521};
    }
    if (defined $en) {
      $data->{name_latn} = $en->{name};
      $data->{wref_en} = $en->{wref_en} if defined $en->{wref_en};
    } else {
      warn "Era |$data->{name}| not defined in English Wikipedia";
    }
  }
}

my $Variants = {};
{
  my $path = $root_path->child ('src/char-variants.txt');
  for (split /\n/, $path->slurp_utf8) {
    my @char = split /\s+/, $_;
    @char = map { s/^j://; $_ } @char;
    for my $c1 (@char) {
      for my $c2 (@char) {
        $Variants->{$c1}->{$c2} = 1;
      }
    }
  }
}

$Data->{eras}->{$_}->{abbr} = substr $_, 0, 1
    for qw(慶応 明治 大正 昭和 平成);
$Data->{eras}->{明治}->{abbr_latn} = 'M';
$Data->{eras}->{大正}->{abbr_latn} = 'T';
$Data->{eras}->{昭和}->{abbr_latn} = 'S';
$Data->{eras}->{平成}->{abbr_latn} = 'H';
$Data->{eras}->{明治}->{names}->{'㍾'} = 1;
$Data->{eras}->{大正}->{names}->{'㍽'} = 1;
$Data->{eras}->{昭和}->{names}->{'㍼'} = 1;
$Data->{eras}->{平成}->{names}->{'㍻'} = 1;

for my $era (values %{$Data->{eras}}) {
  my $name = $era->{name};
  $era->{names}->{$name} = 1;
  my @name = split //, $name;
  @name = map { [keys %$_] } map { $Variants->{$_} || {$_ => 1} } @name;
  my $current = [''];
  while (@name) {
    my $char = shift @name;
    my @next;
    for my $p (@$current) {
      for my $c (@$char) {
        push @next, $p.$c;
      }
    }
    $current = \@next;
  }
  $era->{names}->{$_} = 1 for @$current;
  $era->{short_name} = $name;
  $name =~ s/摂政$//;
  $era->{names}->{$name} = 1 if length $name;
  $era->{short_name} = $name if length $name;
  $name =~ s/天皇$//;
  $era->{names}->{$name} = 1 if length $name;
  $era->{short_name} = $name if length $name;
  for my $name (@$current) {
    $name =~ s/摂政$//;
    $era->{names}->{$name} = 1 if length $name;
    $name =~ s/天皇$//;
    $era->{names}->{$name} = 1 if length $name;
  }
  $era->{names}->{$era->{abbr}} = 1 if defined $era->{abbr};
  $era->{names}->{$era->{abbr_latn}} = 1 if defined $era->{abbr_latn};
  $era->{names}->{lc $era->{abbr_latn}} = 1 if defined $era->{abbr_latn};
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
