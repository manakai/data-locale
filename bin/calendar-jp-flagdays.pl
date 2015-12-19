use strict;
use warnings;
use utf8;
use JSON::PS;
use Path::Tiny;

my $json = json_bytes2perl path (__FILE__)->parent->parent->child
    ('data/calendar/jp-holidays.json')->slurp;

my $Data = {};

for my $day (keys %$json) {
  my $name = $json->{$day};
  unless ($name eq '振替休日' or
          $name eq '国民の休日' or
          $name eq '一六日') { # or $name eq '日曜日'
    $Data->{$day} = 1;
  }
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.

