use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

{
  my $path = $RootPath->child ('src/wp-jp-eras.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %$json) {
    my $yomi = $json->{$key}->{name_kana};
    next unless defined $yomi;
    $Data->{eras}->{$key}->{6001} = [$yomi];
    delete $json->{$key}->{name_kanas}->{$yomi};
    push @{$Data->{eras}->{$key}->{6001}},
        sort { $a cmp $b } keys %{$json->{$key}->{name_kanas}};
  }
}

{
  my $path = $RootPath->child ('local/era-defs-jp-wp-en.json');
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    my $v = $json->{eras}->{$key}->{name_latn};
    next unless defined $v;
    $Data->{eras}->{$key}->{6002} = $v;
    for (qw(key name start_year north_start_year south_start_year)) {
      $Data->{eras}->{$key}->{$_} = $json->{eras}->{$key}->{$_};
    }
  }
}

{
  my $path = $RootPath->child ('src/era-yomi-2.txt');
  my $X = qr{\p{Hiragana}+(?: \p{Hiragana}+)+};
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      next;
    } elsif (/^(\w+) (.+)$/) {
      my $key = $1;
      my $v = $2;
      if ($v =~ s/^($X)//o) {
        my $n1 = $1;
        if ($v =~ s/^ R ($X)//o) {
          my $n2 = $1;
          $Data->{eras}->{$key}->{6011} = $n1;
          $Data->{eras}->{$key}->{6012} = $n2;
        } else {
          #$Data->{eras}->{$key}->{6011} = ;
          $Data->{eras}->{$key}->{6012} = $n1;
        }
        while ($v =~ s/^ ([A-H]+) ($X)//o) {
          my $w = $1;
          my $n3 = $2;
          for (split //, $w) {
            $Data->{eras}->{$key}->{6013 + -0x41 + ord $_} = $n3;
          }
        }
        next unless length $v;
      }
    }
    if (/\S/) {
      die "Bad line |$_|";
    }
  }
  use utf8;
  $Data->{eras}->{'天平感宝'}->{6011} = delete $Data->{eras}->{'天平感宝'}->{6012};
}

{
  sub latin ($) {
    my $x = shift;
    $x =~ s/o\^\^/\x{01D2}/g;
    $x =~ s/u\^\^/\x{01D4}/g;
    $x =~ s/o\^/\x{F4}/g;
    $x =~ s/u\^/\x{FB}/g;
    $x =~ s/o~/\x{014D}/g;
    $x =~ s/_/ /g;
    die $x if $x =~ /[~^_]/;
    return $x;
  } # latin
  
  use utf8;
  my $path = $RootPath->child ('src/era-yomi-3.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      next;
    } elsif (/^(\w+) (\p{Hiragana}+)(?:、(\p{Hiragana}+)|)(?:、(\p{Hiragana}+)|)(?: (.+)|)$/) {
      my $key = $1;
      my $n1 = $2;
      my $n2 = $3;
      my $n3 = $4;
      my $v = $5;

      $Data->{eras}->{$key}->{6031} = $n1;
      $Data->{eras}->{$key}->{6032} = [$n2] if defined $n2;
      $Data->{eras}->{$key}->{6032} = [$n2, $n3] if defined $n3;
      next unless defined $v;
      for (split / /, $v) {
        if (/^(\p{Hiragana}+)$/) {
          push @{$Data->{eras}->{$key}->{6033} ||= []}, $1;
        } elsif (/^([A-Za-z_^~-]+)$/) {
          push @{$Data->{eras}->{$key}->{6034} ||= []}, latin $1;
        } elsif (/^!(\p{Hiragana}+)$/) {
          push @{$Data->{eras}->{$key}->{6035} ||= []}, $1;
        } elsif (/^!([A-Za-z_^~-]+)$/) {
          push @{$Data->{eras}->{$key}->{6036} ||= []}, latin $1;
        } else {
          die "Bad value |$_|";
        }
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $RootPath->child ('src/era-yomi-6041.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+)( .+)$/) {
      my $key = $1;
      my $v = $2;
      while ($v =~ s/^ (\p{Hiragana}+)//o) {
        my $n1 = $1;
        push @{$Data->{eras}->{$key}->{6041} ||= []}, $n1;
      }
      while ($v =~ s/^ (G|A|NK|NY|K)//o) {
        my $id = {
          G => 6042,
          A => 6043,
          NK => 6044,
          NY => 6045,
          K => 6046,
        }->{$1} || die;
        while ($v =~ s/^ (\p{Hiragana}+)//o) {
          my $n2 = $1;
          push @{$Data->{eras}->{$key}->{$id} ||= []}, $n2;
        }
      }
      if (length $v) {
        die "Bad line |$_|";
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $RootPath->child ('src/era-yomi-6047.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+)( .+)$/) {
      my $key = $1;
      my $v = $2;
      while ($v =~ s/^ (\p{Hiragana}+)//o) {
        my $n1 = $1;
        push @{$Data->{eras}->{$key}->{6047} ||= []}, $n1;
      }
      while ($v =~ s/^ (\@)//o) {
        while ($v =~ s/^ (\p{Hiragana}+)//o) {
          my $n2 = $1;
          push @{$Data->{eras}->{$key}->{6048} ||= []}, $n2;
        }
      }
      if (length $v) {
        die "Bad line |$_|";
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path = $RootPath->child ('src/era-yomi-6049.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+)( .+)$/) {
      my $key = $1;
      my $v = $2;
      while ($v =~ s/^ (\p{Hiragana}+)//o) {
        my $n1 = $1;
        push @{$Data->{eras}->{$key}->{6049} ||= []}, $n1;
      }
      while ($v =~ s/^ ([A-Z]+)//o) {
        my $n2 = ucfirst lc $1;
        push @{$Data->{eras}->{$key}->{6050} ||= []}, $n2;
      }
      if (length $v) {
        die "Bad line |$_|";
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for my $id (6051) {
  my $path = $RootPath->child ('src/era-yomi-'.$id.'.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(.+) (\w+) (\p{Hiragana}+)$/) {
      my $key = $2;
      my $n2 = $3;
      for (grep { length } split / /, $1) {
        my $n1 = $_;
        $n1 =~ s/_/ /g;
        push @{$Data->{eras}->{$key}->{$id} ||= []}, $n1;
      }
      push @{$Data->{eras}->{$key}->{$id+1} ||= []}, $n2;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for my $id (6040, 6071..6084) {
  my $path = $RootPath->child ('src/era-yomi-'.$id.'.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+)((?: (?:\p{Hiragana}+|[\p{Latin}'-]+))+)$/) {
      my $key = $1;
      for (grep { length } split / /, $2) {
        push @{$Data->{eras}->{$key}->{$id} ||= []}, $_;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for my $id (6090..6091) {
  my $path = $RootPath->child ('src/era-yomi-'.$id.'.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(.+) (\w+)$/) {
      my $key = $2;
      for (grep { length } split / /, $1) {
        my $n1 = $_;
        $n1 =~ s/_/ /g;
        push @{$Data->{eras}->{$key}->{$id} ||= []}, $n1;
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
  my $path1 = $RootPath->child ('local/cldr-core-json/ja.json');
  my $path2 = $RootPath->child ('local/cldr-core-json/root.json');
  my $json1 = json_bytes2perl $path1->slurp;
  my $json2 = json_bytes2perl $path2->slurp;
  for (0..$#{$json2->{"dates_calendar_japanese_era"}}) {
    my $key = $json1->{"dates_calendar_japanese_era"}->[$_];
    my $latn = $json2->{"dates_calendar_japanese_era"}->[$_];
    $latn =~ s/\s+\(.+\)$//g;
    $Data->{eras}->{$key}->{6060} = $latn;
  }
  ## Wrong: "Meitoku (1384–1387)"
}

{
  my $path = $RootPath->child ('src/era-yomi-6100.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\w+) (.+)$/) {
      my $key = $1;
      my $v = $2;
      for (split / /, $v, -1) {
        if (/^\p{Hiragana}+$/) {
          push @{$Data->{eras}->{$key}->{6103} ||= []}, $_;
          next;
        }
        
        my ($new, $old, @others) = split /,/, $_, -1;
        s/\|/ /g for grep { defined } ($new, $old, @others);
        if (length $new) {
          push @{$Data->{eras}->{$key}->{6100} ||= []}, $new;
        }
        if (defined $old and length $old) {
          push @{$Data->{eras}->{$key}->{6101} ||= []}, $old;
        }
        for (@others) {
          push @{$Data->{eras}->{$key}->{6102} ||= []}, $_;
        }
      }
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
