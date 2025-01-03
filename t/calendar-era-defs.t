#!/bin/sh
echo "1..248"
basedir=`dirname $0`/..
jq=$basedir/local/bin/jq

test() {
  (cat $basedir/data/calendar/era-defs.json | $jq "$2" | sh && echo "ok $1") || echo "not ok $1"
}

test 1 '.eras["承和"].key == "承和"'
test 2 '.eras["承和"].start_year == 834'
test 3 '.eras["承和"].start_day.julian == "0834-02-14"'
test 4 '.eras["承和"].start_day.julian_era == "承和1-02-14"'
test 5 '.eras["承和"].start_day.kyuureki == "0834-01-03"'
test 6 '.eras["承和"].start_day.kyuureki_era == "承和1-01-03"'
test 7 '.eras["承和"].official_start_day.kyuureki == "0834-01-01"'
test 8 '.eras["承和"].official_start_day.kyuureki_era == "承和1-01-01"'
test 9 '.eras["承和"].end_year == 848'
test 10 '.eras["承和"].end_day.julian == "0848-07-15"'
test 11 '.eras["承和"].end_day.julian_era == "承和15-07-15"'
test 12 '.eras["承和"].end_day.kyuureki == "0848-06-12"'
test 13 '.eras["承和"].end_day.kyuureki_era == "承和15-06-12"'
test 14 '.eras["承和"].actual_end_day.kyuureki == "0848-06-13"'
test 15 '.eras["承和"].actual_end_day.kyuureki_era == "承和15-06-13"'

test 16 '.eras["嘉保"].start_year == 1094'
test 17 '.eras["嘉保"].start_day.julian == "1095-01-23"'
test 18 '.eras["嘉保"].start_day.julian_era == "嘉保2-01-23"'
test 19 '.eras["嘉保"].start_day.kyuureki == "1094-12-15"'
test 20 '.eras["嘉保"].start_day.kyuureki_era == "嘉保1-12-15"'
test 21 '.eras["嘉保"].official_start_day.kyuureki == "1094-01-01"'
test 22 '.eras["嘉保"].official_start_day.kyuureki_era == "嘉保1-01-01"'
test 23 '.eras["嘉保"].end_year == 1096'
test 24 '.eras["嘉保"].end_day.julian == "1097-01-02"'
test 25 '.eras["嘉保"].end_day.julian_era == "嘉保4-01-02"'
test 26 '.eras["嘉保"].end_day.kyuureki == "1096-12-16"'
test 27 '.eras["嘉保"].end_day.kyuureki_era == "嘉保3-12-16"'
test 28 '.eras["嘉保"].actual_end_day.kyuureki == "1096-12-17"'
test 29 '.eras["嘉保"].actual_end_day.kyuureki_era == "嘉保3-12-17"'

test 30 '.eras["明治"].start_year == 1868'
test 31 '.eras["明治"].start_day.gregorian == "1868-10-23"'
test 32 '.eras["明治"].start_day.gregorian_era == "明治1-10-23"'
test 33 '.eras["明治"].start_day.kyuureki == "1868-09-08"'
test 34 '.eras["明治"].start_day.kyuureki_era == "明治1-09-08"'
test 35 '.eras["明治"].official_start_day.gregorian == "1868-01-25"'
test 36 '.eras["明治"].official_start_day.gregorian_era == "明治1-01-25"'
test 37 '.eras["明治"].official_start_day.kyuureki == "1868-01-01"'
test 38 '.eras["明治"].official_start_day.kyuureki_era == "明治1-01-01"'
test 39 '.eras["明治"].end_year == 1912'
test 40 '.eras["明治"].end_day.gregorian == "1912-07-29"'
test 41 '.eras["明治"].end_day.gregorian_era == "明治45-07-29"'
test 42 '.eras["明治"].actual_end_day.gregorian == "1912-07-30"'
test 43 '.eras["明治"].actual_end_day.gregorian_era == "明治45-07-30"'

test 44 '.eras["大正"].start_year == 1912'
test 45 '.eras["大正"].start_day.gregorian == "1912-07-30"'
test 46 '.eras["大正"].start_day.gregorian_era == "大正1-07-30"'
test 47 '.eras["大正"].official_start_day.gregorian == "1912-07-30"'
test 48 '.eras["大正"].official_start_day.gregorian_era == "大正1-07-30"'
test 49 '.eras["大正"].end_year == 1926'
test 50 '.eras["大正"].end_day.gregorian == "1926-12-24"'
test 51 '.eras["大正"].end_day.gregorian_era == "大正15-12-24"'
test 52 '.eras["大正"].actual_end_day.gregorian == "1926-12-25"'
test 53 '.eras["大正"].actual_end_day.gregorian_era == "大正15-12-25"'

test 54 '.eras["昭和"].start_year == 1926'
test 55 '.eras["昭和"].start_day.gregorian == "1926-12-25"'
test 56 '.eras["昭和"].start_day.gregorian_era == "昭和1-12-25"'
test 57 '.eras["昭和"].official_start_day.gregorian == "1926-12-25"'
test 58 '.eras["昭和"].official_start_day.gregorian_era == "昭和1-12-25"'
test 59 '.eras["昭和"].end_year == 1989'
test 60 '.eras["昭和"].end_day.gregorian == "1989-01-07"'
test 61 '.eras["昭和"].end_day.gregorian_era == "昭和64-01-07"'
test 62 '.eras["昭和"].actual_end_day.gregorian == "1989-01-07"'
test 63 '.eras["昭和"].actual_end_day.gregorian_era == "昭和64-01-07"'

test 64 '.eras["平成"].start_year == 1989'
test 65 '.eras["平成"].start_day.gregorian == "1989-01-08"'
test 66 '.eras["平成"].start_day.gregorian_era == "平成1-01-08"'
test 67 '.eras["平成"].official_start_day.gregorian == "1989-01-08"'
test 68 '.eras["平成"].official_start_day.gregorian_era == "平成1-01-08"'

test 69 '.eras["大化"].start_year == 645'
test 70 '.eras["大化"].start_day.julian == "0645-07-17"'
test 71 '.eras["大化"].start_day.julian_era == "大化1-07-17"'
test 72 '.eras["大化"].start_day.kyuureki == "0645-06-19"'
test 73 '.eras["大化"].start_day.kyuureki_era == "大化1-06-19"'
test 74 '.eras["大化"].start_kyuureki_day | not'
test 75 '.eras["大化"].start_julian_day | not'
test 76 '.eras["大化"].start_gregorian_day | not'
test 77 '.eras["大化"].official_start_day.kyuureki == "0645-01-01"'
test 78 '.eras["大化"].official_start_day.kyuureki_era == "大化1-01-01"'
test 79 '.eras["大化"].end_year == 650'
test 80 '.eras["大化"].actual_end_day.kyuureki_era == "大化6-02-15"'
test 81 '.eras["大化"].end_kyuureki_day | not'
test 82 '.eras["大化"].end_julian_day | not'
test 83 '.eras["大化"].north_start_day | not'
test 84 '.eras["大化"].south_start_day | not'
test 85 '.eras["大化"].north_end_day | not'
test 86 '.eras["大化"].south_end_day | not'

test 87 '.eras["白雉"].start_year == 650'
test 88 '.eras["白雉"].start_day.kyuureki == "0650-02-15"'
test 89 '.eras["白雉"].end_year == 654'
test 90 '.eras["白雉"].end_day.kyuureki_era == "白雉5-12-30"'
test 91 '.eras["白雉"].end_day.julian_era == "白雉6-02-11"'
test 92 '.eras["白雉"].end_day.gregorian_era == "白雉6-02-14"'
test 93 '.eras["白雉"].end_kyuureki_day | not'
test 94 '.eras["白雉"].actual_end_kyuureki_day | not'

test 95 '.eras["皇極天皇"].start_year == 642'
test 96 '.eras["皇極天皇"].start_day.kyuureki == "0642-01-01"'
test 97 '.eras["皇極天皇"].start_day.julian == "0642-02-05"'
test 98 '.eras["皇極天皇"].start_day.gregorian == "0642-02-08"'
test 99 '.eras["皇極天皇"].end_year == 645'
test 100 '.eras["皇極天皇"].end_day.kyuureki_era == "皇極天皇4-06-18"'
test 101 '.eras["皇極天皇"].actual_end_day.kyuureki_era == "皇極天皇4-06-19"'
test 102 '.eras["皇極天皇"].end_kyuureki_day | not'
test 103 '.eras["皇極天皇"].end_julian_day | not'
test 104 '.eras["皇極天皇"].end_gregorian_day | not'
test 105 '.eras["皇極天皇"].north_start_day | not'
test 106 '.eras["皇極天皇"].south_start_day | not'
test 107 '.eras["皇極天皇"].north_end_day | not'
test 108 '.eras["皇極天皇"].south_end_day | not'

test 109 '.eras["元徳"].start_year == 1329'
test 110 '.eras["元徳"].north_start_year == 1329'
test 111 '.eras["元徳"].south_start_year == 1329'
test 112 '.eras["元徳"].north_start_day.kyuureki == "1329-08-29"'
test 113 '.eras["元徳"].south_start_day.kyuureki == "1329-08-29"'
test 114 '.eras["元徳"].end_year == 1332'
test 115 '.eras["元徳"].north_end_year == 1332'
test 116 '.eras["元徳"].south_end_year == 1331'
test 117 '.eras["元徳"].north_end_day.julian == "1332-05-22"'
test 118 '.eras["元徳"].south_end_day.julian == "1331-09-10"'

test 119 '.eras["元弘"].start_year == 1331'
test 120 '.eras["元弘"].end_year == 1334'
test 121 '.eras["元弘"].south_start_year == 1331'
test 122 '.eras["元弘"].south_start_day.kyuureki == "1331-08-09"'
test 123 '.eras["元弘"].south_end_year == 1334'
test 124 '.eras["元弘"].south_end_day.kyuureki == "1334-01-28"'
test 125 '.eras["元弘"].north_start_year == 1333'
test 126 '.eras["元弘"].north_start_day.kyuureki == "1333-05-25"'
test 127 '.eras["元弘"].north_start_day.kyuureki_era == "元弘3-05-25"'
test 128 '.eras["元弘"].north_end_year == 1334'
test 129 '.eras["元弘"].north_end_day.kyuureki == "1334-01-28"'

test 130 '.eras["建武"].start_year == 1334'
test 131 '.eras["建武"].north_start_year == 1334'
test 132 '.eras["建武"].south_start_year == 1334'
test 133 '.eras["建武"].north_start_day.kyuureki == "1334-01-29"'
test 134 '.eras["建武"].south_start_day.kyuureki == "1334-01-29"'
test 135 '.eras["建武"].end_year == 1338'
test 136 '.eras["建武"].north_end_year == 1338'
test 137 '.eras["建武"].south_end_year == 1336'
test 138 '.eras["建武"].north_end_day.kyuureki == "1338-08-27"'
test 139 '.eras["建武"].south_end_day.kyuureki == "1336-02-28"'

test 140 '.eras["正平"].start_year == 1346'
test 141 '.eras["正平"].end_year == 1370'
test 142 '.eras["正平"].south_start_year == 1346'
test 143 '.eras["正平"].south_start_day.kyuureki == "1346-12-08"'
test 144 '.eras["正平"].south_end_year == 1370'
test 145 '.eras["正平"].south_end_day.kyuureki == "1370-02-04"'
test 146 '.eras["正平"].north_start_year | not'
test 147 '.eras["正平"].north_start_day | not'
test 148 '.eras["正平"].north_end_year | not'
test 149 '.eras["正平"].north_end_day | not'

test 150 '.eras["観応"].start_year == 1350'
test 151 '.eras["観応"].end_year == 1352'
test 152 '.eras["観応"].south_start_year | not'
test 153 '.eras["観応"].south_start_day | not'
test 154 '.eras["観応"].south_end_year | not'
test 155 '.eras["観応"].south_end_day | not'
test 156 '.eras["観応"].north_start_year == 1350'
test 157 '.eras["観応"].north_start_day.kyuureki == "1350-02-27"'
test 158 '.eras["観応"].north_end_year == 1352'
test 159 '.eras["観応"].north_end_day.julian == "1352-11-03"'

test 160 '.eras["天授"].start_year == 1375'
test 161 '.eras["天授"].end_year == 1381'
test 162 '.eras["天授"].south_start_year == 1375'
test 163 '.eras["天授"].south_start_day.kyuureki == "1375-05-27"'
test 164 '.eras["天授"].south_end_year == 1381'
test 165 '.eras["天授"].south_end_day.kyuureki == "1381-02-09"'
test 166 '.eras["天授"].north_start_year | not'
test 167 '.eras["天授"].north_start_day | not'
test 168 '.eras["天授"].north_end_year | not'
test 169 '.eras["天授"].north_end_day | not'

test 170 '.eras["元中"].start_year == 1384'
test 171 '.eras["元中"].end_year == 1392'
test 172 '.eras["元中"].south_start_year == 1384'
test 173 '.eras["元中"].south_start_day.kyuureki == "1384-04-28"'
test 174 '.eras["元中"].south_end_year == 1392'
test 175 '.eras["元中"].south_end_day.kyuureki == "1392-10'"'"'-04"'
test 176 '.eras["元中"].north_start_year | not'
test 177 '.eras["元中"].north_end_year | not'

test 178 '.eras["明徳"].start_year == 1390'
test 179 '.eras["明徳"].end_year == 1394'
test 180 '.eras["明徳"].north_start_year == 1390'
test 181 '.eras["明徳"].south_start_year == 1392'
test 182 '.eras["明徳"].north_start_day.kyuureki == "1390-03-26"'
test 183 '.eras["明徳"].south_start_day.kyuureki == "1392-10'"'"'-05"'
test 184 '.eras["明徳"].north_end_day.kyuureki == "1394-07-04"'
test 185 '.eras["明徳"].south_end_day.kyuureki == "1394-07-04"'

test 186 '.eras["持統天皇"].end_day.kyuureki == "0697-07-29"'
test 187 '.eras["文武天皇"].start_day.kyuureki == "0697-08-01"'
test 188 '.eras["持統天皇"].official_end_day | not'
test 189 '.eras["文武天皇"].official_start_day.kyuureki == "0697-01-01"'

test 190 '.eras["大化"].code14 == 1'
test 191 '.eras["白鳳"].code14 | not'
test 192 '.eras["朱鳥"].code14 == 3'
test 193 '.eras["寿永"].code14 == 105'
test 194 '.eras["元暦"].code14 == 106'
test 195 '.eras["文治"].code14 == 107'
test 196 '.eras["元中"].code14 == 164'
test 197 '.eras["正慶"].code14 == 165'
test 198 '.eras["康応"].code14 == 180'
test 199 '.eras["明徳"].code14 == 181'
test 200 '.eras["平成"].code14 == 247'

test 201 '.eras["大化"].code15 == 1'
test 202 '.eras["白鳳"].code15 == 3'
test 203 '.eras["朱鳥"].code15 == 4'
test 204 '.eras["寿永"].code15 == 106'
test 205 '.eras["元暦"].code15 | not'
test 206 '.eras["文治"].code15 == 107'
test 207 '.eras["元中"].code15 == 164'
test 208 '.eras["正慶"].code15 == "北1"'
test 209 '.eras["康応"].code15 == "北16"'
test 210 '.eras["明徳"].code15 == 165'
test 211 '.eras["昭和"].code15 == 230'

test 212 '.eras["大化"].code10 == 0'
test 213 '.eras["平成"].code10 == 235'
test 214 '.eras["令和"].code10 == 236'

test 215 '.eras["弘和"].name_latn == "Kōwa"'
test 216 '.eras["永徳"].name_latn == "Eitoku"'

test 217 '.eras["昭和"].name_kana == "しょうわ"'
test 218 '.eras["昭和"].name_latn == "Shōwa"'

test 219 '.eras["宝亀"].end_day.kyuureki == "0780-12-30"'
test 220 '.eras["宝亀"].actual_end_day.kyuureki == "0781-01-01"'
test 221 '.eras["宝亀"].end_year == 780'

test 222 '.eras["嘉暦"].start_day.kyuureki == "1326-04-26"'
test 223 '.eras["嘉暦"].end_day.kyuureki == "1329-08-28"'
test 224 '.eras["嘉暦"].actual_end_day.kyuureki == "1329-08-29"'
test 225 '.eras["嘉暦"].north_start_day | not'
test 226 '.eras["嘉暦"].south_start_day | not'
test 227 '.eras["嘉暦"].north_end_day | not'
test 228 '.eras["嘉暦"].south_end_day | not'

test 229 '.eras["正慶"].north_start_day.kyuureki == "1332-04-28"'
test 230 '.eras["正慶"].north_end_day.kyuureki == "1333-05-24"'
test 231 '.eras["正慶"].north_actual_end_day.kyuureki == "1333-05-25"'
test 232 '.eras["正慶"].start_day.kyuureki == "1332-04-28"'
test 233 '.eras["正慶"].end_day.kyuureki == "1333-05-24"'
test 234 '.eras["正慶"].south_start_day | not'
test 235 '.eras["正慶"].south_end_day | not'

test 236 '.eras["明徳"].end_day.kyuureki == "1394-07-04"'

test 237 '.eras["応永"].start_day.kyuureki == "1394-07-05"'
test 238 '.eras["応永"].end_day.kyuureki == "1428-04-26"'
test 239 '.eras["応永"].actual_end_day.kyuureki == "1428-04-27"'
test 240 '.eras["応永"].north_start_day | not'
test 241 '.eras["応永"].south_start_day | not'
test 242 '.eras["応永"].north_end_day | not'
test 243 '.eras["応永"].south_end_day | not'

test 244 '.eras["元弘"].north_official_start_day.kyuureki == "1333-05-25"'
test 245 '.eras["元弘"].north_official_start_day.kyuureki_era == "元弘3-05-25"'
test 246 '.eras["元弘"].south_official_start_day.kyuureki == "1331-01-01"'
test 247 '.eras["明徳"].north_official_start_day.kyuureki == "1390-01-01"'
test 248 '.eras["明徳"].south_official_start_day.kyuureki == "1392-10'"'"'-05"'

## License: Public Domain.
