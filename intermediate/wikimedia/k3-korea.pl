use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;

my $Num = qr{[一二三四亖五六七八九]十[一二三四亖五六七八九]?|十[一二三四亖五六七八九]|[一二三四亖五六七八九十]};
my $MonthNum = qr{[正一二三四亖五六七八九十]|十[一二]};
my $Kanshi = qr{(?!初)\p{sc=Han}{2}};
my $ToNumber = {
  一 => 1, 二 => 2, 三 => 3, 四 => 4, 五 => 5, 亖 => 4,
  六 => 6, 七 => 7, 八 => 8, 九 => 9, 十 => 10,
  '' => 0,
  正 => 1,
  元 => 1,
};
sub parse_number ($) {
  my $s = shift;
  if ($s =~ m{^([一二三四亖五六七八九])十([一二三四亖五六七八九]?)$}) {
    return $ToNumber->{$1} * 10 + $ToNumber->{$2};
  } elsif ($s =~ m{^十([一二三四亖五六七八九])$}) {
    return 10 + $ToNumber->{$1};
  } elsif ($s =~ m{^([正元一二三四亖五六七八九十])$}) {
    return $ToNumber->{$1};
  } else {
    die $s;
  }
} # parse_number

my $Data = {};
$Data->{source_type} = 'k3';

my $CurrentYear = 1 - 57;
my $PrevNames = [];
my $Currents = [];
my $Country2 = '高句麗';
my $Country3 = '百済';
sub read_table ($) {
  my $path = shift;
  my $json = json_bytes2perl $path->slurp;

  shift @{$json->{rows}}; # header
  for my $row (@{$json->{rows}}) {
    for (
      [2, '新羅'],
      [3, $Country2],
      [4, $Country3],
    ) {
      my ($i, $Country) = @$_;
      my $Name;
      my $This = $Currents->[$i];
      for (@{$row->[$i]}) {
        if (/^元年$/) {
          die $Name if $Data->{eras}->{$Name};
          $This = $Data->{eras}->{$Name} = {};
          $This->{min_year} = 1;
          $This->{offset} = $CurrentYear - 1;
          $This->{country} = $Country;
          $This->{years}->[1] = $CurrentYear;
          $This->{prev}->{$CurrentYear} = $PrevNames->[$i] if defined $PrevNames->[$i];
        } elsif (/^($Num)$/o) {
          my $n = parse_number $1;
          die "|$Name|, |$_| ($CurrentYear |@{$row->[0]}|)" if not defined $This;
          $This->{years}->[$n] = $CurrentYear;
        } elsif (/^始祖(東明聖王)姓高氏諱朱蒙即位$/) {
          $Name = $1;
          undef $This;
        } elsif (/^始祖(\p{sc=Han}+)即位$/) {
          $Name = $1;
          undef $This;
        } elsif (/^(\p{sc=Han}+王)(\p{sc=Han}+)即位$/) {
          $Name = $1;
          if ({
            孝成王 => 1,
            興德王 => 1,
          }->{$Name}) {
            die $Name if $Data->{eras}->{$Name};
            $This = $Data->{eras}->{$Name} = {};
            $This->{min_year} = 1;
            $This->{offset} = $CurrentYear - 1;
            $This->{country} = $Country;
            $This->{years}->[1] = $CurrentYear;
            $This->{prev}->{$CurrentYear} = $PrevNames->[$i] if defined $PrevNames->[$i];
          } else {
            undef $This;
          }
        } elsif (/^(\p{sc=Han}+)即位$/) {
          $Name = $1;
          $Name = {
            助負尼師今 => '助賁尼師今',
            沾觧尼師今 => '沾解尼師今',
          }->{$Name} || $Name;
          undef $This;
        } elsif (/^(\p{sc=Han}+王)(?!.位)(\p{sc=Han}+)$/) {
          $Name = $1;
          undef $This;
        } elsif (/^(甄萱)自稱王$/) {
          $Name = $1;
          die $Name if $Data->{eras}->{$Name};
          $This = $Data->{eras}->{$Name} = {};
          $This->{min_year} = 1;
          $This->{offset} = $CurrentYear - 1;
          $This->{country} = $Country;
          $This->{years}->[1] = $CurrentYear;
        } elsif (/^(弓裔)自稱王$/) {
          $Name = $1;
          $Country = $Country2 = '弓裔政権'; #後高句麗
          die $Name if $Data->{eras}->{$Name};
          $This = $Data->{eras}->{$Name} = {};
          $This->{min_year} = 1;
          $This->{offset} = $CurrentYear - 1;
          $This->{country} = $Country;
          $This->{years}->[1] = $CurrentYear;
        } elsif (/^始祖(\p{sc=Han}+)[薨夢]$/) {
          my $n = '朴'.$1.'居西干';
          unless ($Data->{eras}->{$n}) {
            die "Unknown name |$n|";
          }
          $Data->{eras}->{$n}->{dead} = $CurrentYear;
        } elsif (/^(\p{sc=Han}+)[薨夢]$/) {
          my $n = $1;
          $n = {
            婆沙尼師今 => '婆娑尼師今',
            阿達尼師今 => '阿達羅尼師今',
            #助賁尼師今 => '助負尼師今',
            #沽觧尼師今 => '沾觧尼師今',
            沽觧尼師今 => '沾解尼師今',
            智證麻立干 => '智證麻立干王',
          }->{$n} || $n;
          unless ($Data->{eras}->{$n}) {
            die "Unknown name |$n|";
          }
          $Data->{eras}->{$n}->{dead} = $CurrentYear;
        } elsif (/^(\p{sc=Han}+王)(?:遜位退居後宮|禪位)$/) {
          my $n = $1;
          unless ($Data->{eras}->{$n}) {
            die "Unknown name |$n|";
          }
          $Data->{eras}->{$n}->{abdication} = $CurrentYear;
        } elsif (/^長子沙伴王嗣位而幼少見廢$/) {

        } elsif (/^始稱(建元)元年$/) {
          push @{$Data->{new_era}}, {
            ad_year => $CurrentYear,
            era_name => $1,
            #era_id era_key
            #month
            text => $_,
            country => $Country,
          };
        } elsif (/^(?:改元|年號)(\p{sc=Han}{2,4})$/) {
          push @{$Data->{new_era}}, {
            ad_year => $CurrentYear,
            era_name => $1,
            #era_id era_key
            #month
            text => $_,
            country => $Country,
          };
        } elsif (/^改(武泰)為(聖冊)元年$/) {
          push @{$Data->{new_era}}, {
            ad_year => $CurrentYear,
            era_name => $2,
            prev_era_name => $1,
            #era_id era_key
            #month
            text => $_,
            country => $Country,
          };
        } elsif (/^始行中國正朔$/) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               country => $Country};
        } elsif (/^(\p{sc=Han}+)羅不行$/) {
          push @{$Data->{china_era}},
              {event => 'not_used', year => $CurrentYear,
               era_name => $1, country => $Country};
        } elsif (/^(\p{sc=Han}+)羅不行猶用(\p{sc=Han}+)$/) {
          push @{$Data->{china_era}},
              {event => 'not_used', year => $CurrentYear,
               era_name => $1, country => $Country,
               inuse_era_name => $2};
        } elsif (/^(二)月(二十二)日始為中國改年號改為(乾符)(二)年$/) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               era_name => $3, country => $Country,
               month => (parse_number $1),
               day => (parse_number $2),
               era_year => (parse_number $4)};
        } elsif (/^(五)月(二十五)日知中國改年號迺用(中和)(二)年$/) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               era_name => $3, country => $Country,
               month => (parse_number $1),
               day => (parse_number $2),
               era_year => (parse_number $4)};
        } elsif (/^(六)月知中國改年號廼為(光啓)(二)年$/) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               era_name => $2, country => $Country,
               month => (parse_number $1),
               era_year => (parse_number $3)};
        } elsif (/^知中國改年號廼為(景福)(二)年$/) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               era_name => $1, country => $Country,
               era_year => (parse_number $2)};
        } elsif (/^唐將蘇定邦與羅人討之王義慈降百濟三十一王六百七十八年而滅$/) {

        } elsif (/^甄萱子神劒囚父篡位自稱將軍甄萱出奔錦城投太祖$/) {

        } elsif (/^國號(\p{sc=Han}+)$/) {

        } elsif (/^改國號為(\p{sc=Han}+)$/) {

        } elsif (/^(後百濟)$/) {
          $Country = $Country3 = '後百済';
        } elsif (/^(?:從此至見豫為聖骨|東明王升遐|嬰留|從此臣下真骨|太宗|弓裔始起投賊|太子薨于後宮|弓裔都松嶽郡|弓裔移都鐵圓|大相為石船將軍)$/) {
          #
        } elsif (/\S/) {
          die "Bad line |$_|";
        }
      } # row
      $Currents->[$i] = $This;
      $PrevNames->[$i] = $Name if defined $Name;
    }
    $CurrentYear++;
  }
} # read_table

for (qw(k3table1.json k3table2.json k3table3.json)) {
  my $path = $ThisPath->child ($_);
  read_table $path;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
