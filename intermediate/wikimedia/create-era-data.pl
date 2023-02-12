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
  $Prefix2 = q{漢} if $Data->{source_type} eq 'table5';
}

sub cal_tag ($$) {
  my ($year, $date) = @_;

  if ($year < 1-104) {
    return '#秦正';
  }

  if ($year == 1-104 and
      defined $date and $date->[0] <= 9) {
    return '#秦正';
  } else {
    warn "XXX" if $year == 1-104;
  }

  return '';
} # cal_tag

sub country ($) {
  my $key = shift;
  return {
    晉 => '晋',
    吳 => '呉',
    齊 => '斉',
    山陽 => '山陽 (漢土)',
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

for my $key (sort { $a cmp $b } keys %{$Data->{countries}}) {
  next if {
    table2 => {
    },
    table3 => {
      周 => 1,
      楚 => 1,
      燕 => 1,
      秦 => 1,
      齊 => 1,
      宋 => 1,
      晉 => 1,
      蔡 => 1,
      衛 => 1,
      鄭 => 1,
      魯 => 1,
    },
    table5 => {
      漢 => 1,
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

  if ($Prefix2 eq '漢') {
    print qq{\n%tag   group of 漢諸侯国\n};
  }
}

my $YearToKan = {};
if ($Data->{source_type} eq 'table5') {
  for my $key (keys %{$Data->{eras}}) {
    my $data = $Data->{eras}->{$key};
    if (not defined $data->{country}) {
      warn perl2json_bytes_for_record $data;
    }
    if ($data->{country} eq '漢') {
      my $k = {
        漢王高祖 => '漢',
        漢王孝惠 => '恵帝',
        漢王高后 => '呂后',
        漢王孝文 => '漢文帝前',
        漢王孝文後 => '漢文帝後',
        漢王孝景 => '漢景帝前',
        漢王孝景中 => '漢景帝中',
        漢王孝景後 => '漢景帝後',
        漢王孝武建元 => '建元',
        漢王元狩 => '元狩',
        漢王元鼎 => '元鼎',
        漢王元朔 => '元朔',
        漢王元封 => '元封',
      }->{$key} // $key;
      for (1..$#{$data->{years}}) {
        $YearToKan->{$data->{years}->[$_]} = $k;
      }
    }
  }
}
for (sort { $a cmp $b } keys %{$Data->{eras}}) {
  my $data = $Data->{eras}->{$_};
  next if $Data->{source_type} eq 'table5' and $data->{country} eq '漢';
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
      if not $dup and not $pperson =~ /後$/ and not $pperson eq "初更" and
         not defined $data->{person};
  $pperson = $data->{person} if defined $data->{person};
  
  printf q{
name %s monarch%s
name %s
  },
      (($data->{era_name} // $key) =~ /^\Q$data->{country}\E/ ? 'country' : ''),
      (($data->{era_name} // $key) =~ /後$/ ? '+' : ''),
      $data->{era_name} // $key
      unless $key eq '始皇帝' or $key eq '二世';
  push @tag, '後元' if $pperson =~ /後$/;
  if (not $dup and not $key eq $person and not defined $data->{name} and
      not defined $data->{person}) {
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
    } elsif ($Data->{source_type} eq 'table5') {
      push @tag, '史記 漢興以來諸侯王年表 第五';
      push @tag, '漢諸侯王即位紀年';
      push @tag, '前漢';
    }
  }

  $pperson =~ s/後$//;
  $pperson = '秦惠文王' if $pperson eq '初更';
  push @tag, $pperson;
  for my $y (sort { $a <=> $b } keys %{$data->{prev} or {}}) {
    my $pk = $data->{prev}->{$y};
    use utf8;
    my @pk = ($pk eq '始皇帝' ? '秦始皇' : person $data->{country}, $pk);
    if ($pk eq '真公濞') {
      push @pk, '真公濞(丁未)';
    }
    #push @pk, $data->{prev_other} if defined $data->{prev_other};
    my $date;
    if (defined $data->{start_day}) {
      if (defined $data->{start_day}->[2]) {
        $date = sprintf '史記:%d-%d%s-%s',
            $y,
            $data->{start_day}->[0],
            $data->{start_day}->[1] ? "'" : '',
            $data->{start_day}->[2];
      } else {
        $date = sprintf '[史記:%d-%d%s]',
            $y,
            $data->{start_day}->[0],
            $data->{start_day}->[1] ? "'" : '';
      }
    } else {
      $date = sprintf '[史記:%d]', $y;
    }
    printf q{
<-%s %s #%s{#%s #%s} #%s %s
    },
        (join ',', @pk), 
        $date,
        ($y == $data->{offset} + 1 ? $Prefix2 . '称元' : '利用開始'),
        $Prefix2 . $data->{country},
        (person $data->{country}, $pperson),
        ($Prefix2 eq '漢' ? '前漢' : '春秋戦国時代'),
        ($Prefix2 eq '漢' ? cal_tag ($y, $data->{start_day}) : $data->{country} eq '秦' ? '#秦正' : '');
  } # $y
  if ($Data->{source_type} eq 'table5' and
      ($data->{first} or not keys %{$data->{prev} or {}})) {
    my $y = $data->{offset} + 1;
    my @pk;
    push @pk, $YearToKan->{$y} // die "No Kan era for year $y";
    push @pk, '項羽' if $key eq '楚王信';
    push @pk, '衡山王吳芮' if $key eq '長沙文王吳芮';
    my $date;
    if (defined $data->{start_day}) {
      if (defined $data->{start_day}->[2]) {
        $date = sprintf '史記:%d-%d%s-%s',
            $y,
            $data->{start_day}->[0],
            $data->{start_day}->[1] ? "'" : '',
            $data->{start_day}->[2];
      } else {
        $date = sprintf '[史記:%d-%d%s]',
            $y,
            $data->{start_day}->[0],
            $data->{start_day}->[1] ? "'" : '';
      }
    } else {
      $date = {
        趙王張耳 => "[史記:$y-11]",
        梁王彭越 => "[史記:$y-2]",
        趙王敖 => "[史記:$y-8]",
      }->{$key} || sprintf '[史記:%d]', $y;
    }
    printf q{
<-%s %s #漢初封称元{#%s #%s} #前漢 %s
    },
        (join ',', @pk),
        $date,
        $Prefix2 . ($data->{first_country} || $data->{country}),
        (person $data->{country}, $pperson),
        {
          趙王張耳 => '#子正',
        }->{$key} || cal_tag ($y, $data->{start_day});
    
  }
  if (defined $data->{prev_country}) {
    my @pk = ($data->{prev_key});
    printf q{
<-%s [史記:%d] #漢転封称元{#%s%s, #%s%s #%s} #前漢 %s
    },
        (join ',', @pk),
        $data->{offset} + 1,
        $Prefix2, $data->{prev_country},
        $Prefix2, $data->{country},
        (person $data->{country}, $pperson),
        cal_tag ($data->{offset} + 1, undef);
  }
  for my $cc (@{$data->{new_countries} or []}) {
    printf q{
&
%s%s [史記:%d] #%s{#%s%s, #%s%s #%s} #前漢 %s
tag+country %s%s
name %s
name %s
    },
        (defined $cc->{prev} ? '<-' : '><'),
        $cc->{prev} // '',
        $cc->{year},
        (defined $cc->{prev} ? '漢転封利用開始' : '漢転封'),
        $Prefix2, $cc->{prev_country},
        $Prefix2, $cc->{country},
        (person $data->{country}, $pperson),
        cal_tag ($cc->{year}, undef),

        $Prefix2, $cc->{country},

        ($cc->{name} =~ /^\Q$cc->{country}\E(.?)/ ? 'country' . ($1 ? ' monarch' : '') : 'monarch'),
        $cc->{name};
    push @tag, $Prefix2 . $cc->{prev_country};
  }
  if (defined $data->{end_year}) {
    my $y = $data->{end_year};
    my $nk = $YearToKan->{$y} // die "No Kan era for year $y";
    printf q{
->%s [史記:%d] #漢廃国{#%s%s} #前漢 %s
    },
        $nk,
        $y,
        $Prefix2, $data->{country},
        cal_tag ($y, undef);
  }
  for my $nn (@{$data->{names} or []}) {
    printf q{
%%tag   &
tag+country %s%s
#name monarch
%%tag   name %s
    }, $Prefix2, $nn->{country}, $nn->{king_name};
  }
  unless (keys %{$data->{prev} or {}}) {
    $key =~ s/後$//;
    printf q{
tag+country %s
tag+monarch %s
    }, $Prefix2 . $data->{country}, $pperson;
  }
  print "\n";
  for (@tag) {
    print "tag $_\n";
  }
}

## License: Public Domain.
