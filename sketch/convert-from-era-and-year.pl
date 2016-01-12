use strict;
use warnings;
use Encode;
use Path::Tiny;
use JSON::PS;
binmode STDOUT, qw(:encoding(utf-8));

my $era = decode 'utf-8', shift;
my $year = shift;
die "Usage: perl $0 era year\n" unless defined $year;

my $json_path = path (__FILE__)->parent->parent->child ('local/era-year-offsets.json');
my $json = json_bytes2perl $json_path->slurp;

## "convert from era and year"

my $data = $json->{$era};
die "Era |$era| not found" unless defined $data;
my $ad_year = $data->{offset} + $year;

print "($era, $year) is AD $ad_year\n";

## License: Public Domain.
