use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

binmode STDOUT, qw(:encoding(utf-8));

my $Data;
my $Prefix2;
{
  local $/ = undef;
  $Data = json_bytes2perl scalar <>;

  $Prefix2 = q{春秋戦国};
}

sub country ($) {
  my $key = shift;
  return {
    晉 => '晋',
    吳 => '呉',
    齊 => '斉',
  }->{$key} || $key;
} # country

sub person ($$) {
  my ($country, $key) = @_;
  use utf8;
  $key = '楚武王' if $key eq '武王' and $country eq '楚';
  $key = '周定王' if $key eq '定王' and $country eq '周' and $Data->{source_type} eq 'table2';
  $key = '貞定王' if $key eq '定王' and $country eq '周' and $Data->{source_type} eq 'table3';
  $key = '魏惠王' if $key eq '惠王' and $country eq '魏';
  $key = '戦国燕文公' if $key eq '燕文公' and $country eq '燕' and $Data->{source_type} eq 'table3';
  $key = '戦国燕桓公' if $key eq '燕桓公' and $country eq '燕' and $Data->{source_type} eq 'table3';
  $key = '戦国秦惠公' if $key eq '秦惠公' and $country eq '秦' and $Data->{source_type} eq 'table3';

  $key = '秦二世' if $key eq '二世';

  return $key;
} # person

for my $key (sort { $a cmp $b } @{$Data->{countries}}) {
  next if {
    table2 => {
    },
    table3 => {
      周 => 1,
      楚 => 1,
      燕 => 1,
      秦 => 1,
      齊 => 1,
    },
  }->{$Data->{source_type}}->{$key};

  printf q{
%%tag country
%%tag   label %s%s
%%tag   &
%%tag   name %s
%%tag   period of %s
  }, $Prefix2, $key, $key, country ($key);

  print q{
%tag   group of 戦国七雄
  } if {
    韓 => 1, 趙 => 1, 魏 => 1, 楚 => 1, 燕 => 1, 斉 => 1, 齊 => 1,
    秦 => 1,
  }->{$key};
}

for (sort { $a cmp $b } keys %{$Data->{eras}}) {
  my $data = $Data->{eras}->{$_};
  my $key = $_;
  my $person = person $data->{country}, $key;

  my $min = $data->{min_year};
  my $max = $#{$data->{years}};
  if (defined $data->{dead_year}) {
    die if $data->{dead_year} < $max;
    $max = $data->{dead_year};
  }

  my $dup = ($Data->{source_type} eq 'table3' and {
    楚惠王章 => 1, 燕獻公 => 1, 齊平公驁 => 1,
  }->{$key});

  if ($dup) {
    printf qq{\n[%s]\n}, $person;
  } elsif ($person eq '始皇帝') {
    printf qq{\ndef[%s]\n}, '秦始皇';
  } else {
    printf qq{\ndef[%s]\n}, $person;
  }
  
  my @tag;
  printf q{
AD%d = 0
u %d
u %d
  }, $data->{offset}, $min, $max;

  my $pperson = $person;
  $pperson = '胡亥' if $pperson eq '秦二世';
  $person = $data->{name} if defined $data->{name};
  printf q{
%%tag person
%%tag   %s %s
  }, ($person =~ /^戦国/ ? 'label' : 'name'), $pperson
      if not $dup and not $pperson =~ /後$/ and not $pperson eq "初更";

  printf q{
name %s monarch%s
name %s
  },
      ($key =~ /^\Q$data->{country}\E/ ? 'country' : ''), (defined $data->{name} and $pperson =~ /後$/ ? '+' : ''),
      $key
      unless $key eq '始皇帝' or $key eq '二世';
  push @tag, '後元' if $pperson =~ /後$/;
  if (not $dup and not $key eq $person and not defined $data->{name}) {
    printf q{
%%tag   &
%%tag   name %s
    }, $key;
  }

  push @tag, $Prefix2 . $data->{country};
  
  {
    use utf8;
    push @tag, '漢民族';

    $min += $data->{offset};
    $max += $data->{offset};
    for (
      [1-771, 1-403, '春秋時代'],
      [1-481, 1-221, '支那戦国時代'],
      [1-1046, 1-771, '西周'],
      [1-771, 1-256, '東周'],
    ) {
      if ($_->[0] <= $max and $min <= $_->[1]) {
        push @tag, $_->[2];
      }
    }
    if ($Data->{source_type} eq 'table2') {
      push @tag, '史記 十二諸侯年表第二';
      printf q{
s#史記<%s>"%s"
s+
      }, q<https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E5%8D%B7014>,
          $key;
      if ($data->{country} eq '周') {
        push @tag, '周王即位紀年';
        push @tag, '十二諸侯年表即位紀年';
      } else {
        push @tag, '十二諸侯即位紀年';
      }
    } elsif ($Data->{source_type} eq 'table3') {
      push @tag, '史記 六國年表第三';
      printf q{
s#史記<%s>"%s"
s+
      }, q<https://zh.wikisource.org/wiki/%E5%8F%B2%E8%A8%98/%E5%8D%B7015>,
          $key;
      if ($data->{country} eq '周') {
        push @tag, '周王即位紀年';
        push @tag, '六国年表即位紀年';
      } else {
        push @tag, '六国年表即位紀年';
      }
    }
  }

  $pperson =~ s/後$//;
  $pperson = '秦惠文王' if $pperson eq '初更';
  push @tag, $pperson;
  for my $y (sort { $a <=> $b } keys %{$data->{prev} or {}}) {
    my $pk = $data->{prev}->{$y};
    use utf8;
    printf q{
<-%s [史記:%d] #%s{#%s #%s} #春秋戦国時代
    },
        ($pk eq '始皇帝' ? '秦始皇' : person $data->{country}, $pk), $y,
        ($y == $data->{offset} + 1 ? $Prefix2 . '称元' : '利用開始'),
        $Prefix2 . $data->{country},
        person $data->{country}, $pperson;
  }
  unless (keys %{$data->{prev} or {}}) {
    $key =~ s/後$//;
    printf q{
tag+country %s
tag+monarch %s
    }, $Prefix2 . $data->{country}, $key;
  }
  print "\n";
  for (@tag) {
    print "tag $_\n";
  }
}

## License: Public Domain.
