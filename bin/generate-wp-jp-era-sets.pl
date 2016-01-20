use strict;
use warnings;
use utf8;
use JSON::PS;
use Path::Tiny;
binmode STDOUT, q{:encoding(utf-8)};

my $root_path = path (__FILE__)->parent->parent;

my $json_path = $root_path->child ('src/wp-jp-eras.json');
my $json = json_bytes2perl $json_path->slurp;

my $north = {map { $_ => 1 } qw(
暦応 康永 貞和 観応 文和 延文 康安 貞治 応安 永和 康暦 永徳 至徳 嘉慶 康応 明徳
)};
my $south = {map { $_ => 1 } qw(
延元 興国 正平 建徳 文中 天授 弘和 元中
)};

my $sets = {};
for (values %$json) {
  if ($_->{name} eq '正慶') {
    push @{$sets->{north0} ||= []}, [$_->{start}, $_->{name}];
  } elsif ($_->{name} eq '元弘') {
    push @{$sets->{south0} ||= []}, [$_->{start}, $_->{name}];
  } elsif ($south->{$_->{name}}) {
    push @{$sets->{south} ||= []}, [$_->{start}, $_->{name}];
  } elsif ($north->{$_->{name}}) {
    push @{$sets->{north} ||= []}, [$_->{start}, $_->{name}];
  } else {
    push @{$sets->{other} ||= []}, [$_->{start}, $_->{name}];
  }
}

for my $name (sort { $a cmp $b } keys %$sets) {
  print qq{\$jp-$name:\n};
  for (sort { $a->[0] cmp $b->[0] } @{$sets->{$name}}) {
    print qq{g:$_->[0] $_->[1]\n};
  }
  print qq{\n};
}

## License: Public Domain.
