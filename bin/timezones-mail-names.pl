use strict;
use warnings;
use JSON::PS;

my $Data = {};

my $Zones = {
  ACSST => [+1, 10, 30, 'Australian Central Summer Standard Time'],
  ACST  => [+1,  9, 30, 'Australian Central Standard'],
  ADT   => [-1,  3,  0, 'Atlantic Daylight Time'], ## 733
  #ADT   => [-1, 04, 00, 'Brazil Acre Daylight Time'],
  AESST => [+1, 11,  0, 'Australian East Summer Standard Time'],
  AEST  => [+1, 10,  0, 'Australian East Standard Time'],
  AHST  => [-1, 10,  0, 'Alaska-Hawaii Standard Time'],
  AKST  => [-1,  9, 00, 'Alaska Standard Time'],
  AM    => [-1, 00, 00, 'After Morning'],
  AST   => [-1,  4,  0, 'Atlantic Standard Time'], ## 733
  #AST   => [-1, 05, 00, 'Brazil Acre Standard Time'],
  AT    => [-1,  2,  0, 'Azores Time'],
  AWSST => [+1,  9, 00, 'Australian West Summer Standard Time'],
  AWST  => [+1,  8, 00, 'Australian West Standard Time'],
  BDT   => [-1, 10,  0, 'Bering Daylight Time'], ## 733
  BST   => [-1, 11,  0, 'Bering Standard Time'], ## 733
  #BST   => [+1,  1,  0, 'British Summer Time'],
  #BST   => [-1,  3,  0, 'Brazil Standard Time'],
  #BST   => [+1, 03, 00, 'Baghdad Standard Time'],
  BT    => [+1, 03, 00, 'Baghdad Time'],
  CADT  => [+1, 10, 30, 'Central Australian Daylight Time'],
  CAST  => [+1,  9, 30, 'Central Australian Standard Time'],
  CAT   => [-1, 10, 00, 'Central Alaska Time'],
  CCT   => [+1,  8, 00, 'China Coastal Time'],
  CDT   => [-1, 05, 00, 'Central Daylight Time'], ## 733, 822
  #CDT   => [+1,  9, 00, "People's Republic of China Daylight Time"],
  #CDT   => [-1, 06, 00, 'Cuba Daylight Time'],
  #CDT   => [-1, 03, 00, 'Chile Continental Daylight Time'],
  CET   => [+1,  1,  0, 'Central European Time'],
  CETDST=> [+1, 02, 00, 'Central European Daylight Saving Time'],
  CEST  => [+1,  2,  0, 'Central European Daylight Time'],
  CST   => [-1,  6,  0, 'Central Standard Time'], ## 733, 822
  #CST   => [+1, 10, 30, 'Australian Central Standard Time'],
  #CST   => [+1,  8, 00, "People's Republic of China Standard Time"],
  #CST   => [-1, 05, 00, 'Cuba Standard Time'],
  #CST   => [-1, 04, 00, 'Chile Continental Standard Time'],
  DNT   => [+1, 01, 00, 'Dansk Normal Tid'],
  DST   => [-1, 00, 00, 'Daylight Saving Time'],
  EADT  => [+1, 11, 00, 'Eastern Australian Daylight Time'],
  EAST  => [+1, 10, 00, 'Eastern Australian Standard Time'],
  EASTERN => [-1, 0, 0, 'Eastern Time'],
  ECT   => [+1,  1,  0, 'Central European Time'],
  EDT   => [-1,  4,  0, 'Eastern Daylight Time'], ## 733, 822
  #EDT   => [-1, 02, 00, 'Brazil Eastern Daylight Time'],
  #EDT   => [-1, 05, 00, 'Chile Easter Island Daylight Time'],
  EEST  => [+1,  3,  0, 'Eastern European Summer Time'],
  EET   => [+1,  2,  0, 'Eastern Europe Time'], ## RFC 1947
  #EET   => [+1, 03, 00, 'Turkey Time'],
  EETDST=> [+1, 03, 00, 'Eastern European Dayright Saving Time'],
  EST   => [-1,  5,  0, 'Eastern Standard Time'], ## 733, 822
  #EST   => [+1, 10, 00, 'Eastern Australian Standard Time'],
  #EST   => [-1, 03, 00, 'Brazil Eastern Standard Time'],
  #EST   => [-1, 06, 00, 'Chile Easter Island Standard Time'],
  EWT   => [-1,  4,  0, 'U.S. Eastern War Time'],
  FDT   => [-1, 01, 00, 'Brazil De Noronha Daylight Time'],
  FST   => [+1,  2,  0, 'French Summer Time'],
  FDT   => [-1, 02, 00, 'Brazil De Noronha Standard Time'],
  FWT   => [+1,  1,  0, 'French Winter Time'],
  GDT   => [-1, 00, 00, 'Greenwich Daylight Time'], ## 724
  #GDT   => [+1,  2,  0, 'German Daylight Time'],
  GM    => [-1, 00, 00, undef],
  GMT   => [+1,  0,  0, 'Greenwich Mean Time'], ## 733, 822
  GST   => [-1,  3,  0, 'Greenland Standard Time'],
  #GST   => [+1,  1,  0, 'German Standard Time'],
  #GST   => [+1, 10,  0, 'Guam Standard Time'],
  HAST  => [-1, 10, 00, 'Hawaii and Alaska Standard Time'],
  HDT   => [-1,  9,  0, 'Hawaii/Alaska Daylight Time'], ## 733
  #HDT   => [-1, 10, 30, 'Hawaii Daylight Time'],
  HKT   => [+1,  8,  0, 'Hong Kong Time'],
  HST   => [-1, 10,  0, 'Hawaii Standard Time'], ## 733
  IDLE  => [+1, 12,  0, 'International Date Line, East'],
  IDLW  => [-1, 12,  0, 'International Date Line, West'],
  IDT   => [+1,  3,  0, 'Israel Daylight Time'], ## RFC 1555
  #IDT   => [+1, 04, 30, 'Iran Daylight Time'],
  IST   => [+1,  2,  0, 'Israel Standard Time'],
  #IST   => [+1, 05, 30, 'Indian Standard Time'],
  #IST   => [+1, 03, 30, 'Iran Standard Time'],
  IT    => [+1, 03, 30, 'Iran Time'],
  JCST  => [+1,  9, 00, 'Japan Central Standard Time'],
  JST   => [+1,  9, 00, 'Japan Central Standard Time'],
  JT    => [+1,  9, 00, 'Japan Central Standard Time'],
  #JT    => [+1, 07, 30, 'Java Time'],
  KDT   => [+1, 10, 00, 'Korean Daylight Time'],
  KST   => [+1,  9, 00, 'Korean Standard Time'],
  LCL   => [-1, 00, 00, undef], ## LSMTP unknown time zone
  LIGT  => [+1, 10, 00, 'Melbourne Time'],
  LOCAL => [-1, 00, 00, 'Local time zone'],
  LON   => [-1, 00, 00, undef],
  LT    => [-1,  0,  0, 'Luna Time'], ## RFC 1607
  MDT   => [-1,  6,  0, 'Mountain Daylight Time'], ## 733, 822
  MET   => [+1,  0,  0, 'Middle European Time'],
  #MET   => [+1, 01, 00, 'Medium European Time'],
  'MET DST' => [+1,  2,  0, 'Middle European Daylight Time'],
  METDST=> [+1,  2,  0, 'Middle European Daylight Time'],
  MEST  => [+1,  2,  0, 'Middle European Summer Time'],
  MEWT  => [+1,  0,  0, 'Middle European Winter Time'],
  MEZ   => [+1,  0,  0, 'Central European (German) Time'],
  MST   => [-1,  7,  0, 'Mountain Standard Time'], ## 733, 822
  MOUNTAIN=> [-1,  7,  0, 'Mountain Standard Time'],
  MT    => [+1,  8, 30, 'Moluccas Time'],
  #MT    => [-1,  0,  0, 'Mars Time'], ## RFC 1607
  NDT   => [-1,  2, 30, 'Newfoundland Daylight Time'],
  NFT   => [-1,  3, 30, 'Newfoundland Standard Time'],
  NOR   => [+1, 01, 00, 'Norway Standard Time'],
  NST   => [-1,  3, 30, 'Newfoundland Standard Time'], ## 733
  #NST   => [-1,  6, 30, 'North Sumatra Time'],
  #NST   => [-1, 11, 00, 'Nome Standard Time'],
  NT    => [-1, 11,  0, 'Nome Time'],
  NZD   => [+1, 13,  0, 'New Zealand Daylight Time'],
  NZT   => [+1, 12,  0, 'New Zealand Time'],
  NZDT  => [+1, 13,  0, 'New Zealand Daylight Time'],
  NZS   => [+1, 12,  0, 'New Zealand Standard Time'],
  NZST  => [+1, 12,  0, 'New Zealand Standard Time'],
  PDT   => [-1,  7,  0, 'Pacific Daylight Time'], ## 733, 822
  PM    => [-1, 00, 00, undef],
  PPET  => [-1, 07, 00, 'US Pacific New (Presidental Election Year) Time'],
  PST   => [-1,  8,  0, 'Pacific Standard Time'], ## 733, 822
  SADT  => [+1, 10, 30, 'South Australian Daylight Time'],
  SAMST => [+5,  0, 00, 'Samara Summer Time'],
  SAST  => [+1,  9, 30, 'South Australian Standard Time'],
  SAT   => [+1,  9, 30, 'South Australian Time'],
  SET   => [+1,  1,  0, 'Seychelles Time'],
  SST   => [+1,  2,  0, 'Swedish Summer Time'],
  #SST   => [+1,  7,  0, 'South Sumatra Time'],
  #SST   => [+1,  8, 00, 'Singapore Standard Time'],
  #SST   => [-1, 11, 00, 'US Samoa Standard Time'],
  SWT   => [+1,  1,  0, 'Swedish Winter Time'],
  UCT   => [+1, 00, 00, 'Coordinated Universal Time'],
  UKR   => [+1,  2,  0, 'Ukraine Time'],
  UNDEFINED => [-1,  0,  0, 'Undefined Time'],
  UT    => [+1,  0,  0, 'Universal Time'], ## 822
  UTC   => [+1,  0,  0, 'Coordinated Universal Time'],
  WADT  => [+1,  8, 00, 'West Australian Daylight Time'],
  WAST  => [+1, 07, 00, 'West Australian Standard Time'],
  WAT   => [-1,  0,  0, 'West Africa Time'],
  WDT   => [+1,  9, 00, 'West Australian Daylight Time'],
  #WDT   => [-1, 03, 00, 'Brazil Western Daylight Time'],
  WET   => [+1,  0,  0, 'Western European Time'],
  WETDST=> [+1, 01, 00, 'Western European Daylight Time'],
  WST   => [+1,  8,  0, 'West Australian Standard Time'],
  #WST   => [-1, 04, 00, 'Brazil Western Standard Time'],
  YDT   => [-1,  8,  0, 'Yukon Daylight Time'], ## 733
  YST   => [-1,  9,  0, 'Yukon Standard Time'], ## 733
  Z     => [+1,  0,  0, 'UTC'], ## 822, ISO 8601
  ZP4   => [+1,  4,  0, 'Z+4'],
  ZP5   => [+1,  5,  0, 'Z+5'],
  ZP6   => [+1,  6,  0, 'Z+6'],
}; # $Zones

for my $name (keys %$Zones) {
  my $def = $Zones->{$name};
  if ($def->[0] > 0) {
    $Data->{names}->{$name}->{offset} = $def->[0] * ($def->[1] * 60 * 60 + $def->[2] * 60);
  } else {
    $Data->{names}->{$name}->{offset_unknown} = 1;
  }
  $Data->{names}->{$name}->{label} = $def->[3] if defined $def->[3];
}

delete $Data->{names}->{$_}->{offset},
$Data->{names}->{$_}->{offset_unknown} = 1
    for 'A'..'Z';

$Data->{names}->{$_}->{conflicting} = 1
    for qw(ADT AST BST CDT CST EDT EET EST GDT GST HDT IDT IST JT
           MET MT NST SST WDT WST);

$Data->{names}->{$_}->{allowed_rfc822} = 1
    for qw(GMT UT EST EDT CST CDT MST MDT PST PDT), 'A'..'I', 'K'..'Z';
$Data->{names}->{$_}->{allowed_son_of_rfc1036} = 1
    for qw(GMT UT);
$Data->{names}->{$_}->{allowed_but_not_recommended_rss2} = 1
    for 'A'..'I', 'K'..'Y';
$Data->{names}->{$_}->{allowed_http} = 1
    for qw(GMT);

print perl2json_bytes_for_record $Data;

## License: Public Domain.
