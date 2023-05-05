use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $ThisPath = path (__FILE__)->parent;
my $Data = {};
$Data->{source_type} = 'kourai';

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

my $prev_name;
sub read_table ($) {
  my $path = shift;
  my $json = json_bytes2perl $path->slurp;

  shift @{$json->{rows}}; # header
  for my $row (@{$json->{rows}}) {
    $row->[0] =~ s{^(\s*1276 \|\| 丙子)}{$1||};
    if ($row->[0] =~ m{^\s*([0-9]+)\s*\|\|\s*\w+\s*\|\|\s*(\S.+\S)\s*\|\|\s*(\S.+\S)\s*$}) {
      my $CurrentYear = 0+$1;
      my $cys = $2;
      my $kys = $3;

      $cys =~ s/。$//;
      $kys =~ s/。$//;
      my @cy = grep { length } split /<p>|[。.]|\s+/, $cys;
      my @ky = grep { length } split /<p>|[。.]|\s+/, $kys;

      for my $ky (@ky) {
        if ($ky =~ m{^(\p{sc=Han}+?)($Num|元)年$}) {
          my $name = $1;
          my $year = parse_number $2;
          if ($name eq '忠肅王' and
              $Data->{eras}->{$name}->{years}->[$year]) {
            $name .= '後';
          }
          $name = '太祖' if $name eq '天授';
          $name = '光宗' if $name eq '光德';
          if ($name eq '太宗天會') {
            #
          } else {
            my $data = $Data->{eras}->{$name} ||= {};
            $data->{min_year} = 1;
            $data->{offset} ||= $CurrentYear + $year - 1 - 1;
            $data->{country} = '高麗';
            $data->{years}->[$year] = $CurrentYear;
            if (defined $prev_name and not $prev_name eq $name) {
              die "$name $year ($prev_name)" if $year != 1;
              $data->{prev}->{$CurrentYear} = $prev_name;
            }
            $prev_name = $name;
          }
        } elsif ($ky =~ m{^(恭讓王)(元)年十二月誅禑、昌$}) {
          my $name = $1;
          my $year = parse_number $2;
          my $data = $Data->{eras}->{$name} ||= {};
          $data->{min_year} = 1;
          $data->{offset} = $CurrentYear - 1;
          $data->{country} = '高麗';
          $data->{years}->[$year] = $CurrentYear;
          $data->{prev}->{$CurrentYear} = $prev_name;
          $prev_name = $name;
        } elsif ($ky =~ m{^($Num)月始行(\p{sc=Han}+)年號$}) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               month => (parse_number $1),
               country => '高麗',
               china_country => $2};
        } elsif ($ky =~ m{^行(\p{sc=Han}+)年號$}) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               country => '高麗',
               china_country => $1};
        } elsif ($ky =~ m{^($Num)月(\p{sc=Han}+)遣使來冊王自是復?行(\2)年號$}) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               month => (parse_number $1),
               country => '高麗',
               china_country => $2};
        } elsif ($ky =~ m{^(十)月遣使如契丹請壞鴨綠城橋不聽，停賀正使仍用(大平)年號$}) {
          push @{$Data->{china_era}},
              {event => 'continue', year => $CurrentYear,
               month => (parse_number $1),
               country => '高麗',
               era_name => $2};
        } elsif ($ky =~ m{^(四)月以遼爲金所侵正朔不可行，凡文牒除去(天慶)年號但用甲子$}) {
          push @{$Data->{china_era}},
              {event => 'stop_and_use_kanshi', year => $CurrentYear,
               month => (parse_number $1),
               country => '高麗',
               era_name => $2};
        } elsif ($ky =~ m{^以(金)國衰微不用年號$}) {
          push @{$Data->{china_era}},
              {event => 'stop', year => $CurrentYear,
               country => '高麗',
               china_country => $1};
        } elsif ($ky =~ m{^(五)月停(至正)年號，遣使奉表如金陵賀登極仍謝恩$}) {
          push @{$Data->{china_era}},
              {event => 'stop', year => $CurrentYear,
               month => (parse_number $1),
               country => '高麗',
               era_name => $2};
        } elsif ($ky =~ m{^(二)月(北元)遣使來行(宣光)年號$}) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               month => (parse_number $1),
               country => '高麗',
               china_country => $2,
               era_name => $3};
        } elsif ($ky =~ m{^(六)月廢禑放于江華，子昌立，復行(洪武)年號$}) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               month => (parse_number $1),
               country => '高麗',
               era_name => $2};
        } elsif ($ky =~ m{^(九)月復行(洪武)年號$}) {
          push @{$Data->{china_era}},
              {event => 'started', year => $CurrentYear,
               month => (parse_number $1),
               country => '高麗',
               era_name => $2};
        } elsif ($ky =~ m{^停(洪武)年號$}) {
          push @{$Data->{china_era}},
              {event => 'stop', year => $CurrentYear,
               country => '高麗',
               era_name => $1};
        } elsif ($ky =~ m{^(正隆)之(隆)避(世祖)諱以(豐)字代之$}) {
          push @{$Data->{china_era}},
              {event => 'rename', year => $CurrentYear,
               country => '高麗',
               era_name => $1,
               old_char => $2, new_char => $4, person => $3};
        } elsif ($ky =~ m{^(?:($Num)年|)(閏|)($Num)月(\p{sc=Han}+)薨，?(?:太子|弟|元子)(\p{sc=Han}*|\Q{{!|𭦬|⿰日真}}\E)卽位(?:是爲\p{sc=Han}+|)$}) {
          #
        } elsif ($ky =~ m{^($Num|正)月(\p{sc=Han}+)疾篤(?:召|傳位于)(?:弟|堂弟|太子|)(\p{sc=Han}*)(?:[禪傳]位，?|)(?:尋薨|)$}) {
          #
        } elsif ($ky =~ m{^十月大叔鷄林君顒受禪，卽位$}) {
          #
        } elsif ($ky =~ m{^(閏|)($Num)月(\p{sc=Han}+)薨$}) {
          #
        } elsif ($ky =~ m{^二月大良君詢卽位康兆廢穆宗，尋弑之$}) {
          #
        } elsif ($ky =~ m{^六月後百濟甄萱來投$}) {
          #
        } elsif ($ky =~ m{^十月新羅王金傅來降納土$}) {
          #
        } elsif ($ky =~ m{^九月王親討甄萱逆子神劒，後百濟亡$}) {
          #
        } elsif ($ky =~ m{^十月契丹來侵遣使請和$}) {
          #
        } elsif ($ky =~ m{^($Num|正)月(\p{sc=Han}+)遣使來冊王$}) {
          #
        } elsif ($ky =~ m{^十一月契丹帝來侵王幸羅州$}) {
          #
        } elsif ($ky =~ m{如(?:蒙古|元)$} or
                 $ky =~ m{自元} or
                 $ky =~ m{元加?冊}) {
          #
        } elsif ({
          太祖 => 1,
          光宗 => 1,
          契丹滅渤海國世子大光顯來附 => 1,
          二月王還京 => 1,
          "十一月遣使如宋貢方物，告契丹連歲來侵" => 1,
          二月遣使如契丹請稱藩納貢 => 1,
          正月契丹使至不納 => 1,
          五月契丹移牒責我絶通好 => 1,
          十二月遣使如契丹請復通好 => 1,
          "五月宋遣使賜國信物時與宋絶久，宋使至擧國欣慶" => 1,
          尹瓘逐女眞立碑公險鎭以爲界 => 1,
          六月宋賜大晟樂器 => 1,
          三月金遣使寄書請和親 => 1,
          二月李資謙叛流之 => 1,
          四月遣使如金上表稱臣 => 1,
          九月金遣使來諭虜宋二帝 => 1,
          六月宋遣使請假途往問二帝 => 1,
          行在王上表陳畏金未得承稟之意 => 1,
          正月僧妙淸等據西京叛 => 1,
          二月金富軾平西京 => 1,
          八月毅宗幸普賢院鄭仲夫等殺扈從文臣入城殺文臣五十餘人 => 1,
          "九月，放毅宗于巨齊殺太子立王弟翼陽公晧" => 1,
          六月金甫當等 => 1,
          "反正至巨濟，奉毅宗出居" => 1,
          林府 => 1,
          九月鄭仲夫等殺文臣殆盡 => 1,
          十月李義旼弑毅宗 => 1,
          九月西京留守趙位寵起兵 => 1,
          九月慶大升誅鄭仲夫 => 1,
          四月崔忠獻殺李義旼 => 1,
          九月崔忠獻廢明宗放太子立王弟平 => 1,
          公旼 => 1,
          十一月明宗薨十二月東京叛遣將討之 => 1,
          尋薨 => 1,
          十二月崔忠獻放熙宗及太子 => 1,
          立漢南公貞 => 1,
          八月契丹遺種金山金始二王子 => 1,
          來侵 => 1,
          三月丹兵犯京城 => 1,
          三月趙 => 1,
          金就礪殲丹兵于江東城 => 1,
          八月蒙古始遣使來索獺皮紬苧等物 => 1,
          正月蒙使遝中途爲盜所殺 => 1,
          蒙古反疑我遂與之絶 => 1,
          十二月蒙古兵圍京城 => 1,
          七月崔瑀脅王遷都江華 => 1,
          五月西京人畢賢甫叛擒斬之 => 1,
          八月蒙古兵散入南京 => 1,
          四月永寧公 => 1,
          入蒙古爲禿魯花 => 1,
          七月蒙古遣人來督復都舊京 => 1,
          九月蒙使來王出迎于昇天府十二月遣安慶公 => 1,
          如蒙古乞還師 => 1,
          九月蒙古車羅大兵 => 1,
          入南界 => 1,
          五月車羅大復來曰王親來又令王子朝京可無患王遣永安公請還師 => 1,
          三月柳璥金俊等誅崔誼 => 1,
          九月蒙古兵犯松京 => 1,
          十二月定州人卓靑等叛附蒙古 => 1,
          四月遣太子 => 1,
          如蒙古請降 => 1,
          六月高宗薨太孫諶權監國事 => 1,
          四月元宗還自蒙古卽位 => 1,
          九月還 => 1,
          八月王如蒙古十二月還 => 1,
          十二月林衍誅金俊代執國政 => 1,
          四月世子如蒙古六月林衍廢王立安慶公 => 1,
          八月帝遣使詔責高麗臣僚 => 1,
          十二月王復位如蒙古是歲崔坦殺西京留守叛附蒙古 => 1,
          三月林衍憂 => 1,
          死洪文 => 1,
          "宋松禮等，誅衍子惟茂復政王室" => 1,
          五月王與世子自蒙古還舊京 => 1,
          六月三別抄叛立承化侯溫據珍島是歲蒙古置達魯花赤于我國 => 1,
          五月金方慶與蒙古元帥 => 1,
          篤洪茶丘 => 1,
          "攻破珍島殺僞王，餘黨散入耽羅" => 1,
          六月世子入質于蒙古 => 1,
          二月世子從元俗 => 1,
          "髮胡服而還，國人駭之" => 1,
          四月金方慶與 => 1,
          篤等討三別抄餘黨于耽羅平之 => 1,
          五月世子尙元帝女安平公主 => 1,
          八月世子還國卽位 => 1,
          十月金方慶與元元帥忽敦洪茶丘等征日本至一 => 1,
          戰敗軍不還者萬三千五百餘人 => 1,
          四月王及公主世子 => 1,
          征日本事 => 1,
          五月金方慶與 => 1,
          篤茶丘 => 1,
          征日本至覇家臺戰敗軍不還者十萬有奇 => 1,
          三月王及公主世子還 => 1,
          五月哈丹來侵 => 1,
          十二月以哈丹之侵遷都江華 => 1,
          正月世子見帝請討哈丹帝遣平章事薛 => 1,
          干率師來救 => 1,
          五月殲哈丹于燕 => 1,
          縣 => 1,
          正月復都開京 => 1,
          八月王及公主還 => 1,
          九月王及公主世子 => 1,
          五月王及公主還公主薨 => 1,
          十月世子如元遣使請傳位世子元許之 => 1,
          "正月世子與妃寶塔實憐公主來，王傳位于世子是爲忠宣元封王爲逸壽王" => 1,
          "八月元遣使趣忠宣及公主入朝，取國王印授逸壽王" => 1,
          "自是忠宣入朝宿衛者，凡十年" => 1,
          八月還 => 1,
          "忠宣迎立武宗功第一，封瀋陽王" => 1,
          "七月忠烈王薨，忠宣還國復卽位" => 1,
          十月元遣使來冊王依前瀋陽王 => 1,
          "三月王欲留元，不欲東還，以世子燾見于帝，請傳位" => 1,
          帝命冊封是爲忠肅王 => 1,
          忠宣又以異母兄江陽公滋之子暠爲瀋陽王世子 => 1,
          "四月忠宣不得已，與公主及新王還自元，以暠留元爲禿魯花" => 1,
          六月新王卽位 => 1,
          "三月忠宣奏于帝，傳瀋王位于世子暠，自稱太尉王" => 1,
          七月王娶營王之女亦憐眞八剌公主 => 1,
          五月帝命太尉王降香于江南 => 1,
          "十月自江南還京，宦者伯顔豆古思于帝" => 1,
          十二月流吐蕃 => 1,
          "十二月白元恒、朴孝修等上書于元，乞還太尉王" => 1,
          三月帝因 => 1,
          責王收國王印 => 1,
          "時瀋王方幸於帝，曹" => 1,
          蔡河中等謀立瀋王王萬端 => 1,
          "八月權漢功、蔡洪哲等上書于元，請立瀋王，百官不署名" => 1,
          "九月又集百官署名，呈于元不受" => 1,
          元召太尉王還燕京 => 1,
          正月 => 1,
          "王還國，復賜國王印" => 1,
          五月太尉王薨于燕邸 => 1,
          二月遣世子禎如元宿衛 => 1,
          十月遣使請傳位世子禎 => 1,
          五月命王還國 => 1,
          正月元命忠肅復位 => 1,
          "二月遣使來取國王印，徵忠惠入朝" => 1,
          三月忠肅王薨 => 1,
          九月征東省請忠惠襲位 => 1,
          "十一月元遣使傳國印于忠惠，遂執以歸" => 1,
          正月元囚忠惠于刑部 => 1,
          三月釋之復王位四月東還 => 1,
          十一月元遣使執王以歸 => 1,
          十二月流于揭陽 => 1,
          正月行至岳陽縣薨 => 1,
          二月元子昕在元帝命襲王位 => 1,
          四月東還 => 1,
          二月元命忠惠王庶子 => 1,
          入朝 => 1,
          五月命 => 1,
          嗣位 => 1,
          "十月元以忠惠王母弟江寧大君祺爲國王，遣使收國璽以歸，忠定遜于江華" => 1,
          三月忠定王遇 => 1,
          薨 => 1,
          五月奇轍等謀逆誅之 => 1,
          十月紅賊十餘萬來侵 => 1,
          "十一月，王及公主幸福州賊陷京城" => 1,
          正月安祐李方實金得培等大敗紅賊收復京城 => 1,
          二月王還都次興王寺 => 1,
          "閏三月夜盜入行宮，徑至寢殿" => 1,
          王匿免 => 1,
          "後得罪人金鏞，誅之" => 1,
          五月元以忠宣王 => 1,
          "子德興君爲高麗國王，崔濡自爲政丞以來，王遣慶千興等禦之" => 1,
          "正月崔濡以德興君渡鴨綠江圍義州，濡軍見我軍盛自潰而北" => 1,
          "十月元遣使詔王復位，檻送崔濡" => 1,
          四月大明遣使賜璽書及紗羅匹段 => 1,
          正月我太祖平東寧府 => 1,
          五月帝遣使齎印來封王 => 1,
          八月易服色 => 1,
          六月辛旽謀逆誅之 => 1,
          五月大明安置漢主陳友諒子理夏主明貞子昇于我 => 1,
          七月封辛禑爲江寧大君 => 1,
          九月洪倫崔萬生弑王李仁任立辛禑 => 1,
          "十一月密直金義伴大明使林密、蔡斌，中路殺斌奔北元" => 1,
          "九月倭賊焚雲峯縣屯引月驛，我太祖率諸將大敗之" => 1,
          三月大明立鐵嶺衛 => 1,
          "四月禑以曹敏修爲左軍都統，我太祖爲右軍都統，往攻遼東" => 1,
          "五月師次威化島，太祖擧義回軍" => 1,
          "十一月我太祖與沈德符等定策，立定昌府院君瑤，放昌于江華" => 1,
          恭讓王四年七月廢王放于原州 => 1,
        }->{$ky}) {
          #
        } elsif ($ky =~ /\S/) {
          die "Bad line component |$ky|";
        }
      }
    } elsif ($row->[0] =~ /\S/) {
      die "Bad line |$row->[0]|";
    }
  }

} # read_table

for (qw(kouraitable1.json kouraitable2.json)) {
  my $path = $ThisPath->child ($_);
  read_table $path;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
