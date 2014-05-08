use strict;
use warnings;
use JSON::PS;

my $Data = {};

## <http://www.whatwg.org/specs/web-apps/current-work/#duration-time-component>
for ($Data->{component_scales} = {}) {
  $_->{W} = 604800;
  $_->{w} = 604800;
  $_->{D} = 86400;
  $_->{d} = 86400;
  $_->{H} = 3600;
  $_->{h} = 3600;
  $_->{M} = 60;
  $_->{m} = 60;
  $_->{S} = 1;
  $_->{s} = 1;
}

print perl2json_bytes_for_record $Data;

## License: Public Domain.
