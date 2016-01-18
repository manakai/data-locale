use strict;
use warnings;
use JSON::PS;

my $data = q{

y=-658
1 -658 2 1
2 -658 3 2
3 -658 4 1
4 -658 4 30

y=-650
1 -650 2 2
2 -650 3 4
3 -650 4 2

y=-641
8  -641 9 17
9  -641 10 17
10 -641 11 15
11 -641 12 15
12 -640 1 13

y=-640
1 -640 2 12
2 -640 3 13

y=-638
1 -638 1 21
2 -638 2 19
2' -638 3 21
3 -638 4 19

y=-634
1 -634 2 5
2 -634 3 7
3 -634 4 5

y=-614
1 -614 1 25
2 -614 2 24
3 -614 3 25
4 -614 4 24

y=-606
1 -606 1 27
2 -606 2 25
3 -606 3 27
4 -606 4 25

y=-570
1 -570 1 20
1' -570 2 19
2 -570 3 20

y=-541
9 -541 9 23
10 -541 10 22
11 -541 11 21
12 -541 12 20
12' -540 1 19

y=-540
1 -540 2 17
2 -540 3 18

y=-456
11 -456 12 11
12 -455 1 9

y=-455
1 -455 2 8
2 -455 3 10
3 -455 4 8
4 -455 5 8
5 -455 6 6
6 -455 7 6

y=-438
1 -438 1 31
2 -438 3 2
3 -438 4 1
4 -438 4 30

y=-410
4 -410 5 20
5 -410 6 19
6 -410 7 18
7 -410 8 17
8 -410 9 15
9 -410 10 15
10 -410 11 13
11 -410 12 13

y=-378
1 -378 1 28
2 -378 2 27
3 -378 3 28

y=-376
11 -376 11 27
12 -376 12 26

y=-375
1 -375 1 25
2 -375 2 23
3 -375 3 25
4 -375 4 23
5 -375 5 23
6 -375 6 21

y=-338
1 -338 2 5
2 -338 3 6
3 -338 4 5
4 -338 5 4

y=-318
1 -318 1 25
2 -318 2 23
3 -318 3 25
4 -318 4 23

y=-262
1 -262 2 6
2 -262 3 7
3 -262 4 6
4 -262 5 5

y=-231
5' -231 6 20
6 -231 7 20
7 -231 8 18
8 -231 9 17
9 -231 10 17
10 -231 11 15
11 -231 12 15
12 -230 1 13

y=-174
1 -174 1 25
2 -174 2 23
3 -174 3 25
4 -174 4 23

y=-130
1 -130 2 17
2 -130 3 19
3 -130 4 17

y=-122
1 -122 1 20
1' -122 2 19
2 -122 3 20

y=-102
1 -102 2 8
2 -102 3 9
3 -102 4 8
4 -102 5 7

y=-86
1 -86 2 12
2 -86 3 13
3 -86 4 12
4 -86 5 11

y=30
1 30 1 21
1' 30 2 19
2 30 3 21

y=42
1 42 2 7
2 42 3 8
3 42 4 7
4 42 5 6

y=134
1 134 2 10
2 134 3 12
3 134 4 10
4 134 5 10

y=206
1 206 1 27
2 206 2 25
3 206 3 27

y=230
1 230 1 31
2 230 3 2
3 230 3 31

y=314
1 314 2 3
2 314 3 4
3 314 4 3

y=350
1 350 1 26
2 350 2 24
3 350 3 26
4 350 4 24

y=356
11 356 12 10
12 357 1 8

y=357
1 357 2 7
2 357 3 8
3 357 4 7
4 357 5 6
5 357 6 5

y=456
10 456 11 15
11 456 12 14
12 457 1 13

y=457
1 457 2 11
2 457 3 13
3 457 4 11
4 457 5 11

y=470
1 470 2 18
2 470 3 19
3 470 4 18

y=514
1 514 2 12
2 514 3 14
3 514 4 12
4 514 5 12

y=558
12 558 12 28

y=559
1 559 1 26
2 559 2 25
3 559 3 26
4 559 4 25
5 559 5 24
5' 559 6 23

y=619
1 619 1 24
2 619 2 22
3 619 3 24
3' 619 4 23
4 619 5 22
5 619 6 21
6 619 7 20

};

my $Data = {};

$Data->{notes}->{"0619-03-01"}->{has_note} = 1;
$Data->{notes}->{"0619-03'-01"}->{has_note} = 1;

my $k_year;
for (split /\n/, $data) {
  if (/^y=(-?\d+)$/) {
    $k_year = $1;
  } elsif (/^(\d+)('|)\s+(-?\d+)\s+(\d+)\s+(\d+)\s*$/) {
    my $k_m = $1;
    my $k_m_leap = $2;
    my $g_day = sprintf '%04d-%02d-%02d', $3, $4, $5;
    $g_day =~ s/^-(\d{3})-/-0$1-/;
    my $k_day = sprintf '%04d-%02d%s-%02d',
        $k_year, $k_m, $k_m_leap ? "'" : '', 1;
    $k_day =~ s/^-(\d{3})-/-0$1-/;
    $Data->{mapping}->{$g_day} = $k_day;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.

