use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;
use Web::Encoding;

my $Data = {};

my $In;
{
  local $/ = undef;
  $In = json_bytes2perl scalar <>;
  $Data->{source_type} = $In->{source_type};
}

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

sub get_year ($$$) {
  my ($i, $en, $n) = @_;
  my $year1 = do {
    if ($Data->{source_type} eq 'table8' or
        $Data->{source_type} eq 'table9') {
      if ($i == 0 and $en eq '') {
        -133;
      } elsif ($i == 1 and $en eq '') {
        -127;
      } elsif ($i == 2 and $en eq '') {
        -121;
      } elsif ($i == 2 and $en eq '元狩') {
        -121;
      } elsif ($i == 3 and $en eq '') {
        -115;
      } elsif ($i == 4 and $en eq '') {
        -109;
      } elsif ($i == 5 and $en eq '') {
        -103;
      } elsif ($i == 5 and $en eq '太初') {
        -103;
      } elsif ($i == 5 and $en eq '征和') {
        -91;
      } else {
        die "Bad era ($i, $en)";
      }
    } else {
      if ($i == 0 and $en eq '') {
        -205;
      } elsif ($i == 1 and $en eq '') {
        -193;
      } elsif ($i == 1 and $en eq '孝惠') {
        -193;
      } elsif ($i == 2 and $en eq '') {
        -186;
      } elsif ($i == 3 and $en eq '') {
        -178;
      } elsif ($i == 3 and $en eq '前') {
        -178;
      } elsif ($i == 3 and $en eq '後') {
        -162;
      } elsif ($i == 4 and $en eq '') {
        -155;
      } elsif ($i == 4 and $en eq '前') {
        -155;
      } elsif ($i == 4 and $en eq '中') {
        -148;
      } elsif ($i == 4 and $en eq '後') {
        -142;
      } elsif ($i == 5 and $en eq '') {
        -139;
      } elsif ($en eq '建元') {
        -139;
      } elsif ($en eq '元光') {
        -133;
      } elsif ($en eq '元朔') {
        -127;
      } elsif ($en eq '元狩') {
        -121;
      } elsif ($en eq '元鼎') {
        -115;
      } elsif ($en eq '元封') {
        -109;
      } elsif ($en eq '太初') {
        -103;
      } elsif ($en eq '太始') {
        -95;
      } elsif ($en eq '征和') {
        -91;
      } elsif ($en eq '後元') {
        -87;
      } else {
        die "Bad era ($i, $en)";
      }
    }
  };
  return $year1 + $n - 1;
} # get_year

shift @{$In->{rows}};
for my $row (@{$In->{rows}}) {
  next unless @$row;

  my $country_cell = shift @$row;
  my $country;
  if ($country_cell =~ m{^(\p{sc=Han}+)。*$}) {
    $country = $1;
  } elsif ($country_cell eq '平陸。平陸。') {
    $country = '平陸';
  } else {
    die "Bad country cell |$country_cell|";
  }

  shift @$row;

  unshift @$row, '' if $Data->{source_type} eq 'table7';
  pop @$row if $Data->{source_type} eq 'table6';
  
  my $current;
  for my $i (0..5) {
    my $cell = $row->[$i];

    $cell =~ s/。。元年/元年/;
    $cell =~ s/矦公孫昆。。邪元年/矦公孫昆邪元年/;
    $cell =~ s/侯張阍。。歸義元年/侯張阍歸義元年/;
    $cell =~ s/四年君買元年/四年，君買元年/;
    $cell =~ s/([侯矦]\p{sc=Han}{1,3})。(元年)/$1$2/;
    $cell =~ s/(三年，侯纏卒)。(.+?國除)/$1$2/;
    $cell =~ s/其三年，爲太尉；(七年，)爲丞相。(有罪，國除)/$1$2/;
    $cell =~ s/元光二年，封嬰孫賢爲臨汝侯。侯賢元年/元光二年，侯賢元年/;
    $cell =~ s/(後元年，侯武薨)。(嗣子奇反，不得置後，國除)/$1$2/;
    $cell =~ s/元年閏月/元年閏八月/; # 元封1 -109
    $cell =~ s/，。。國除/，國除/;
    $cell =~ s/，。/，/;
    $cell =~ s/(元朔六年，侯申坐尚南宮公主)。。(不敬，國除)/$1$2/;
    $cell =~ s/^一八/一。八/;
    $cell =~ s/殤侯程嗣。薨/殤侯程嗣，薨/;
    $cell =~ s/(莊侯)。。(\p{sc=Han}+元年)/$1$2/;
    $cell =~ s/($Num)(年)(侯\p{sc=Han}+元年)/$1$2，$3/go;
    my $count = 0;
    my $first = 1;
    for my $s (split /。/, $cell) {
      if ($s =~ /^(前|中|後|元\p{sc=Han}|建元|孝惠|建元|太初|)($Num|元)年(?:，?(後|閏|)($MonthNum)月($Kanshi|)|中|)，(?:同有罪，封|復封；|)(\p{sc=Han}+)元年$/) {
        my $en = $1;
        my $y = parse_number $2;
        my $lm = $3;
        my $m = defined $4 ? parse_number $4 : undef;
        my $k = $5 || undef;
        my $name = $6;
        $name =~ s/^封\p{sc=Han}+[弟子孫]//;
        my $re = $name =~ s/^復封//;

        my $key = $name;
        $key = '復封' . $key if $re;
        my $data = {};
        if (defined $Data->{eras}->{$key} or
            ($Data->{source_type} eq 'table8' and
             ($key eq '侯勝' or $key eq '侯廣德' or $key eq '侯建德' or
              $key eq '侯德')) or
             ($Data->{source_type} eq 'table9' and
              ($key eq '侯劉信' or $key eq '侯劉福' or $key eq '侯始' or
               $key eq '侯德' or $key eq '侯成' or $key eq '侯昭' or
               $key eq '侯福'))) {
          $data->{era_name} = $key;
          $key = $country . $key;
          if (defined $Data->{eras}->{$key}) {
            die $key;
          }
        }
        $Data->{eras}->{$key} = $data;
        $data->{key} = $key;
        $data->{country} = $country;
        my $name0 = $name;
        $name = {
          將夜 => '齊侯趙將夜',
          恭侯捷 => '侯捷',
          節侯澤 => '侯澤',
          大中大夫呂祿 => '趙王呂祿',
          侯劉濞 => '吳王濞',
          矦呂產 => '呂產',
        }->{$name} || $name;
        $data->{person} = $name if ($re and not $name eq '翳子彊侯郢人') or not ($name eq $name0);
        $data->{name} = $name if $re and $name eq '翳子彊侯郢人';
        $data->{re} = 1 if $re;

        my $year = get_year $i, $en, $y;
        $data->{offset} = $year - 1;
        $data->{min_year} = 1;
        $data->{years}->[1] = $year;
        if (defined $k) {
          $data->{start_day} = [$m, $lm, $k];
        } elsif (defined $m) {
          $data->{start_day} = [$m, $lm, undef];
        }

        if (defined $current) {
          $data->{prev}->{$year} = $current->{key};
        } else {
          $data->{first} = 1;
        }
        $current = $data;

      } elsif ($s =~ /^至?(前|中|後|後元|征和|太初|元\p{sc=Han}|建元|)($Num|元)年(?:，?($MonthNum)月(?:($Kanshi)|)|)(?:\p{sc=Han}+薨|)，(.+)(?:國除|絕|免|爲關內侯|無嗣|不得及嗣|絕，七歲)$/o) {
        my $en = $1;
        my $y = parse_number $2;
        my $m = defined $3 ? parse_number $3 : undef;
        my $k = $4;
        my $t = $5;

        my $year = get_year $i, $en, $y;
        $current->{end_year} = $year;
        $current->{end_day} = [$m, 0, $k] if defined $m;
        undef $current;
        
        #if ($t =~ /祿爲趙王/) {
        #  
        #}
        #六年七月壬辰，產爲呂王，國除。
      } elsif ($s eq '太始四年五月丁卯，侯石坐爲太常，行太僕事，治嗇夫可年，益縱年，國除') {
        my $year = get_year 5, '太始', 4;
        $current->{end_year} = $year;
        $current->{end_day} = [5, 0, '丁卯'];
        undef $current;
      } elsif ($s =~ /^至?(前|中|後|元\p{sc=Han}|)($Num)年，復封(始)$/o) {
        #
      } elsif ($s =~ /^(\p{sc=Han}+)($Num)$/o) {
        $count += parse_number $2;
      } elsif ($s =~ /^($Num)$/o) {
        $count += parse_number $1;
        if (defined $current and $first and not $cell =~ /^$Num。元年/) {
          my $year = get_year $i, '', $count;
          $current->{years}->[$year - $current->{offset}] = $year;
        }
      } elsif ($s eq '有罪，絕' or $s eq '有罪，除' or $s eq '中絕' or
               $s eq '有罪' or
               $s eq '有罪，絕，國除' or $s eq '不得隆彊嗣' or
               $s eq '奪，絕' or $s eq '罪，絕' or $s eq '罪絕' or
               $s eq '薨，無後，國除' or $s eq '薨，無後，絕' or $s eq '絕' or
               $s eq '信平薨，子偃爲魯王，國除') {
        my $year = get_year $i, '', $count;
        $current->{end_year} = $year;
        undef $current;
      } elsif ($s eq '三年復封，一年絕') {
        #
      } elsif ($s eq '二年，復封襄') {
        #
      } elsif ($s =~ /^十年，八月，豨以趙相國將兵守代$/) {
        my $year = get_year $i, '', 10;
        $current->{end_year} = $year;
        $current->{end_day} = [8, 0, undef];
        undef $current;
      } elsif ($s eq '漢使召豨，豨反，以其兵與王黃等略代，自立爲王' or
               $s eq '漢殺豨靈丘') {
        #
      } elsif ($s =~ /^孝景五年，侯穀嗣$/) {
        my $year = get_year $i, '', 5;
        $current->{years}->[$year - $current->{offset}] = $year;
        undef $current;
      } elsif ($s =~ /^中五年，矦布薨$/) {
        my $year = get_year $i, '中', 5;
        $current->{years}->[$year - $current->{offset}] = $year;
        undef $current; 
      } elsif ($s eq '坐呂氏事誅，國除') {
        my $year = get_year $i, '', 8;
        $current->{end_year} = $year;
        $current->{end_day} = [5, 0, '丙辰'];
        $current->{end_day_open} = 1;
        undef $current;
      } elsif ($s eq '九月，奪矦，國除') {
        my $year = get_year $i, '', 8;
        $current->{end_year} = $year;
        $current->{end_day} = [9, 0, undef];
        undef $current;
      } elsif ($s eq '五月，卒，無後，國除') {
        my $year = get_year $i, '', 3;
        $current->{end_year} = $year;
        $current->{end_day} = [5, 0, undef];
        undef $current;
      } elsif ($s =~ /^中二年，封昌孫左車$/) {
        #
      } elsif ($s eq '惞薨，子昌代') {
        #
      } elsif ($s eq '三年，復封溫如故' or
               $s eq '二年，復封') {
        #
      } elsif ($s eq '仲子濞，爲吳王') {
        #
      } elsif ($s =~ /^孝文時坐後父故奪爵級，關內矦$/) {
        #
      } elsif ($s =~ /^三年，矦富以兄子戎爲楚王反，富與家屬至長安北闕自歸，不能相教，上印綬$/ or
               $s eq '詔復王' or
               $s eq '後以平陸矦爲楚王，更封富爲紅矦') {
        #
      } elsif ($s =~ /^其/ or
               $s =~ /^追尊/ or
               $s =~ /^祿以趙王/ or
               $s =~ /^賜姓/ or
               $s =~ /^($Num|元)年，爲/o or
               $s eq '同，祿弟' or
               $s eq '呂須子' or
               $s eq '不得，千秋父' or
               $s eq '太僕賀父' or
               $s eq '復爲丞相' or
               $s eq '坐呂氏誅，族' or
               $s eq '孝景三年，昭以故芒侯將兵從太尉亞夫擊吳楚有功，復侯' or
               $s eq '發婁' or
               $s eq '定侯安國' or
               $s eq '十二年十月乙未，定蒯成' or
               $s eq '五歲罷' or
               $s eq '以子吳王故，尊仲謚爲代頃侯' or
               $s eq '繩' or
               $s eq '侯平嗣，不得元' or
               $s eq '皆失謚' or
               $s eq '景帝時，爲丞相' or
               $s eq '元年，以故魯王爲南宮侯' or
               $s eq '八年九月，產以呂王爲漢相，謀爲不善' or
               $s eq '大臣誅產，遂滅諸呂' or
               $s eq '爲不其矦' or
               $s eq '建元元年爲丞相，二歲免' or
               $s eq '太初二年，無龍從浞野侯戰死' or
               $s eq '太初二年三月丁卯，封葛繹侯' or
               $s eq '二歲復侯' or
               $s eq '子曾復封為龍镪侯' or
               $s eq '封凡三月' or
               $s eq '侯郢客坐與人妻姦，棄市') {
        #
      } elsif ($s =~ /\S/) {
        die "Bad sentence |$s|";
      }
      $first = 0;
    } # $s
  } # cell
}

for (values %{$Data->{eras}}) {
  $Data->{countries}->{$_->{country}} = 1;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
