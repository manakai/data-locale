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

sub drop_kanshi ($) {
  my $name = shift;
  $name =~ s/\(\w+\)$//;
  return $name;
} # drop_kanshi

sub expand_name ($$) {
  my ($era, $name) = @_;
  $era->{names}->{drop_kanshi $name} = 1;
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
  for (@$current) {
    if (/^(.+?)\(\w+\)$/) {
      $era->{names}->{$1} = 1;
    } else {
      $era->{names}->{$_} = 1;
    }
  }
  my @all = @$current;
  for my $name (@$current) {
    if ($name =~ s/摂政$//) {
      $era->{names}->{$name} = 1,
      push @all, $name
          if length $name;
    }
    if ($name =~ s/天皇$//) {
      $era->{names}->{$name} = 1,
      push @all, $name
          if length $name;
    }
  }

  for (@all) {
    if (/^(.+)\(\w+\)$/) {
      $Data->{name_conflicts}->{$1}->{$era->{key}} = 1;
    } elsif (defined $Data->{name_to_key}->{jp}->{$_} and
             not $Data->{name_to_key}->{jp}->{$_} eq $era->{key}) {
      warn "Duplicate era |$_| (|$era->{key}| vs |$Data->{name_to_key}->{jp}->{$_}|)";
    } else {
      $Data->{name_to_key}->{jp}->{$_} = $era->{key};
    }
  }
} # expand_name

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
expand_name $Data->{eras}->{明治}, '㍾';
expand_name $Data->{eras}->{大正}, '㍽';
expand_name $Data->{eras}->{昭和}, '㍼';
expand_name $Data->{eras}->{平成}, '㍻';

for my $era (values %{$Data->{eras}}) {
  my $name = $era->{name};
  expand_name $era, $name;
  $era->{short_name} = $name;
  $name =~ s/摂政$//;
  $era->{names}->{$name} = 1 if length $name;
  $era->{short_name} = $name if length $name;
  $name =~ s/天皇$//;
  $era->{names}->{$name} = 1 if length $name;
  $era->{short_name} = $name if length $name;
  if ($name ne $era->{name}) {
    expand_name $era, $name;
  }
  $era->{names}->{$era->{abbr}} = 1, expand_name $era, $era->{abbr}
      if defined $era->{abbr};
  $era->{names}->{$era->{abbr_latn}} = 1, expand_name $era, $era->{abbr_latn}
      if defined $era->{abbr_latn};
  $era->{names}->{lc $era->{abbr_latn}} = 1, expand_name $era, lc $era->{abbr_latn}
      if defined $era->{abbr_latn};
}

{
  my $path = $root_path->child ('src/era-yomi.txt');
  my $key;
  my $prop;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)\s+(\S+)$/) {
      die "Bad key |$1|" unless $Data->{eras}->{$1};
      $Data->{eras}->{$1}->{name_kanas}->{$2} = 1;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $root_path->child ('src/jp-private-eras.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)(?:\s+(BC|)(\d+)|)$/) {
      my $first_year = defined $3 ? $2 ? 1 - $3 : $3 : undef;
      my @name = split /,/, $1;
      my @n;
      for (@name) {
        if (defined $Data->{name_to_key}->{jp}->{$_}) {
          warn "Duplicate era |$_|";
        } else {
          push @n, $_;
        }
      }
      next unless @n;
      my $d = $Data->{eras}->{$n[0]} ||= {};
      $d->{jp_private_era} = 1;
      $d->{key} = $n[0];
      $d->{name} = drop_kanshi $n[0];
      $d->{names}->{drop_kanshi $_} = 1 for @n;
      expand_name $d, $_ for @n;
      if (defined $first_year) {
        $d->{offset} = $first_year - 1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $root_path->child ('src/era-variants.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)\s*=\s*(\S+)$/) {
      my $variant = $1;
      my $key = $2;
      die "Era |$key| not defined" unless defined $Data->{eras}->{$key};
      $Data->{eras}->{$key}->{names}->{drop_kanshi $variant} = 1;
      expand_name $Data->{eras}->{$key}, $variant;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $root_path->child ('src/era-data.txt');
  my $key;
  my $prop;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^\[(.+)\]$/) {
      $key = $1;
      die "Bad key |$key|" unless $Data->{eras}->{$key};
      undef $prop;
    } elsif (defined $key and /^(source)$/) {
      push @{$Data->{eras}->{$key}->{sources} ||= []}, $prop = {};
    } elsif (defined $prop and ref $prop eq 'HASH' and
             /^  (title|url):(.+)$/) {
      $prop->{$1} = $2;
    } elsif (defined $key and /^(wref_ja)\s+(.+)$/) {
      $Data->{eras}->{$key}->{wref_ja} = $2;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for my $name (keys %{$Data->{name_conflicts}}) {
  if (defined $Data->{name_to_key}->{jp}->{$name}) {
    $Data->{name_conflicts}->{$name}->{$Data->{name_to_key}->{jp}->{$name}} = 1;
  } else {
    warn "Era name |$name| not defined";
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
