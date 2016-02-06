use strict;
use warnings;
use utf8;
use Encode;
use JSON::PS;

my $data = q{
1	%E7%94%B2	%E3%84%90%E3%84%A7%E3%84%9A%CB%87	ji%C7%8E	ciaeh43	gaap3	%E3%81%93%E3%81%86	k%C5%8D	%E3%81%8D%E3%81%AE%E3%81%88	kinoe	%EA%B0%91	gap	%E1%A0%A8%E1%A1%B3%E1%A0%A3%E1%A0%B8%E1%A0%A0%E1%A0%A9%E1%A1%A4%E1%A1%B3%E1%A0%B6%E1%A0%A0%E1%A0%A8	niowanggiyan	gi%C3%A1p
2	%E4%B9%99	%E3%84%A7%CB%87	y%C7%90	ieh43	jyut6	%E3%81%8A%E3%81%A4	otsu	%E3%81%8D%E3%81%AE%E3%81%A8	kinoto	%EC%9D%84	eul	%E1%A0%A8%E1%A1%B3%E1%A0%A3%E1%A1%A5%E1%A0%A3%E1%A0%A8	niohon	%E1%BA%A5t
3	%E4%B8%99	%E3%84%85%E3%84%A7%E3%84%A5%CB%87	b%C7%90ng	pin51	bing2	%E3%81%B8%E3%81%84	hei	%E3%81%B2%E3%81%AE%E3%81%88	hinoe	%EB%B3%91	byeong	%E1%A1%B6%E1%A1%A0%E1%A0%AF%E1%A1%A4%E1%A1%B3%E1%A0%B6%E1%A0%A0%E1%A0%A8	fulgiyan	b%C3%ADnh
4	%E4%B8%81	%E3%84%89%E3%84%A7%E3%84%A5	d%C4%ABng	ting44	ding1	%E3%81%A6%E3%81%84	tei	%E3%81%B2%E3%81%AE%E3%81%A8	hinoto	%EC%A0%95	jeong	%E1%A1%B6%E1%A1%A0%E1%A0%AF%E1%A0%A0%E1%A1%A5%E1%A1%A1%E1%A0%A8	fulah%C5%ABn	%C4%91inh
5	%E6%88%8A	%E3%84%A8%CB%8B	w%C3%B9	vu231	mou6	%E3%81%BC	bo	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%88	tsuchinoe	%EB%AC%B4	mu	%E1%A0%B0%E1%A1%A0%E1%A0%B8%E1%A0%A0%E1%A0%B6%E1%A0%A0%E1%A0%A8	suwayan	m%E1%BA%ADu
6	%E5%B7%B1	%E3%84%90%E3%84%A7%CB%87	j%C7%90	ci51	gei2	%E3%81%8D	ki	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%A8	tsuchinoto	%EA%B8%B0	gi	%E1%A0%B0%E1%A0%A3%E1%A1%A5%E1%A0%A3%E1%A0%A8	sohon	k%E1%BB%B7
7	%E5%BA%9A	%E3%84%8D%E3%84%A5	g%C4%93ng	keng44	gang1	%E3%81%93%E3%81%86	k%C5%8D	%E3%81%8B%E3%81%AE%E3%81%88	kanoe	%EA%B2%BD	gyeong	%E1%A1%A7%E1%A0%A0%E1%A0%A8%E1%A0%B6%E1%A0%A0%E1%A0%A8	%C5%A1anyan	canh
8	%E8%BE%9B	%E3%84%92%E3%84%A7%E3%84%A3	x%C4%ABn	sin44	san1	%E3%81%97%E3%82%93	shin	%E3%81%8B%E3%81%AE%E3%81%A8	kanoto	%EC%8B%A0	sin	%E1%A1%A7%E1%A0%A0%E1%A1%A5%E1%A1%A1%E1%A0%A8	%C5%A1ah%C5%ABn	t%C3%A2n
9	%E5%A3%AC	%E3%84%96%E3%84%A3%CB%8A	r%C3%A9n	nyin223	jam4	%E3%81%98%E3%82%93	jin	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%88	mizunoe	%EC%9E%84	im	%E1%A0%B0%E1%A0%A0%E1%A1%A5%E1%A0%A0%E1%A0%AF%E1%A1%B3%E1%A0%B6%E1%A0%A0%E1%A0%A8	sahaliyan	nh%C3%A2m
10	%E7%99%B8	%E3%84%8D%E3%84%A8%E3%84%9F%CB%87	gu%C7%90	kue51	gwai3	%E3%81%8D	ki	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%A8	mizunoto	%EA%B3%84	gye	%E1%A0%B0%E1%A0%A0%E1%A1%A5%E1%A0%A0%E1%A1%A5%E1%A1%A1%E1%A0%A8	sahah%C5%ABn	qu%C3%BD
};

my $data2 = q{
1	%E5%AD%90	%E3%84%97%CB%87	z%C7%90	zi2	%E3%81%97	shi	%E3%81%AD	ne	%EC%9E%90	ja	%E1%A0%AC%E1%A0%A4%E1%A0%AF%E1%A0%A4%E1%A0%AD%E1%A0%A0%E1%A0%A8%E1%A0%8E%E1%A0%A0	%E1%A0%B0%E1%A1%B3%E1%A0%A9%E1%A1%A4%E1%A1%9D%E1%A1%B5%E1%A1%B3	t%C3%AD
2	%E4%B8%91	%E3%84%94%E3%84%A1%CB%87	ch%C7%92u	cau2	%E3%81%A1%E3%82%85%E3%81%86	ch%C5%AB	%E3%81%86%E3%81%97	ushi	%EC%B6%95	chuk	%E1%A0%A6%E1%A0%AC%E1%A0%A1%E1%A0%B7	%E1%A1%B3%E1%A1%A5%E1%A0%A0%E1%A0%A8	s%E1%BB%ADu
3	%E5%AF%85	%E3%84%A7%E3%84%A3%CB%8A	y%C3%ADn	jan4	%E3%81%84%E3%82%93	in	%E3%81%A8%E3%82%89	tora	%EC%9D%B8	in	%E1%A0%AA%E1%A0%A0%E1%A0%B7%E1%A0%B0	%E1%A1%A8%E1%A0%A0%E1%A0%B0%E1%A1%A5%E1%A0%A0	d%E1%BA%A7n
4	%E5%8D%AF	%E3%84%87%E3%84%A0%CB%87	m%C7%8Eo	maau5	%E3%81%BC%E3%81%86	b%C5%8D	%E3%81%86	u	%EB%AC%98	myo	%E1%A0%B2%E1%A0%A0%E1%A0%A4%E1%A0%AF%E1%A0%A0%E1%A0%A2	%E1%A1%A4%E1%A1%A1%E1%A0%AF%E1%A0%AE%E1%A0%A0%E1%A1%A5%E1%A1%A1%E1%A0%A8	m%C3%A3o
5	%E8%BE%B0	%E3%84%94%E3%84%A3%CB%8A	ch%C3%A9n	san4	%E3%81%97%E3%82%93	shin	%E3%81%9F%E3%81%A4	tatsu	%EC%A7%84	jin	%E1%A0%AF%E1%A0%A4%E1%A0%A4	%E1%A0%AE%E1%A1%A0%E1%A1%A9%E1%A1%A0%E1%A1%B5%E1%A1%B3	th%C3%ACn
6	%E5%B7%B3	%E3%84%99%CB%8B	s%C3%AC	zi6	%E3%81%97	shi	%E3%81%BF	mi	%EC%82%AC	sa	%E1%A0%AE%E1%A0%A3%E1%A0%AD%E1%A0%A0%E1%A0%A2	%E1%A0%AE%E1%A1%9D%E1%A1%B3%E1%A1%A5%E1%A1%9D	t%E1%BB%8B
7	%E5%8D%88	%E3%84%A8%CB%87	w%C7%94	ng5	%E3%81%94	go	%E3%81%86%E3%81%BE	uma	%EC%98%A4	o	%E1%A0%AE%E1%A0%A3%E1%A0%B7%E1%A0%A2	%E1%A0%AE%E1%A0%A3%E1%A1%B5%E1%A1%B3%E1%A0%A8	ng%E1%BB%8D
8	%E6%9C%AA	%E3%84%A8%E3%84%9F%CB%8B	w%C3%A8i	mei6	%E3%81%B3	bi	%E3%81%B2%E3%81%A4%E3%81%98	hitsuji	%EB%AF%B8	mi	%E1%A0%AC%E1%A0%A3%E1%A0%A8%E1%A0%A2	%E1%A1%A5%E1%A0%A3%E1%A0%A8%E1%A1%B3%E1%A0%A8	m%C3%B9i
9	%E7%94%B3	%E3%84%95%E3%84%A3	sh%C4%93n	san1	%E3%81%97%E3%82%93	shin	%E3%81%95%E3%82%8B	saru	%EC%8B%A0	sin	%E1%A0%AA%E1%A0%A1%E1%A0%B4%E1%A0%A2%E1%A0%A8	%E1%A0%AA%E1%A0%A3%E1%A0%A8%E1%A1%B3%E1%A0%A3	th%C3%A2n
10	%E9%85%89	%E3%84%A7%E3%84%A1%CB%87	y%C7%92u	jau5	%E3%82%86%E3%81%86	y%C5%AB	%E3%81%A8%E3%82%8A	tori	%EC%9C%A0	yu	%E1%A0%B2%E1%A0%A0%E1%A0%AC%E1%A0%A2%E1%A0%B6%E1%A0%8E%E1%A0%A0	%E1%A0%B4%E1%A0%A3%E1%A1%B4%E1%A0%A3	d%E1%BA%ADu
11	%E6%88%8C	%E3%84%92%E3%84%A9	x%C5%AB	seot1	%E3%81%98%E3%82%85%E3%81%A4	jutsu	%E3%81%84%E3%81%AC	inu	%EC%88%A0	sul	%E1%A0%A8%E1%A0%A3%E1%A0%AC%E1%A0%A0%E1%A0%A2	%E1%A1%B3%E1%A0%A8%E1%A1%A9%E1%A0%A0%E1%A1%A5%E1%A1%A1%E1%A0%A8	tu%E1%BA%A5t
12	%E4%BA%A5	%E3%84%8F%E3%84%9E%CB%8B	h%C3%A0i	hoi6	%E3%81%8C%E3%81%84	gai	%E3%81%84	i	%ED%95%B4	hae	%E1%A0%AD%E1%A0%A0%E1%A0%AC%E1%A0%A0%E1%A0%A2	%E1%A1%A0%E1%A0%AF%E1%A1%A4%E1%A1%B3%E1%A0%B6%E1%A0%A0%E1%A0%A8	h%E1%BB%A3i
};

my $data3 = q{
1	%E7%94%B2%E5%AD%90	ji%C7%8E-z%C7%90	gapja	%EA%B0%91%EC%9E%90	kasshi	kinoe-ne	Gi%C3%A1p	T%C3%BD
2	%E4%B9%99%E4%B8%91	y%C7%90-ch%C7%92u	eulchuk	%EC%9D%84%EC%B6%95	itch%C5%AB	kinoto-ushi	%E1%BA%A4t	S%E1%BB%ADu
3	%E4%B8%99%E5%AF%85	b%C7%90ng-y%C3%ADn	byeongin	%EB%B3%91%EC%9D%B8	heiin	hinoe-tora	B%C3%ADnh	D%E1%BA%A7n
4	%E4%B8%81%E5%8D%AF	d%C4%ABng-m%C7%8Eo	jeongmyo	%EC%A0%95%EB%AC%98	teib%C5%8D	hinoto-u	%C4%90inh	M%C3%A3o
5	%E6%88%8A%E8%BE%B0	w%C3%B9-ch%C3%A9n	mujin	%EB%AC%B4%EC%A7%84	boshin	tsuchinoe-tatsu	M%E1%BA%ADu	Th%C3%ACn
6	%E5%B7%B1%E5%B7%B3	j%C7%90-s%C3%AC	gisa	%EA%B8%B0%EC%82%AC	kishi	tsuchinoto-mi	K%E1%BB%B7	T%E1%BB%B5
7	%E5%BA%9A%E5%8D%88	g%C4%93ng-w%C7%94	gyeongo	%EA%B2%BD%EC%98%A4	k%C5%8Dgo	kanoe-uma	Canh	Ng%E1%BB%8D
8	%E8%BE%9B%E6%9C%AA	x%C4%ABn-w%C3%A8i	sinmi	%EC%8B%A0%EB%AF%B8	shinbi	kanoto-hitsuji	T%C3%A2n	M%C3%B9i
9	%E5%A3%AC%E7%94%B3	r%C3%A9n-sh%C4%93n	imsin	%EC%9E%84%EC%8B%A0	jinshin	mizunoe-saru	Nh%C3%A2m	Th%C3%A2n
10	%E7%99%B8%E9%85%89	gu%C7%90-y%C7%92u	gyeyu	%EA%B3%84%EC%9C%A0	kiy%C5%AB	mizunoto-tori	Qu%C3%BD	D%E1%BA%ADu
11	%E7%94%B2%E6%88%8C	ji%C7%8E-x%C5%AB	gapsul	%EA%B0%91%EC%88%A0	k%C5%8Djutsu	kinoe-inu	Gi%C3%A1p	Tu%E1%BA%A5t
12	%E4%B9%99%E4%BA%A5	y%C7%90-h%C3%A0i	eulhae	%EC%9D%84%ED%95%B4	itsugai	kinoto-i	%C3%82t	H%E1%BB%A3i
13	%E4%B8%99%E5%AD%90	b%C7%90ng-z%C7%90	byeongja	%EB%B3%91%EC%9E%90	heishi	hinoe-ne	B%C3%ADnh	T%C3%BD
14	%E4%B8%81%E4%B8%91	d%C4%ABng-ch%C7%92u	jeongchuk	%EC%A0%95%EC%B6%95	teich%C5%AB	hinoto-ushi	%C4%90inh	S%E1%BB%ADu
15	%E6%88%8A%E5%AF%85	w%C3%B9-y%C3%ADn	muin	%EB%AC%B4%EC%9D%B8	boin	tsuchinoe-tora	M%E1%BA%ADu	D%E1%BA%A7n
16	%E5%B7%B1%E5%8D%AF	j%C7%90-m%C7%8Eo	gimyo	%EA%B8%B0%EB%AC%98	kib%C5%8D	tsuchinoto-u	K%E1%BB%B7	M%C3%A3o
17	%E5%BA%9A%E8%BE%B0	g%C4%93ng-ch%C3%A9n	gyeongjin	%EA%B2%BD%EC%A7%84	k%C5%8Dshin	kanoe-tatsu	Canh	Th%C3%ACn
18	%E8%BE%9B%E5%B7%B3	x%C4%ABn-s%C3%AC	sinsa	%EC%8B%A0%EC%82%AC	shinshi	kanoto-mi	T%C3%A2n	T%E1%BB%B5
19	%E5%A3%AC%E5%8D%88	r%C3%A9n-w%C7%94	imo	%EC%9E%84%EC%98%A4	jingo	mizunoe-uma	Nh%C3%A2m	Ng%E1%BB%8D
20	%E7%99%B8%E6%9C%AA	gu%C7%90-w%C3%A8i	gyemi	%EA%B3%84%EB%AF%B8	kibi	mizunoto-hitsuji	Qu%C3%BD	M%C3%B9i
21	%E7%94%B2%E7%94%B3	ji%C7%8E-sh%C4%93n	gapsin	%EA%B0%91%EC%8B%A0	k%C5%8Dshin	kinoe-saru	Gi%C3%A1p	Th%C3%A2n
22	%E4%B9%99%E9%85%89	y%C7%90-y%C7%92u	euryu	%EC%9D%84%EC%9C%A0	itsuy%C5%AB	kinoto-tori	%E1%BA%A4t	D%E1%BA%ADu
23	%E4%B8%99%E6%88%8C	b%C7%90ng-x%C5%AB	byeongsul	%EB%B3%91%EC%88%A0	heijutsu	hinoe-inu	B%C3%ADnh	Tu%E1%BA%A5t
24	%E4%B8%81%E4%BA%A5	d%C4%ABng-h%C3%A0i	jeonghae	%EC%A0%95%ED%95%B4	teigai	hinoto-i	%C4%90inh	H%E1%BB%A3i
25	%E6%88%8A%E5%AD%90	w%C3%B9-z%C7%90	muja	%EB%AC%B4%EC%9E%90	boshi	tsuchinoe-ne	M%E1%BA%ADu	T%C3%BD
26	%E5%B7%B1%E4%B8%91	j%C7%90-ch%C7%92u	gichuk	%EA%B8%B0%EC%B6%95	kich%C5%AB	tsuchinoto-ushi	K%E1%BB%B7	S%E1%BB%ADu
27	%E5%BA%9A%E5%AF%85	g%C4%93ng-y%C3%ADn	gyeongin	%EA%B2%BD%EC%9D%B8	k%C5%8Din	kanoe-tora	Canh	D%E1%BA%A7n
28	%E8%BE%9B%E5%8D%AF	x%C4%ABn-m%C7%8Eo	sinmyo	%EC%8B%A0%EB%AC%98	shinb%C5%8D	kanoto-u	T%C3%A2n	M%C3%A3o
29	%E5%A3%AC%E8%BE%B0	r%C3%A9n-ch%C3%A9n	imjin	%EC%9E%84%EC%A7%84	jinshin	mizunoe-tatsu	Nh%C3%A2m	Th%C3%ACn
30	%E7%99%B8%E5%B7%B3	gu%C7%90-s%C3%AC	gyesa	%EA%B3%84%EC%82%AC	kishi	mizunoto-mi	Qu%C3%BD	T%E1%BB%B5
31	%E7%94%B2%E5%8D%88	ji%C7%8E-w%C7%94	gabo	%EA%B0%91%EC%98%A4	k%C5%8Dgo	kinoe-uma	Gi%C3%A1p	Ng%E1%BB%8D
32	%E4%B9%99%E6%9C%AA	y%C7%90-w%C3%A8i	eulmi	%EC%9D%84%EB%AF%B8	itsubi	kinoto-hitsuji	%E1%BA%A4t	M%C3%B9i
33	%E4%B8%99%E7%94%B3	b%C7%90ng-sh%C4%93n	byeongsin	%EB%B3%91%EC%8B%A0	heishin	hinoe-saru	B%C3%ADnh	Th%C3%A2n
34	%E4%B8%81%E9%85%89	d%C4%ABng-y%C7%92u	jeongyu	%EC%A0%95%EC%9C%A0	teiy%C5%AB	hinoto-tori	%C4%90inh	D%E1%BA%ADu
35	%E6%88%8A%E6%88%8C	w%C3%B9-x%C5%AB	musul	%EB%AC%B4%EC%88%A0	bojutsu	tsuchinoe-inu	M%E1%BA%ADu	Tu%E1%BA%A5t
36	%E5%B7%B1%E4%BA%A5	j%C7%90-h%C3%A0i	gihae	%EA%B8%B0%ED%95%B4	kigai	tsuchinoto-i	K%E1%BB%B7	H%E1%BB%A3i
37	%E5%BA%9A%E5%AD%90	g%C4%93ng-z%C7%90	gyeongja	%EA%B2%BD%EC%9E%90	k%C5%8Dshi	kanoe-ne	Canh	T%C3%BD
38	%E8%BE%9B%E4%B8%91	x%C4%ABn-ch%C7%92u	sinchuk	%EC%8B%A0%EC%B6%95	shinch%C5%AB	kanoto-ushi	T%C3%A2n	S%E1%BB%ADu
39	%E5%A3%AC%E5%AF%85	r%C3%A9n-y%C3%ADn	imin	%EC%9E%84%EC%9D%B8	jin'in	mizunoe-tora	Nh%C3%A2m	D%E1%BA%A7n
40	%E7%99%B8%E5%8D%AF	gu%C7%90-m%C7%8Eo	gyemyo	%EA%B3%84%EB%AC%98	kib%C5%8D	mizunoto-u	Qu%C3%BD	M%C3%A3o
41	%E7%94%B2%E8%BE%B0	ji%C7%8E-ch%C3%A9n	gapjin	%EA%B0%91%EC%A7%84	k%C5%8Dshin	kinoe-tatsu	Gi%C3%A1p	Th%C3%ACn
42	%E4%B9%99%E5%B7%B3	y%C7%90-s%C3%AC	eulsa	%EC%9D%84%EC%82%AC	itsushi	kinoto-mi	%E1%BA%A4t	T%E1%BB%B5
43	%E4%B8%99%E5%8D%88	b%C7%90ng-w%C7%94	byeongo	%EB%B3%91%EC%98%A4	heigo	hinoe-uma	B%C3%ADnh	Ng%E1%BB%8D
44	%E4%B8%81%E6%9C%AA	d%C4%ABng-w%C3%A8i	jeongmi	%EC%A0%95%EB%AF%B8	teibi	hinoto-hitsuji	%C4%90inh	M%C3%B9i
45	%E6%88%8A%E7%94%B3	w%C3%B9-sh%C4%93n	musin	%EB%AC%B4%EC%8B%A0	boshin	tsuchinoe-saru	M%E1%BA%ADu	Th%C3%A2n
46	%E5%B7%B1%E9%85%89	j%C7%90-y%C7%92u	giyu	%EA%B8%B0%EC%9C%A0	kiy%C5%AB	tsuchinoto-tori	K%E1%BB%B7	D%E1%BA%ADu
47	%E5%BA%9A%E6%88%8C	g%C4%93ng-x%C5%AB	gyeongsul	%EA%B2%BD%EC%88%A0	k%C5%8Djutsu	kanoe-inu	Canh	Tu%E1%BA%A5t
48	%E8%BE%9B%E4%BA%A5	x%C4%ABn-h%C3%A0i	sinhae	%EC%8B%A0%ED%95%B4	shingai	kanoto-i	T%C3%A2n	H%E1%BB%A3i
49	%E5%A3%AC%E5%AD%90	r%C3%A9n-z%C7%90	imja	%EC%9E%84%EC%9E%90	jinshi	mizunoe-ne	Nh%C3%A2m	T%C3%BD
50	%E7%99%B8%E4%B8%91	gu%C7%90-ch%C7%92u	gyechuk	%EA%B3%84%EC%B6%95	kich%C5%AB	mizunoto-ushi	Qu%C3%BD	S%E1%BB%ADu
51	%E7%94%B2%E5%AF%85	ji%C7%8E-y%C3%ADn	gabin	%EA%B0%91%EC%9D%B8	k%C5%8Din	kinoe-tora	Gi%C3%A1p	D%E1%BA%A7n
52	%E4%B9%99%E5%8D%AF	y%C7%90-m%C7%8Eo	eulmyo	%EC%9D%84%EB%AC%98	itsub%C5%8D	kinoto-u	%E1%BA%A4t	M%C3%A3o
53	%E4%B8%99%E8%BE%B0	b%C7%90ng-ch%C3%A9n	byeongjin	%EB%B3%91%EC%A7%84	heishin	hinoe-tatsu	B%C3%ADnh	Th%C3%ACn
54	%E4%B8%81%E5%B7%B3	d%C4%ABng-s%C3%AC	jeongsa	%EC%A0%95%EC%82%AC	teishi	hinoto-mi	%C4%90inh	T%E1%BB%B5
55	%E6%88%8A%E5%8D%88	w%C3%B9-w%C7%94	muo	%EB%AC%B4%EC%98%A4	bogo	tsuchinoe-uma	M%E1%BA%ADu	Ng%E1%BB%8D
56	%E5%B7%B1%E6%9C%AA	j%C7%90-w%C3%A8i	gimi	%EA%B8%B0%EB%AF%B8	kibi	tsuchinoto-hitsuji	K%E1%BB%B7	M%C3%B9i
57	%E5%BA%9A%E7%94%B3	g%C4%93ng-sh%C4%93n	gyeongsin	%EA%B2%BD%EC%8B%A0	k%C5%8Dshin	kanoe-saru	Canh	Th%C3%A2n
58	%E8%BE%9B%E9%85%89	x%C4%ABn-y%C7%92u	sinyu	%EC%8B%A0%EC%9C%A0	shin'y%C5%AB	kanoto-tori	T%C3%A2n	D%E1%BA%ADu
59	%E5%A3%AC%E6%88%8C	r%C3%A9n-x%C5%AB	imsul	%EC%9E%84%EC%88%A0	jinjutsu	mizunoe-inu	Nh%C3%A2m	Tu%E1%BA%A5t
60	%E7%99%B8%E4%BA%A5	gu%C7%90-h%C3%A0i	gyehae	%EA%B3%84%ED%95%B4	kigai	mizunoto-i	Qu%C3%BD	H%E1%BB%A3i
};

my $data4 = q{
1	%E7%94%B2%E5%AD%90	%E3%81%8D%E3%81%AE%E3%81%88%E3%81%AD	%E3%81%8B%E3%81%A3%E3%81%97
2	%E4%B9%99%E4%B8%91	%E3%81%8D%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86%E3%81%97	%E3%81%84%E3%81%A3%E3%81%A1%E3%82%85%E3%81%86
3	%E4%B8%99%E5%AF%85	%E3%81%B2%E3%81%AE%E3%81%88%E3%81%A8%E3%82%89	%E3%81%B8%E3%81%84%E3%81%84%E3%82%93
4	%E4%B8%81%E5%8D%AF	%E3%81%B2%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86	%E3%81%A6%E3%81%84%E3%81%BC%E3%81%86
5	%E6%88%8A%E8%BE%B0	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%88%E3%81%9F%E3%81%A4	%E3%81%BC%E3%81%97%E3%82%93
6	%E5%B7%B1%E5%B7%B3	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%BF	%E3%81%8D%E3%81%97
7	%E5%BA%9A%E5%8D%88	%E3%81%8B%E3%81%AE%E3%81%88%E3%81%86%E3%81%BE	%E3%81%93%E3%81%86%E3%81%94
8	%E8%BE%9B%E6%9C%AA	%E3%81%8B%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%B2%E3%81%A4%E3%81%98	%E3%81%97%E3%82%93%E3%81%B3
9	%E5%A3%AC%E7%94%B3	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%88%E3%81%95%E3%82%8B	%E3%81%98%E3%82%93%E3%81%97%E3%82%93
10	%E7%99%B8%E9%85%89	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%A8%E3%82%8A	%E3%81%8D%E3%82%86%E3%81%86
11	%E7%94%B2%E6%88%8C	%E3%81%8D%E3%81%AE%E3%81%88%E3%81%84%E3%81%AC	%E3%81%93%E3%81%86%E3%81%98%E3%82%85%E3%81%A4
12	%E4%B9%99%E4%BA%A5	%E3%81%8D%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%84	%E3%81%84%E3%81%A4%E3%81%8C%E3%81%84
13	%E4%B8%99%E5%AD%90	%E3%81%B2%E3%81%AE%E3%81%88%E3%81%AD	%E3%81%B8%E3%81%84%E3%81%97
14	%E4%B8%81%E4%B8%91	%E3%81%B2%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86%E3%81%97	%E3%81%A6%E3%81%84%E3%81%A1%E3%82%85%E3%81%86
15	%E6%88%8A%E5%AF%85	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%88%E3%81%A8%E3%82%89	%E3%81%BC%E3%81%84%E3%82%93
16	%E5%B7%B1%E5%8D%AF	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86	%E3%81%8D%E3%81%BC%E3%81%86
17	%E5%BA%9A%E8%BE%B0	%E3%81%8B%E3%81%AE%E3%81%88%E3%81%9F%E3%81%A4	%E3%81%93%E3%81%86%E3%81%97%E3%82%93
18	%E8%BE%9B%E5%B7%B3	%E3%81%8B%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%BF	%E3%81%97%E3%82%93%E3%81%97
19	%E5%A3%AC%E5%8D%88	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%88%E3%81%86%E3%81%BE	%E3%81%98%E3%82%93%E3%81%94
20	%E7%99%B8%E6%9C%AA	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%B2%E3%81%A4%E3%81%98	%E3%81%8D%E3%81%B3
21	%E7%94%B2%E7%94%B3	%E3%81%8D%E3%81%AE%E3%81%88%E3%81%95%E3%82%8B	%E3%81%93%E3%81%86%E3%81%97%E3%82%93
22	%E4%B9%99%E9%85%89	%E3%81%8D%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%A8%E3%82%8A	%E3%81%84%E3%81%A4%E3%82%86%E3%81%86
23	%E4%B8%99%E6%88%8C	%E3%81%B2%E3%81%AE%E3%81%88%E3%81%84%E3%81%AC	%E3%81%B8%E3%81%84%E3%81%98%E3%82%85%E3%81%A4
24	%E4%B8%81%E4%BA%A5	%E3%81%B2%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%84	%E3%81%A6%E3%81%84%E3%81%8C%E3%81%84
25	%E6%88%8A%E5%AD%90	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%88%E3%81%AD	%E3%81%BC%E3%81%97
26	%E5%B7%B1%E4%B8%91	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86%E3%81%97	%E3%81%8D%E3%81%A1%E3%82%85%E3%81%86
27	%E5%BA%9A%E5%AF%85	%E3%81%8B%E3%81%AE%E3%81%88%E3%81%A8%E3%82%89	%E3%81%93%E3%81%86%E3%81%84%E3%82%93
28	%E8%BE%9B%E5%8D%AF	%E3%81%8B%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86	%E3%81%97%E3%82%93%E3%81%BC%E3%81%86
29	%E5%A3%AC%E8%BE%B0	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%88%E3%81%9F%E3%81%A4	%E3%81%98%E3%82%93%E3%81%97%E3%82%93
30	%E7%99%B8%E5%B7%B3	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%BF	%E3%81%8D%E3%81%97
31	%E7%94%B2%E5%8D%88	%E3%81%8D%E3%81%AE%E3%81%88%E3%81%86%E3%81%BE	%E3%81%93%E3%81%86%E3%81%94
32	%E4%B9%99%E6%9C%AA	%E3%81%8D%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%B2%E3%81%A4%E3%81%98	%E3%81%84%E3%81%A4%E3%81%B3
33	%E4%B8%99%E7%94%B3	%E3%81%B2%E3%81%AE%E3%81%88%E3%81%95%E3%82%8B	%E3%81%B8%E3%81%84%E3%81%97%E3%82%93
34	%E4%B8%81%E9%85%89	%E3%81%B2%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%A8%E3%82%8A	%E3%81%A6%E3%81%84%E3%82%86%E3%81%86
35	%E6%88%8A%E6%88%8C	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%88%E3%81%84%E3%81%AC	%E3%81%BC%E3%81%98%E3%82%85%E3%81%A4
36	%E5%B7%B1%E4%BA%A5	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%84	%E3%81%8D%E3%81%8C%E3%81%84
37	%E5%BA%9A%E5%AD%90	%E3%81%8B%E3%81%AE%E3%81%88%E3%81%AD	%E3%81%93%E3%81%86%E3%81%97
38	%E8%BE%9B%E4%B8%91	%E3%81%8B%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86%E3%81%97	%E3%81%97%E3%82%93%E3%81%A1%E3%82%85%E3%81%86
39	%E5%A3%AC%E5%AF%85	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%88%E3%81%A8%E3%82%89	%E3%81%98%E3%82%93%E3%81%84%E3%82%93
40	%E7%99%B8%E5%8D%AF	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86	%E3%81%8D%E3%81%BC%E3%81%86
41	%E7%94%B2%E8%BE%B0	%E3%81%8D%E3%81%AE%E3%81%88%E3%81%9F%E3%81%A4	%E3%81%93%E3%81%86%E3%81%97%E3%82%93
42	%E4%B9%99%E5%B7%B3	%E3%81%8D%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%BF	%E3%81%84%E3%81%A3%E3%81%97
43	%E4%B8%99%E5%8D%88	%E3%81%B2%E3%81%AE%E3%81%88%E3%81%86%E3%81%BE	%E3%81%B8%E3%81%84%E3%81%94
44	%E4%B8%81%E6%9C%AA	%E3%81%B2%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%B2%E3%81%A4%E3%81%98	%E3%81%A6%E3%81%84%E3%81%B3
45	%E6%88%8A%E7%94%B3	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%88%E3%81%95%E3%82%8B	%E3%81%BC%E3%81%97%E3%82%93
46	%E5%B7%B1%E9%85%89	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%A8%E3%82%8A	%E3%81%8D%E3%82%86%E3%81%86
47	%E5%BA%9A%E6%88%8C	%E3%81%8B%E3%81%AE%E3%81%88%E3%81%84%E3%81%AC	%E3%81%93%E3%81%86%E3%81%98%E3%82%85%E3%81%A4
48	%E8%BE%9B%E4%BA%A5	%E3%81%8B%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%84	%E3%81%97%E3%82%93%E3%81%8C%E3%81%84
49	%E5%A3%AC%E5%AD%90	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%88%E3%81%AD	%E3%81%98%E3%82%93%E3%81%97
50	%E7%99%B8%E4%B8%91	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86%E3%81%97	%E3%81%8D%E3%81%A1%E3%82%85%E3%81%86
51	%E7%94%B2%E5%AF%85	%E3%81%8D%E3%81%AE%E3%81%88%E3%81%A8%E3%82%89	%E3%81%93%E3%81%86%E3%81%84%E3%82%93
52	%E4%B9%99%E5%8D%AF	%E3%81%8D%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%86	%E3%81%84%E3%81%A4%E3%81%BC%E3%81%86
53	%E4%B8%99%E8%BE%B0	%E3%81%B2%E3%81%AE%E3%81%88%E3%81%9F%E3%81%A4	%E3%81%B8%E3%81%84%E3%81%97%E3%82%93
54	%E4%B8%81%E5%B7%B3	%E3%81%B2%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%BF	%E3%81%A6%E3%81%84%E3%81%97
55	%E6%88%8A%E5%8D%88	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%88%E3%81%86%E3%81%BE	%E3%81%BC%E3%81%94
56	%E5%B7%B1%E6%9C%AA	%E3%81%A4%E3%81%A1%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%B2%E3%81%A4%E3%81%98	%E3%81%8D%E3%81%B3
57	%E5%BA%9A%E7%94%B3	%E3%81%8B%E3%81%AE%E3%81%88%E3%81%95%E3%82%8B	%E3%81%93%E3%81%86%E3%81%97%E3%82%93
58	%E8%BE%9B%E9%85%89	%E3%81%8B%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%A8%E3%82%8A	%E3%81%97%E3%82%93%E3%82%86%E3%81%86
59	%E5%A3%AC%E6%88%8C	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%88%E3%81%84%E3%81%AC	%E3%81%98%E3%82%93%E3%81%98%E3%82%85%E3%81%A4
60	%E7%99%B8%E4%BA%A5	%E3%81%BF%E3%81%9A%E3%81%AE%E3%81%A8%E3%81%AE%E3%81%84	%E3%81%8D%E3%81%8C%E3%81%84
};

$data =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
$data = decode 'utf-8', $data;
$data2 =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
$data2 = decode 'utf-8', $data2;
$data3 =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
$data3 = decode 'utf-8', $data3;
$data4 =~ s/%([0-9A-Fa-f]{2})/pack 'C', hex $1/ge;
$data4 = decode 'utf-8', $data4;

my $Data = {};

for (split /\n/, $data) {
  next unless length;
  my ($index, $char, $zh_zhuyin, $zh_pinyin, $zh_wuupin, $zh_jyutping,
      $ja_on, $ja_on_latn, $ja_kun, $ja_kun_latn,
      $kr, $kr_latn,
      $manchu, $manchu_latn,
      $vi, $x) = split /\t/, $_;
  die $index if not defined $vi or defined $x;
  $Data->{heavenly_stems}->[$index-1] = {
    value => 0+$index,
    name => $char,
    zh_zhuyin => $zh_zhuyin,
    zh_pinyin => $zh_pinyin,
    #zh_wuupin => $zh_wuupin,
    #zh_jyutping => $zh_jyutping,
    ja_on => $ja_on,
    ja_on_latn => $ja_on_latn,
    ja_kun => $ja_kun,
    ja_kun_latn => $ja_kun_latn,
    kr => $kr,
    kr_latn => $kr_latn,
    manchu => $manchu,
    manchu_latn => $manchu_latn,
    vi => $vi,
    wref_ja => $char,
  };
}

for (split /\n/, $data2) {
  next unless length;
  my ($index, $char, $zh_zhuyin, $zh_pinyin, $zh_jyutping,
      $ja_on, $ja_on_latn, $ja_kun, $ja_kun_latn,
      $kr, $kr_latn,
      $manchu, $manchu_latn,
      $vi, $x) = split /\t/, $_;
  die $index if not defined $vi or defined $x;
  $Data->{earthly_branches}->[$index-1] = {
    value => 0+$index,
    name => $char,
    zh_zhuyin => $zh_zhuyin,
    zh_pinyin => $zh_pinyin,
    #zh_jyutping => $zh_jyutping,
    ja_on => $ja_on,
    ja_on_latn => $ja_on_latn,
    ja_kun => $ja_kun,
    ja_kun_latn => $ja_kun_latn,
    kr => $kr,
    kr_latn => $kr_latn,
    manchu => $manchu,
    manchu_latn => $manchu_latn,
    vi => $vi,
    wref_ja => ($char eq '子' ? $char.'_(十二支)' : $char),
  };
}

for (split /\n/, $data3) {
  next unless length;
  my ($index, $char, $zh_pinyin, $kr_latn, $kr,
      $ja_on_latn, $ja_kun_latn,
      $vi_1, $vi_2, $x) = split /\t/, $_;
  die $index if not defined $vi_2 or defined $x;
  $Data->{kanshi}->[$index-1] = {
    value => 0+$index,
    name => $char,
    zh_pinyin => $zh_pinyin,
    ja_on_latn => $ja_on_latn,
    ja_kun_latn => $ja_kun_latn,
    kr => $kr,
    kr_latn => $kr_latn,
    vi => "$vi_1 $vi_2",
  };
}

for (split /\n/, $data4) {
  next unless length;
  my ($index, $char, $ja_kun, $ja_on, $x) = split /\t/, $_;
  die $index if not defined $ja_on or defined $x;
  $Data->{kanshi}->[$index-1]->{ja_kun} = $ja_kun;
  $Data->{kanshi}->[$index-1]->{ja_on} = $ja_on;
  $Data->{kanshi}->[$index-1]->{wref_ja} = $char;
}

for my $key (qw(heavenly_stems earthly_branches kanshi)) {
  $Data->{name_lists}->{$key} = join ' ', map { $_->{name} } @{$Data->{$key}};
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
