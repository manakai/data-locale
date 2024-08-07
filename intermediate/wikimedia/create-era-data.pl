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
  $Prefix2 = q{漢} if
      $Data->{source_type} eq 'table5' or
      $Data->{source_type} eq 'table6' or
      $Data->{source_type} eq 'table7' or
      $Data->{source_type} eq 'table8' or
      $Data->{source_type} eq 'table9';
  $Prefix2 = '' if
      $Data->{source_type} eq 'k3' or
      $Data->{source_type} eq 'kourai';
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
    #warn "XXX" if $year == 1-104;
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
    清 => '清 (漢土)',
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

  $key = '百済武王' if $key eq '武王' and $country eq '百済';
  $key = '百済惠王' if $key eq '惠王' and $country eq '百済';
  $key = '景德王' if $key eq '景泰王';

  if ($country eq '高麗') {
    for (qw(太祖 光宗 仁宗 宣宗 神宗 高宗 定宗 肅宗)) {
      $key = $country . $_ if $key eq $_;
    }
  }

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
    table6 => {
      魯 => 1,
    },
    table7 => {
      山陽 => 1,
      沛 => 1,
      隆慮 => 1,
      魏其 => 1,
    },
    table8 => {
      壯 => 1,
      平州 => 1,
      昌武 => 1,
      涅陽 => 1,
      翕 => 1,
    },
    table9 => {
      博陽 => 1,
      土軍 => 1,
      安陽 => 1,
      宜春 => 1,
      將梁 => 1,
      平 => 1,
      廣川 => 1,
      廣陵 => 1,
      建成 => 1,
      彭 => 1,
      昌 => 1,
      易 => 1,
      易 => 1,
      朸 => 1,
      東城 => 1,
      東平 => 1,
      栒 => 1,
      海常 => 1,
      祝茲 => 1,
      缾 => 1,
      魏其 => 1,
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
    if ($Data->{source_type} eq 'table5') {
      #print qq{\n%tag   isa 漢諸侯国\n};
    }
    if ($Data->{source_type} eq 'table6' or
        $Data->{source_type} eq 'table7' or
        $Data->{source_type} eq 'table8' or
        $Data->{source_type} eq 'table9') {
      #print qq{\n%tag   isa 漢列侯国\n};
    }
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
} else {
  for (-205..-194) {
    $YearToKan->{$_} = '漢';
  }
  for (-193..-187) {
    $YearToKan->{$_} = '恵帝';
  }
  for (-186..-179) {
    $YearToKan->{$_} = '呂后';
  }
  for (-178..-163) {
    $YearToKan->{$_} = '漢文帝前';
  }
  for (-162..-156) {
    $YearToKan->{$_} = '漢文帝後';
  }
  for (-155..-149) {
    $YearToKan->{$_} = '漢景帝前';
  }
  for (-148..-143) {
    $YearToKan->{$_} = '漢景帝中';
  }
  for (-142..-140) {
    $YearToKan->{$_} = '漢景帝後';
  }
  for (-139..-134) {
    $YearToKan->{$_} = '建元';
  }
  for (-133..-128) {
    $YearToKan->{$_} = '元光';
  }
  for (-127..-122) {
    $YearToKan->{$_} = '元朔';
  }
  for (-121..-116) {
    $YearToKan->{$_} = '元狩';
  }
  for (-115..-110) {
    $YearToKan->{$_} = '元鼎';
  }
  for (-109..-104) {
    $YearToKan->{$_} = '元封';
  }
  for (-103..-96) {
    $YearToKan->{$_} = '太初';
  }
  for (-95..-92) {
    $YearToKan->{$_} = '太始';
  }
  for (-91..-88) {
    $YearToKan->{$_} = '征和';
  }
  for (-87..0) {
    $YearToKan->{$_} = '後元';
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

  if ($person eq '貞定王') {
    print q{
name country monarch
name 周貞定王
&
    };
  }

  if ($Data->{source_type} eq 'k3') {
    printf q{
+name era %s
    }, $key
        unless {
          朴赫居世居西干 => 1,
          南觧次次雄 => 1,
          儒理尼師今 => 1,
          脫觧尼師今 => 1,
          婆娑尼師今 => 1,
          祇摩尼師今 => 1,
          逸聖尼師今 => 1,
          阿達羅尼師今 => 1,
          伐休尼師今 => 1,
          奈觧尼師今 => 1,
          助賁尼師今 => 1,
          沾解尼師今 => 1,
          味鄒尼師今 => 1,
          儒禮尼師今 => 1,
          基臨尼師今 => 1,
          訖觧尼師今 => 1,
          奈勿尼師今 => 1,
          實聖尼師今 => 1,
          訥祗麻立干 => 1,
          慈悲麻立干 => 1,
          炤知麻立干 => 1,
          智證麻立干王 => 1,
          法興王 => 1,
          真興王 => 1,
          真智王 => 1,
          真平王 => 1,
          善德王 => 1,
          真德王 => 1,
          太宗王 => 1,
          文武王 => 1,
          神文王 => 1,
          孝昭王 => 1,
          聖德王 => 1,
          孝成王 => 1,
          景德王 => 1,
          景泰王 => 1,
          惠恭王 => 1,
          宣德王 => 1,
          元聖王 => 1,
          昭聖王 => 1,
          哀莊王 => 1,
          憲德王 => 1,
          興德王 => 1,
          僖康王 => 1,
          閔哀王 => 1,
          #
          文聖王 => 1,
          憲安王 => 1,
          景文王 => 1,
          憲康王 => 1,
          定康王 => 1,
          真聖王 => 1,
          孝恭王 => 1,
          神德王 => 1,
          景明王 => 1,
          景哀王 => 1,
          敬順王 => 1,

          東明聖王 => 1,
          瑠璃明王 => 1,
          太武神王 => 1,
          閔中王 => 1,
          慕本王 => 1,
          國祖王 => 1,
          次大王 => 1,
          新大王 => 1,
          故國川責王 => 1,
          山上王 => 1,
          東川王 => 1,
          中川王 => 1,
          西川王 => 1,
          峰上王 => 1,
          羙川王 => 1,
          故國原王 => 1,
          小獸林王 => 1,
          故國壤王 => 1,
          廣開土王 => 1,
          長壽王 => 1,
          文咨明王 => 1,
          安藏王 => 1,
          安原王 => 1,
          陽原王 => 1,
          平原王 => 1,
          嬰陽王 => 1,
          榮留王 => 1,
          小獸林王 => 1,
          榮留王 => 1,
          平原王 => 1,
          寳藏王 => 1,
          
          溫祚王 => 1,
          多婁王 => 1,
          己婁王 => 1,
          蓋婁王 => 1,
          肖古王 => 1,
          仇首王 => 1,
          古厼王 => 1,
          責稽王 => 1,
          汾西王 => 1,
          比流王 => 1,
          契王 => 1,
          近肖古王 => 1,
          近仇首王 => 1,
          枕流王 => 1,
          辰斯王 => 1,
          阿莘王 => 1,
          腆支王 => 1,
          乆厼辛王 => 1,
          毗有王 => 1,
          盖鹵王 => 1,
          文周王 => 1,
          三斤王 => 1,
          東城王 => 1,
          武寧王 => 1,
          聖王 => 1,
          威德王 => 1,
          惠王 => 1,
          百済惠王 => 1,
          法王 => 1,
          武王 => 1,
          百済武王 => 1,
          義慈王 => 1,

          甄萱 => 1,
        }->{$key};
  } else {
    printf q{
name %s monarch%s
name %s
    },
      (($data->{era_name} // $key) =~ /^\Q$data->{country}\E/ ? 'country' : ''),
      ((($data->{era_name} // $key) =~ /後$/ or $data->{re}) ? '+' : ''),
      $data->{era_name} // $key
      unless $key eq '始皇帝' or $key eq '二世';
  }
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
    if ($Data->{source_type} eq 'k3' or
        $Data->{source_type} eq 'kourai') {
      if ($data->{country} =~ /後|弓裔政権/) {
        push @tag, '朝鮮人';
      } else {
        push @tag, $data->{country} . '人';
      }
    } else {
      push @tag, '漢民族';
    }

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
    } elsif ($Data->{source_type} eq 'table6') {
      push @tag, '史記 高祖功臣侯者年表 第六';
      push @tag, '漢列侯即位紀年';
      push @tag, '前漢';
    } elsif ($Data->{source_type} eq 'table7') {
      push @tag, '史記 惠景閒矦者年表 第七';
      push @tag, '漢列侯即位紀年';
      push @tag, '前漢'; 
    } elsif ($Data->{source_type} eq 'table8') {
      push @tag, '史記 建元以來侯者年表 第八';
      push @tag, '漢列侯即位紀年';
      push @tag, '前漢';
    } elsif ($Data->{source_type} eq 'table9') {
      push @tag, '史記 建元以來王子侯者年表 第九';
      push @tag, '漢列侯即位紀年';
      push @tag, '前漢';
    } elsif ($Data->{source_type} eq 'k3') {
      if ($min <= 800) {
        push @tag, '朝鮮三国時代';
      } elsif (892 <= $max and $min <= 936) {
        push @tag, '後三国時代';
      }
      push @tag, '朝鮮王即位紀年';
      if ($data->{country} =~ /百済/) {
        push @tag, '三國史記 年表 百濟';
      } elsif ($data->{country} =~ /高句麗|弓裔/) {
        push @tag, '三國史記 年表 高句麗';
      } else {
        push @tag, '三國史記 年表 新羅';
      }
    } elsif ($Data->{source_type} eq 'kourai') {
      push @tag, '高麗史 年表 高麗';
      push @tag, '高麗王即位紀年';
    }
  }

  $pperson =~ s/後$//;
  $pperson = '秦惠文王' if $pperson eq '初更';
  push @tag, $pperson;
  for my $y (sort { $a <=> $b } keys %{$data->{prev} or {}}) {
    my $pk = $data->{prev}->{$y};
    use utf8;
    my @pk = ($pk eq '始皇帝' ? '秦始皇' : person $data->{country}, $pk);
    push @pk, '魯武公敖(丁丑)' if $key eq '魯懿公戲';
    push @pk, '趙王敖(庚子)' if $key eq '趙隱王如意';
    push @pk, '齊湣王地(辛酉)' if $key eq '齊襄王法章';
    push @pk, '宣王(乙亥)' if $key eq '幽王';
    push @pk, '姬猛' if $key eq '敬王';
    push @pk, '矦呂產' if $key eq '呂產';
    push @pk, '魏襄王(癸卯)' if $key eq '魏昭王';
    push @pk, '奈勿尼師今(乙卯)' if $key eq '實聖尼師今';
    push @pk, '神武王' if $key eq '文聖王';
    push @pk, '文咨明王(辛未)' if $pk[0] eq '文咨明王';
    push @pk, '顯宗(己酉)' if $pk[0] eq '顯宗';
    push @pk, '高麗光宗(己酉)' if $pk[0] eq '高麗光宗' ;
    push @pk, '高麗宣宗(癸亥)' if $pk[0] eq '高麗宣宗';
    push @pk, '高麗仁宗(壬寅)' if $pk[0] eq '高麗仁宗';
    push @pk, '高麗高宗(癸酉)' if $pk[0] eq '高麗高宗';
    push @pk, '忠烈王(甲戌)' if $pk[0] eq '忠烈王';
    push @pk, '恭愍王(辛卯)' if $pk[0] eq '恭愍王';
    push @pk, '辛禑(甲寅)' if $pk[0] eq '辛禑';
    push @pk, '威德王(乙亥)' if $pk[0] eq '百済惠王';
    #push @pk, $data->{prev_other} if defined $data->{prev_other};
    my $ctag = $Prefix2 . $data->{country};
    if ($ctag eq '春秋戦国齊') {
      if ($data->{offset} < -377) {
        $ctag = '姜斉';
      } else {
        $ctag = '田斉';
      }
    }
    my $date;
    my $cal =
        $Data->{source_type} eq 'kourai' ? '高麗' :
        $Data->{source_type} eq 'k3' ? '新羅' : '史記';
    if (defined $data->{start_day}) {
      if (defined $data->{start_day}->[2]) {
        $date = sprintf '%s:%d-%d%s-%s',
            $cal,
            $y,
            $data->{start_day}->[0],
            $data->{start_day}->[1] ? "'" : '',
            $data->{start_day}->[2];
      } else {
        $date = sprintf '[%s:%d-%d%s]',
            $cal,
            $y,
            $data->{start_day}->[0],
            $data->{start_day}->[1] ? "'" : '';
      }
    } else {
      $date = sprintf '[%s:%d]', $cal, $y;
    }
    my $prev_data = $Data->{eras}->{$pk[0]};
    if (defined $prev_data and
        defined $prev_data->{abdication} and
        $y == $prev_data->{abdication}) {
      printf q{
<-%s [%s:%d] #改元前の退位{#%s #%s #%s王} #三国史記
      },
          $pk[0],
          $cal, $prev_data->{abdication},
          $ctag,
          (person $prev_data->{country}, $pk[0]),
          $ctag;
    } elsif (defined $prev_data and
             defined $prev_data->{dead} and
             $y == $prev_data->{dead}) {
      printf q{
<-%s [%s:%d] #改元前の死去{#%s #%s} #三国史記
      },
          $pk[0],
          $cal, $prev_data->{dead},
          $ctag,
          (person $data->{country}, $pk[0]);
    }

    next if {
      文咨明王 => 1,

      味鄒尼師今 => 1,
      昭聖王 => 1,
    }->{$key};
    
    printf q{
<-%s %s #%s{#%s #%s%s} #%s %s
    },
        (join ',', @pk), 
        $date,
        ($Data->{source_type} eq 'k3' ? '建元前の即位' :
         $Data->{source_type} eq 'kourai' ? '高麗称元' : 
         $y == $data->{offset} + 1 ? $Prefix2 . '称元' : '利用開始'),
        $ctag,
        (person $data->{country}, $pperson),
        ($Data->{source_type} eq 'k3' ? ' #'.$data->{country}.'王' : ''),
        ($Data->{source_type} eq 'kourai' ? '高麗史' :
         $Data->{source_type} eq 'k3' ? '三国史記' :
         $Prefix2 eq '漢' ? '前漢' : '春秋戦国時代'),
        ($Prefix2 eq '漢' ? cal_tag ($y, $data->{start_day}) : $data->{country} eq '秦' ? '#秦正' : '');
    if ($key eq '齊威王因' or
        $key eq '威德王' or
        ($Data->{source_type} eq 'table3' and $key eq '惠王')) {
      print qq{  #旧説\n};
    }
    if ($data->{re}) {
      print qq{  #重祚\n};
    }
  } # $y
  if (($Data->{source_type} eq 'table5' or
       $Data->{source_type} eq 'table6' or
       $Data->{source_type} eq 'table7' or
       $Data->{source_type} eq 'table8' or
       $Data->{source_type} eq 'table9') and
      ($data->{first} or not keys %{$data->{prev} or {}})) {
    my $y = $data->{offset} + 1;
    my @pk;
    push @pk, $YearToKan->{$y} // die "No Kan era for year $y";
    push @pk, '項羽' if $key eq '楚王信';
    push @pk, '衡山王吳芮' if $key eq '長沙文王吳芮';
    push @pk, '大中大夫呂祿' if $key eq '趙王呂祿';
    push @pk, '侯劉濞' if $key eq '吳王濞';
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
    my $date;
    if (defined $data->{end_day}) {
      if (defined $data->{end_day}->[2]) {
        $date = sprintf '史記:%d-%d%s-%s',
            $y,
            $data->{end_day}->[0],
            $data->{end_day}->[1] ? "'" : '',
            $data->{end_day}->[2];
      } else {
        $date = sprintf '[史記:%d-%d%s]',
            $y,
            $data->{end_day}->[0],
            $data->{end_day}->[1] ? "'" : '';
      }
      if ($data->{end_day_open}) {
        $date = sprintf '[%s,史記:%d]',
            $date, $y;
      }
    } else {
      $date = sprintf '[史記:%d]', $y;
    }
    my $nk = $YearToKan->{$y} // die "No Kan era for year $y";
    printf q{
->%s %s #漢廃国{#%s%s} #前漢 %s
    },
        $nk,
        $date,
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
