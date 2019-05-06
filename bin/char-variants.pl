use strict;
use warnings;
use Path::Tiny;
use JSON::PS;

my $RootPath = path (__FILE__)->parent->parent;
my $Data = {};

sub add ($$) {
  my ($x, $y) = @_;
  if (defined $Data->{groups}->{$x} and defined $Data->{groups}->{$y}) {
    if ($Data->{groups}->{$x} eq $Data->{groups}->{$y}) {
      # nothing to do
    } else {
      for my $xv (@{$Data->{groups}->{$x}}) {
        push @{$Data->{groups}->{$y}}, $xv;
        $Data->{groups}->{$xv} = $Data->{groups}->{$y};
      }
    }
  } elsif (defined $Data->{groups}->{$x}) {
    push @{$Data->{groups}->{$y} = $Data->{groups}->{$x}}, $y;
  } elsif (defined $Data->{groups}->{$y}) {
    push @{$Data->{groups}->{$x} = $Data->{groups}->{$y}}, $x;
  } else {
    $Data->{groups}->{$x} = $Data->{groups}->{$y} = [$x, $y];
  }
} # add

{
  my $path = $RootPath->child ('local/chars-maps.json');
  my $json = json_bytes2perl $path->slurp;
  my $map = $json->{maps}->{'unicode:compat_decomposition'};
  for (keys %{$map->{char_to_char}}) {
    my $from = hex $_;
    if ((0xF900 <= $from and $from <= 0xFAFF) or # CJK COMPATIBILITY IDEOGRAPHS
        (0x2F800 <= $from and $from <= 0x2FA1F)) { # CJK COMPATIBILITY IDEOGRAPHS SUPPLEMENT
      my $to = hex $map->{char_to_char}->{$_};
      add chr $from, chr $to;
    }
  }
}

{
  my $path = $RootPath->child ('src/char-variants.txt');
  for (split /\n/, $path->slurp_utf8) {
    my @char = split /\s+/, $_;
    @char = map { s/^j://; $_ } @char;
    for my $c2 (@char) {
      for my $c1 (@char) {
        add $c1, $c2;
      }
    }
  }
}

## <https://www.meti.go.jp/policy/it_policy/kaigen/faq.html>
add "\x{4EE4}", "\x{4EE4}\x{E0101}";
add "\x{4EE4}", "\x{4EE4}\x{E0102}";

add "\x{4EE4}", "\x{4EE4}\x{FE00}";
add "\x{4EE4}", "\x{4EE4}\x{E0100}";

for my $chars (values %{$Data->{groups}}) {
  for my $c1 (@$chars) {
    for my $c2 (@$chars) {
      $Data->{variants}->{$c1}->{$c2} = 1;
    }
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
