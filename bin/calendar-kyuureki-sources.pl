use strict;
use warnings;
use utf8;
use Path::Tiny;
use JSON::PS;

my $root_path = path (__FILE__)->parent->parent;

my $Data = {};
my $Input = {};

{
  my $path = $root_path->child ('local/kyuureki-sansei.json');
  my $json = json_bytes2perl $path->slurp;
  for my $g (keys %{$json->{mapping}}) {
    $Data->{j106}->{map}->{$json->{mapping}->{$g}} = $g;
  }
}

$Input->{j245} = q{
## <http://fomalhautpsa.sakura.ne.jp/Science/OgawaKiyohiko/senmyoreki.pdf>

* * j245-computed j245-actual
1001 11' 戊戌 -
1001 12 丁卯 戊戌
1001 12' - 戊辰
1069 10' - 甲子
1069 11 - 癸巳
1069 11' 甲午 -
1164 11' 壬子 -
1164 10' - 壬午
1164 11 - 辛亥
1183 11' 壬辰 -
1183 10' - 壬戌
1183 11 - 辛卯
1259 11' 庚午 -
1259 10' - 庚子
1259 11 - 己巳
1278 11' 庚戌 -
1278 10' - 庚辰
1278 11 - 己酉
1297 11' 庚寅 -
1297 10' - 庚申
1297 11 - 己丑
1335 10' -    己卯
1335 11  己卯 戊申
1335 12  己酉 戊寅
1335 12' 己卯 -
1336 1   己酉 戊申
1338 8' 癸巳 -
1338 7' - 癸亥
1338 8  - 壬辰
1357 8' 癸酉 -
1357 7' - 癸卯
1357 8  - 壬申
1376 8' 癸丑 -
1376 7' - 癸未
1376 8 - 壬子
1392 11' 戊申 -
1392 10' - 戊寅
1392 11 - 丁未
1411 11' 戊子 -
1411 10' - 戊午
1411 11  - 丁亥

推算 := j245-computed
長暦 := j246
通暦 := j247
便覧 := j245-actual
三正 := j106

* *          推算 長暦 通暦 便覧
936 11       丙戌 丙戌 丙戌 丙戌
936 11'      丙辰 丙辰 丙辰 丙辰
936 12       乙酉 乙酉 乙酉 乙酉
937 1        乙卯 乙卯 乙卯 甲寅
937 2        乙酉 乙酉 乙酉 甲申
937 3        甲寅 甲寅 甲寅 甲寅

* *    推算 長暦 便覧 通暦
1217 3 戊寅 戊寅 戊寅 戊寅
1217 4 丁未 丁未 丁未 戊申
1217 5 丁丑 丁丑 丁丑 戊寅
1217 6 丁未 丁未 丁未 丁未

*   * 推算 長暦 通暦 三正 便覧
891 7 己酉 d d d 戊申
894 5 癸亥 d d d 壬戌
937 12 庚辰 d d d 己卯
958 5 壬午 d d d 辛巳
965 1 癸酉 d d d 壬申
973 4 乙酉 d d d 甲申
977 9 己丑 d d d 戊子
982 4 癸亥 d d d 壬戌
983 2 戊子 d d d 丁亥
994 4 癸未 d d d 壬午
994 6 壬午 d d d 辛巳
997 4 乙未 d d d 甲午
997 6 甲午 d d d 癸巳
1002 10 癸亥 d d d 壬戌
1014 3 丁亥 d 丙戌 丙戌 丙戌
1032 11 己巳 d d 戊辰 戊辰
1138 1 戊子 d d 丁亥 丁亥
1157 1 戊辰 d 丁卯 丁卯 丁卯
1187 8 庚午 d 己巳 己巳 己巳
1228 1 丙子 d 乙亥 乙亥 乙亥
1336 3 戊申 d d d 丁未
1344 1 癸亥 d d d 壬戌
1395 12 辛卯 d d d 庚寅
#1433 8 辛巳 d d d 辛巳
1433 9 辛巳 d d d 庚辰
1433 10 庚戌 d d d 庚戌

*    *   推算 長暦 通暦 便覧
1468 10  丁亥 d    d    d
1468 10' -    -    丁巳 d
1468 11  丁巳 d    丙戌 -
1468 12  丁亥 -    丙辰 -
1468 12' 丁巳 d    -    -
1469 1   丙戌 d    d    d

*    *  推算 長暦 通暦 三正 便覧
892  1  丙午 d    d    d    丁未
1018 10 己丑 d    庚寅 d    d
1026 9  癸卯 d    d    d    甲辰
1027 8  戊辰 d    d    d    己巳
1030 1  甲寅 d    d    d    乙卯
1034 8  丁巳 d    d    d    戊午
1037 4  癸卯 d    d    d    甲辰
1396 5  丁巳 d    d    d    戊午

*    *   推算 長暦 通暦 便覧
1050 10  乙卯 d    d    d
1050 10' -    -    甲申 d
1050 11  甲申 d    癸丑 d
1050 11' 甲寅 d    -    -
1050 12  甲申 d    癸未 d
1051 1   癸丑 d    d    d

*    *  推算 長暦 通暦 便覧
1129 7  丁丑 d    d    d
1129 7' -    -    丁未 d
1129 8  丁未 d    丙子 d
1129 8' 丁丑 d    -    -
1129 9  丙午 d    d    d

*    *  推算 長暦 通暦 便覧 三正
1162 2  戊戌 d    d    d    -
1162 2' -    -    戊辰 d    -
1162 3  戊辰 d    丁酉 d    d
1162 3' 戊戌 d    -    -    -
1162 4  丁卯 d    d    d    -

*    *   推算 長暦 通暦 便覧
1202 10  壬申 d    d    d
1202 10' -    -    -    壬寅
1202 11  壬寅 -    -    辛未
1202 11' 辛未 -    -    -
1202 12  辛未 d    d    d
1203 1   辛未 d    d    d
1203 2   庚子 d    d    d

*    *   推算 長暦 通暦 便覧
1243 7   丙子 d    d    d
1243 7'  -    -    乙巳 d
1243 8   乙巳 乙巳 甲戌 d
1243 8'  乙亥 d    -    -
1243 9   甲辰 d    d    d

*    *   推算 長暦 通暦 三正 便覧
1281 7   甲子 d    -    -    -
1281 7'  -    -    甲子 d    d
1281 8   甲子 d    癸巳 d    甲午
1281 8'  甲午 d    -    -    -
1281 9   癸亥 d    d    d    d

*    *   推算 長暦 通暦 便覧
1316 10  庚午 d    d    d
1316 10' -    己亥 d    d
1316 11  庚子 戊辰 d    d
1316 11' 庚午 -    -    -
1316 12  己亥 d    戊戌 d
1317 1   己巳 d    戊辰 d
1317 2   戊戌 d    d    d

*    *   推算 長暦 便覧 通暦
1373 10' -    -    戊戌 d
1373 11  戊戌 d    丁卯 d
1373 11' 戊辰 d    -    -
1373 12  戊戌 d    丁酉 d

* *    推算 長暦 通暦 便覧 三正
1374 1 丁卯 丁卯 丁卯 丁卯 -
1374 2 丁酉 丁酉 丁酉 丁酉 -
1374 3 丁卯 丁卯 丁卯 丙寅 丁卯

*    *  推算 長暦 便覧 通暦
1395 7  癸巳 d    d    d
1395 7' -    -    壬辰 d
1395 8  壬戌 d    辛卯 d
1395 8' 壬辰 d    -    -
1395 9  壬戌 d    辛酉 d

*    *   推算 長暦 便覧 通暦
1449 10  戊申 d    d    d
1449 10' -    -    丁丑 d
1449 11  戊寅 d    丙午 d
1449 12  丁未 d    丙子 d
1449 12' 丁丑 d    -    -
1450 1   丁未 d    丙午 d
1450 2   丙子 d    d    d

*    *  推算 長暦 便覧 通暦
1156 10 己亥 d    d    d
1156 11 己巳 d    戊辰 d
1156 12 戊戌 d    d    d

*    *  推算 便覧
1270 10 丁酉 d
1270 11 丁卯 丙寅
1270 12 丙申 d
1271 1  乙丑 d

*    *  推算 長暦 便覧 通暦
1308 10 丙辰 d d d
1308 11 丙戌 d 乙酉 d
1308 12 丙辰 d 乙卯 d
1309 1  乙酉 d d d

*    *   推算 長暦 通暦 便覧
1441 10  甲午 d d d
1441 11  甲子 d d 癸亥
1441 12  甲午 d d 癸巳
1442 1   癸亥 d d d

*    *  推算 長暦 便覧 通暦
1479 10 癸丑 d d d
1479 11 癸未 d 壬午 d
1479 12 壬子 d d d

*    *  推算 長暦 通暦 三正 便覧
891  1  壬子 d    d    d    辛亥
938  1  己酉 d    d    d    戊申
938  2  己卯 d    d    d    戊寅
942 11  辛巳 d    d    d    庚辰
975  9  庚午 d    d    d    己巳
1110 7' 丁卯 d    戊辰 d    d

*    * 推算 長暦 通暦 三正 便覧
1091 9 丙戌 丁亥 d    d    丙戌
1272 2 己丑 庚寅 d    d    己丑
1503 7 乙丑 丙寅 d    d    乙丑

};

$Input->{mishima} = q{

## 応安7年 京暦3月4日 = 三島暦3月3日
## <http://fomalhautpsa.sakura.ne.jp/Science/OgawaKiyohiko/senmyoreki.pdf>
g:1374-04-21 k:1374-03-01

## <http://tokaido.canariya.net/1-rene-tokdo/6book/2bu/7.html>
## 1/1=壬辰
1437 2/15 010110101001

## <https://www.city.mishima.shizuoka.jp/ipn017331.html>
## 天明9年 1/1=戊午
1789 1/26 1101010010101 6

## <http://library.nao.ac.jp/kichou/open/013/>
## 文化2年 1/1=丙戌
1805 1/31 0101000101110 8

## <http://dl.ndl.go.jp/info:ndljp/pid/8929798>
## 文化14年 1/1=乙巳
1817 2/16 101101010010
## 文化15年 1/1=己亥
1818 2/5 110101101001
## 文政2年 1/1=甲午
1819 1/26 0101011011010 4
## 文政3年
1820 010101011101
## 文政4年
1821 010010101101
## 文政5年
1822 1010001011011 1
## 文政6年
1823 101000101011
## 文政7年
1824 1100100101011 8
## 文政8年
1825 101010100101
## 文政9年
1826 101101010010

## <http://www.ndl.go.jp/koyomi/rekishi/chihou06_2_exp.html>
## 文政8年 1/1=己丑
#1825 2/18 101010100101

## <http://www.geocities.jp/mishimagoyomi/tenpo15yomu/tenpo15yomu.htm>
## 天保15年 1/1=戊辰
1844 2/18 110101010101

## <http://blog.goo.ne.jp/sztimes/e/48ddc21aa07dd8e50d159dae2c32ec83>
## 嘉永6年 1/1=丙午
1853 2/8 101101010101

## <http://dl.ndl.go.jp/info:ndljp/pid/2555153>
## 慶応4年
1868 1/25 0110010010110 4
## 明治2年
1869 111001001011
## 明治3年
1870 0110101010010 10
## 明治4年
1871 110110101001

}; # mishima

$Input->{c102} = q{

## 11月 小
g:1933-12-17 k:1933-11-01
g:1934-01-01 k:1933-11-16
## 12月 大
g:1934-01-15 k:1933-12-01
1934 2/14 010110101101
1935 001010110110
1936 1001001101110 3
1937 100100101110
1938 1100100101101 7
1939 110010010101
1940 110101001010
1941 1101101001010 6
1942 101101101001
1943 010101101101
1944 0010101011011 4
1945 001001011101

};

$Input->{c67} = q{

## <https://www.jstage.jst.go.jp/article/jgeography1889/19/10/19_10_745/_pdf>
## 光武11年 1/1=癸巳
1907 2/13 010101101010

## <http://dl.ndl.go.jp/info:ndljp/pid/2535599>
T7 2/11 100101011101

## <http://dl.ndl.go.jp/info:ndljp/pid/2535600>
T12 2/16 011010101001

## <http://dl.ndl.go.jp/info:ndljp/pid/2535601>
T16 2/2 100101011011

}; # c67

$Input->{c14} = q{
g:1913-12-27 k:1913-12-01
g:1913-12-28 k:1913-12-02
g:1913-12-29 k:1913-12-03
g:1913-12-30 k:1913-12-04
g:1913-12-31 k:1913-12-05
g:1914-01-01 k:1913-12-06
g:1914-01-26 k:1914-01-01
g:1914-02-25 k:1914-02-01
g:1914-03-27 k:1914-03-01
g:1914-04-25 k:1914-04-01
g:1914-05-25 k:1914-05-01
g:1914-06-23 k:1914-05'-01
g:1914-07-23 k:1914-06-01
g:1914-08-21 k:1914-07-01
g:1914-09-20 k:1914-08-01
g:1914-10-19 k:1914-09-01
g:1914-11-17 k:1914-10-01
g:1914-12-17 k:1914-11-01
g:1915-01-15 k:1914-12-01
g:1915-02-14 k:1915-01-01
g:1915-03-16 k:1915-02-01
g:1915-04-14 k:1915-03-01
g:1915-05-14 k:1915-04-01
g:1915-06-13 k:1915-05-01
g:1915-07-12 k:1915-06-01
g:1915-08-11 k:1915-07-01
g:1915-09-09 k:1915-08-01
g:1915-10-09 k:1915-09-01
g:1915-11-07 k:1915-10-01
g:1915-12-07 k:1915-11-01
g:1916-01-05 k:1915-12-01
g:1916-02-03 k:1916-01-01
g:1916-03-04 k:1916-02-01
g:1916-04-03 k:1916-03-01
g:1916-05-02 k:1916-04-01
g:1916-06-01 k:1916-05-01
g:1916-06-30 k:1916-06-01
g:1916-07-30 k:1916-07-01
g:1916-08-29 k:1916-08-01
g:1916-09-27 k:1916-09-01
g:1916-10-27 k:1916-10-01
g:1916-11-25 k:1916-11-01
g:1916-12-25 k:1916-12-01
g:1917-01-23 k:1917-01-01
g:1917-02-22 k:1917-02-01
g:1917-03-23 k:1917-02'-01
g:1917-04-21 k:1917-03-01
g:1917-05-21 k:1917-04-01
g:1917-06-19 k:1917-05-01
g:1917-07-19 k:1917-06-01
g:1917-08-18 k:1917-07-01
g:1917-09-16 k:1917-08-01
g:1917-10-16 k:1917-09-01
g:1917-11-15 k:1917-10-01
g:1917-12-14 k:1917-11-01

g:1920-01-21 k:1919-12-01
g:1920-02-20 k:1920-01-01
g:1920-03-20 k:1920-02-01
g:1920-04-19 k:1920-03-01
g:1920-05-18 k:1920-04-01
g:1920-06-16 k:1920-05-01
g:1920-07-16 k:1920-06-01
g:1920-08-14 k:1920-07-01
g:1920-09-12 k:1920-08-01
g:1920-10-12 k:1920-09-01
g:1920-11-10 k:1920-10-01
g:1920-12-10 k:1920-11-01
g:1921-01-09 k:1920-12-01
g:1921-02-08 k:1921-01-01
g:1921-03-10 k:1921-02-01
g:1921-04-08 k:1921-03-01
g:1921-05-08 k:1921-04-01
g:1921-06-06 k:1921-05-01
g:1921-07-05 k:1921-06-01
g:1921-08-04 k:1921-07-01
g:1921-09-02 k:1921-08-01
g:1921-10-01 k:1921-09-01
g:1921-10-31 k:1921-10-01
g:1921-11-29 k:1921-11-01
g:1921-12-29 k:1921-12-01
g:1922-01-28 k:1922-01-01
g:1922-02-27 k:1922-02-01
g:1922-03-28 k:1922-03-01
g:1922-04-27 k:1922-04-01
g:1922-05-27 k:1922-05-01
g:1922-06-25 k:1922-05'-01
g:1922-07-24 k:1922-06-01
g:1922-08-23 k:1922-07-01
g:1922-09-21 k:1922-08-01
g:1922-10-20 k:1922-09-01
g:1922-11-19 k:1922-10-01
g:1922-12-18 k:1922-11-01
};

$Input->{c15} = q{
## 11 大
g:1956-01-01 k:1955-11-19
g:1956-01-13 k:1955-12-01
1956 2/12 010100101011
1957 1010100101010 8

## 1977 11 小 12 小
1978 2/7 101101101010

g:2005-12-31 k:2005-12-01
g:2006-01-29 k:2006-01-01
g:2006-02-28 k:2006-02-01
g:2006-03-29 k:2006-03-01
g:2006-04-28 k:2006-04-01
g:2006-05-27 k:2006-05-01
g:2006-06-26 k:2006-06-01
g:2006-07-25 k:2006-07-01
g:2006-08-24 k:2006-07'-01
g:2006-09-22 k:2006-08-01
g:2006-10-22 k:2006-09-01
g:2006-11-21 k:2006-10-01
g:2006-12-20 k:2006-11-01
};

{
  ## Derived from |Time::Local|
  ## <http://cpansearch.perl.org/src/DROLSKY/Time-Local-1.2300/lib/Time/Local.pm>.

  use constant SECS_PER_MINUTE => 60;
  use constant SECS_PER_HOUR   => 3600;
  use constant SECS_PER_DAY    => 86400;

  my %Cheat;
  my $Epoc = 0;
  $Epoc = _daygm( gmtime(0) );
  %Cheat = ();

  use POSIX qw(floor);
  sub _daygm {

    # This is written in such a byzantine way in order to avoid
    # lexical variables and sub calls, for speed
    return $_[3] + (
        $Cheat{ pack( 'ss', @_[ 4, 5 ] ) } ||= do {
            my $month = ( $_[4] + 10 ) % 12;
            my $year  = $_[5] + 1900 - int($month / 10);

            ( ( 365 * $year )
              + floor( $year / 4 )
              - floor( $year / 100 )
              + floor( $year / 400 )
              + int( ( ( $month * 306 ) + 5 ) / 10 )
            )
            - $Epoc;
        }
    );
  }

  sub timegm_nocheck {
    my ( $sec, $min, $hour, $mday, $month, $year ) = @_;

    my $days = _daygm( undef, undef, undef, $mday, $month, $year - 1900);

    return $sec
           + ( SECS_PER_MINUTE * $min )
           + ( SECS_PER_HOUR * $hour )
           + ( SECS_PER_DAY * $days );
  }
}

my $g2k_map_path = $root_path->child ('data/calendar/kyuureki-map.txt');
my $g2k_map = {map { split /\t/, $_ } split /\x0D?\x0A/, $g2k_map_path->slurp};
my $k2g_map = {reverse %$g2k_map};

sub k2g ($) {
  return $k2g_map->{$_[0]} or die "Kyuureki |$_[0]| is not defined";
} # k2g

sub jd2g_ymd ($) {
  my @time = gmtime (($_[0] - 2440587.5) * 24 * 60 * 60);
  return undef unless defined $time[5];
  return ($time[5]+1900, $time[4]+1, $time[3]);
} # jd2g_ymd

my $IndexToKanshi = {map { my $x = $_; $x =~ s/\s+//g; $x =~ s/(\d+)/ $1 /g;
                           grep { length } split /\s+/, $x } q{
1甲子2乙丑3丙寅4丁卯5戊辰6己巳7庚午8辛未9壬申10癸酉11甲戌12乙亥13丙子
14丁丑15戊寅16己卯17庚辰18辛巳19壬午20癸未21甲申22乙酉23丙戌24丁亥25戊子
26己丑27庚寅28辛卯29壬辰30癸巳31甲午32乙未33丙申34丁酉35戊戌36己亥
37庚子38辛丑39壬寅40癸卯41甲辰42乙巳43丙午44丁未45戊申46己酉47庚戌48辛亥
49壬子50癸丑51甲寅52乙卯53丙辰54丁巳55戊午56己未57庚申58辛酉59壬戌60癸亥
}};
sub ymk_to_g ($$$$) {
  my ($k_y, $k_m, $k_l, $kanshi) = @_;
  my $k1 = sprintf '%04d-%02d%s-%02d', $k_y, $k_m, $k_l ? "'" : '', 1;
  my $k2 = sprintf '%04d-%02d%s-%02d', $k_y, $k_m, '', 1;
  my @g = split /-/, (k2g $k1) // (k2g $k2);
  my $unix = timegm_nocheck 0, 0, 0, $g[2], $g[1]-1, $g[0];
  my $jd = $unix / (24*60*60) + 2440587.5;
  for my $delta_day (0, 1..30, reverse (-30..-1), 31, -31) {
    my $b_jd = $jd + $delta_day;
    my $b_index = (($b_jd + 49.5) % 60) + 1;
    my $b_kanshi = $IndexToKanshi->{$b_index};
    if ($b_kanshi eq $kanshi) {
      return jd2g_ymd $b_jd;
    }
  }
  die "Bad input $k_y/$k_m/$k_l/$kanshi";
} # ymk_to_g

sub ymd_to_string (@) {
  return sprintf '%04d-%02d-%02d', $_[0], $_[1], $_[2];
} # ymd_to_string

for my $key (keys %$Input) {
  my $data = $Data->{$key} ||= {};
  $data->{partial} = 1 unless $key eq 'c102';
  my $day;
  my $col1;
  my $col2;
  my $col3;
  my $col4;
  my $col5;
  my $key_map = {};
  for (split /\n/, $Input->{$key}) {
    if (/^\s*#/) {
      next;
    } elsif (m{^([0-9]+|T[0-9]+)\s+(?:([0-9]+)/([0-9]+)\s+|)([012]+)(?:\s+([0-9]+)|)$}) {
      my $year = $1;
      my $g_m = $2;
      my $g_d = $3;
      my $months = $4;
      my $leap = $5;
      $months =~ tr/2/0/;

      if ($year =~ s/^T//) {
        $year += 1911;
      }

      $day = timegm_nocheck 0, 0, 0, $g_d, $g_m-1, $year if defined $g_d;
      my $k_m = 1;
      my $is_leap = 0;
      for (split //, $months) {
        my $k = sprintf '%04d-%02d%s-%02d', $year, $k_m, $is_leap ? "'" : '', 1;
        my @g = gmtime $day;
        my $g = sprintf '%04d-%02d-%02d', $g[5]+1900, $g[4]+1, $g[3];
        if (defined $data->{$k}) {
          die "Duplicate |$k|";
        } else {
          $data->{map}->{$k} = $g;
        }

        if (defined $leap and $k_m == $leap) {
          if ($is_leap) {
            $k_m++;
            $is_leap = 0;
          } else {
            $is_leap = 1;
          }
        } else {
          $k_m++;
        }
        $day += (29 + ($_ ? 1 : 0)) * 24*60*60;
      }
    } elsif (/^g:([0-9]+)-([0-9]+)-([0-9]+)\s+k:([0-9]+)-([0-9]+)('|)-([0-9]+)$/) {
      my $g = sprintf '%04d-%02d-%02d', $1, $2, $3;
      my $k = sprintf '%04d-%02d%s-%02d', $4, $5, $6 ? "'" : '', $7;
      if (defined $data->{map}->{$k}) {
        die "Duplicate |$k|";
      }
      $data->{map}->{$k} = $g;
    } elsif (/^\*\s+\*\s+([\w-]+)\s+([\w-]+)$/) {
      $col1 = $key_map->{$1} // $1;
      $col2 = $key_map->{$2} // $2;
      $col3 = undef;
      $col4 = undef;
      $col5 = undef;
      $Data->{$col1}->{partial} = 1;
      $Data->{$col2}->{partial} = 1;
    } elsif (/^\*\s+\*\s+([\w-]+)\s+([\w-]+)\s+([\w-]+)\s+([\w-]+)$/) {
      $col1 = $key_map->{$1} // $1;
      $col2 = $key_map->{$2} // $2;
      $col3 = $key_map->{$3} // $3;
      $col4 = $key_map->{$4} // $4;
      $col5 = undef;
      $Data->{$col1}->{partial} = 1;
      $Data->{$col2}->{partial} = 1;
      $Data->{$col3}->{partial} = 1;
      $Data->{$col4}->{partial} = 1;
    } elsif (/^\*\s+\*\s+([\w-]+)\s+([\w-]+)\s+([\w-]+)\s+([\w-]+)\s+([\w-]+)$/) {
      $col1 = $key_map->{$1} // $1;
      $col2 = $key_map->{$2} // $2;
      $col3 = $key_map->{$3} // $3;
      $col4 = $key_map->{$4} // $4;
      $col5 = $key_map->{$5} // $5;
      $Data->{$col1}->{partial} = 1;
      $Data->{$col2}->{partial} = 1;
      $Data->{$col3}->{partial} = 1;
      $Data->{$col4}->{partial} = 1;
      $Data->{$col5}->{partial} = 1;
    } elsif (/^([0-9]+)\s+([0-9]+)('|)\s+([\w-]+)\s+([\w-]+)(?:\s+([\w-]+)|)(?:\s+([\w-]+)|)(?:\s+([\w-]+)|)$/) {
      my $k_y = $1;
      my $k_m = $2;
      my $k_l = $3;
      my $kanshi1 = $4;
      my $kanshi2 = $5;
      my $kanshi3 = $6 // '-';
      my $kanshi4 = $7 // '-';
      my $kanshi5 = $8 // '-';
      unless ($kanshi1 eq '-') {
        my $g = ymd_to_string ymk_to_g $k_y, $k_m, $k_l, $kanshi1;
        my $k = sprintf '%04d-%02d%s-%02d', $k_y, $k_m, $k_l ? "'" : '', 1;
        if (defined $Data->{"$col1"}->{map}->{$k}) {
          warn "Duplicate $col1 $k";
        } else {
          $Data->{$col1}->{map}->{$k} = $g;
          $Data->{$key}->{notes}->{$k}->{misc_note} = 1;
        }
      }
      unless ($kanshi2 eq '-') {
        $kanshi2 = $kanshi1 if $kanshi2 eq 'd';
        my $g = ymd_to_string ymk_to_g $k_y, $k_m, $k_l, $kanshi2;
        my $k = sprintf '%04d-%02d%s-%02d', $k_y, $k_m, $k_l ? "'" : '', 1;
        if (defined $Data->{"$col2"}->{map}->{$k}) {
          warn "Duplicate $col2 $k";
        } else {
          $Data->{$col2}->{map}->{$k} = $g;
          $Data->{$key}->{notes}->{$k}->{misc_note} = 1;
        }
      }
      unless ($kanshi3 eq '-') {
        $kanshi3 = $kanshi2 if $kanshi3 eq 'd';
        my $g = ymd_to_string ymk_to_g $k_y, $k_m, $k_l, $kanshi3;
        my $k = sprintf '%04d-%02d%s-%02d', $k_y, $k_m, $k_l ? "'" : '', 1;
        if (defined $Data->{"$col3"}->{map}->{$k}) {
          warn "Duplicate $col3 $k";
        } else {
          $Data->{$col3}->{map}->{$k} = $g;
          $Data->{$key}->{notes}->{$k}->{misc_note} = 1;
        }
      }
      unless ($kanshi4 eq '-') {
        $kanshi4 = $kanshi3 if $kanshi4 eq 'd';
        my $g = ymd_to_string ymk_to_g $k_y, $k_m, $k_l, $kanshi4;
        my $k = sprintf '%04d-%02d%s-%02d', $k_y, $k_m, $k_l ? "'" : '', 1;
        if (defined $Data->{"$col4"}->{map}->{$k}) {
          warn "Duplicate $col4 $k";
        } else {
          $Data->{$col4}->{map}->{$k} = $g;
          $Data->{$key}->{notes}->{$k}->{misc_note} = 1;
        }
      }
      unless ($kanshi5 eq '-') {
        $kanshi5 = $kanshi4 if $kanshi5 eq 'd';
        my $g = ymd_to_string ymk_to_g $k_y, $k_m, $k_l, $kanshi5;
        my $k = sprintf '%04d-%02d%s-%02d', $k_y, $k_m, $k_l ? "'" : '', 1;
        if (defined $Data->{"$col5"}->{map}->{$k}) {
          warn "Duplicate $col5 $k";
        } else {
          $Data->{$col5}->{map}->{$k} = $g;
          $Data->{$key}->{notes}->{$k}->{misc_note} = 1;
        }
      }
    } elsif (/^([\w-]+)\s+:=\s+([\w-]+)$/) {
      die "Duplicate $1" if defined $key_map->{$1};
      $key_map->{$1} = $2;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
} # $key

print perl2json_bytes_for_record $Data;

## License: Public Domain.

