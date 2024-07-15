use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::Encoding;
use Web::Encoding::Normalization qw(to_nfc);
binmode STDERR, qw(:encoding(utf-8));

require (path (__FILE__)->parent->child ("names.pl")->absolute);

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

  use POSIX;
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


my $root_path = path (__FILE__)->parent->parent;

my $Data = {};

my $Tags;
my $TagByKey = {};
{
  my $path = $root_path->child ('local/view/tags.json');
  $Tags = (json_bytes2perl $path->slurp)->{tags};
  for my $item (values %$Tags) {
    $TagByKey->{$item->{key}} = $item;
  }
}

## Japanese official eras && pre-大宝 emperor eras
for (
  ['src/wp-jp-eras.json', undef, 'name' => ['name', 'wref_ja']],
  ['local/era-defs-jp-emperor.json', 'eras', 'name' => ['name_ja', 'name_kana', 'offset', 'wref_ja', 'wref_en']],
  ['local/era-defs-jp-wp-en.json', 'eras', 'key' => ['wref_en']],
  ['local/era-yomi-list.json', 'eras', 'key' => ['ja_readings', '6034', '6036']],
) {
  my ($file_name, $first_level, $key_key, $data_keys) = @$_;
  my $path = $root_path->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  $json = $json->{$first_level} if defined $first_level;
  for my $key (keys %$json) {
    my $data = $json->{$key};
    next if not defined $data->{$key_key};
    $Data->{eras}->{$key}->{key} //= $data->{$key_key};
    $Data->{eras}->{$key}->{_LABELS} //= [{labels => [{reps => []}]}];
    for (@$data_keys) {
      if (defined $data->{$_}) {
        if ($_ eq 'name_ja' or $_ eq 'name') {
          my $name = $data->{$_};
          push @{$Data->{eras}->{$key}->{_LABELS}->[0]->{labels}->[0]->{reps}},
              {kind => 'name', type => 'han',
               lang => 'ja', value => $name};

          $name =~ s/摂政$// &&
          push @{$Data->{eras}->{$key}->{_LABELS}->[0]->{labels}},
              {reps => [{kind => 'name', type => 'han',
                         lang => 'ja', value => $name}]};

          $name =~ s/皇后$// &&
          push @{$Data->{eras}->{$key}->{_LABELS}->[0]->{labels}},
              {reps => [{kind => 'name', type => 'han',
                         lang => 'ja', value => $name}]};
          
          $name =~ s/天皇$// &&
          push @{$Data->{eras}->{$key}->{_LABELS}->[0]->{labels}},
              {reps => [{kind => 'name', type => 'han',
                         lang => 'ja', value => $name}]};

          $Data->{eras}->{$key}->{short_name} = $name
              unless $name eq $data->{$_};
        } elsif ($_ eq 'ja_readings') {
          push @{$Data->{eras}->{$key}->{_LABELS}->[0]->{labels}->[0]->{reps}},
              grep { not $_->{is_ja} }
              map { {%$_, kind => 'yomi', type => 'yomi',
                     insert_22hyphen => 1} } @{$data->{$_}};
        } elsif ($_ eq '6034' or $_ eq '6036') {
          my $s = $_;
          push @{$Data->{eras}->{$key}->{_LABELS}->[0]->{labels}->[0]->{reps}},
              map { {kind => 'yomi', type => 'yomi',
                     source => $s, value => $_} } $data->{$_};
        } elsif ($_ eq 'name_kana') {
          push @{$Data->{eras}->{$key}->{_LABELS}->[0]->{labels}->[0]->{reps}},
              map { {kind => 'yomi', type => 'yomi',
                     kana_modern => $_} } $data->{$_};
        } else {
          $Data->{eras}->{$key}->{$_} = $data->{$_};
        }
      }
    }
  } # $json
}

sub drop_kanshi ($) {
  my $name = shift;
  $name =~ s/\(\w+\)$//;
  return $name;
} # drop_kanshi

{
  my $path = $root_path->child ('src/era-ids-1.txt');
  for (split /\x0D?\x0A/, decode_web_utf8 $path->slurp) {
    if (/^\s*#/) {
      #
    } elsif (/^y~([1-9][0-9]*)\s+(\S+)\s+(?:(-?[0-9]+)|)$/) {
      my $id = 0+$1;
      my $key = $2;
      my $offset;
      $offset = 0+$3 if defined $3;

      die "Duplicate era key |$key|" if defined $Data->{eras}->{$key};
      $Data->{eras}->{$key} = my $data = {};
      $data->{id} = $id;
      $data->{key} = $key;
      $data->{_LABELS} //= [{labels => [{reps => []}]}];
      $data->{offset} = $offset if defined $offset;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

sub set_object_tag ($$) {
  my ($obj, $tkey) = @_;
  my $item = $TagByKey->{$tkey};
  die "Tag |$tkey| not defined", Carp::longmess unless defined $item;

  $obj->{tag_ids}->{$item->{id}} = $item->{key};
  for (qw(region_of group_of period_of)) {
    for (keys %{$item->{$_} or {}}) {
      my $item2 = $Tags->{$_};
      $obj->{tag_ids}->{$item2->{id}} = $item2->{key};
      if ($item2->{type} eq 'country') {
        for (keys %{$item2->{period_of} or {}}) {
          my $item3 = $Tags->{$_};
          $obj->{tag_ids}->{$item3->{id}} = $item3->{key};
        }
      }
    }
  }
  return $item;
} # set_object_tag

sub set_tag ($$) {
  my ($key, $tkey) = @_;
  return set_object_tag $Data->{eras}->{$key} ||= {}, $tkey;
} # set_tag

{
  use utf8;
  $Data->{eras}->{단기}->{key} = '단기';
  $Data->{eras}->{AD}->{key} = 'AD';
  $Data->{eras}->{단기}->{_LABELS} //= [{labels => [{reps => []}]}];
  $Data->{eras}->{AD}->{_LABELS} //= [{labels => [{reps => []}]}];
}

for (
  ['local/era-date-list.json' => ['_usages', map {
    ('jp_'.$_.'era', 'jp_emperor_era',
     'offset',
     'known_oldest_year', 'known_latest_year',
    );
  } '', 'north_', 'south_']],
  ['local/cn-ryuukyuu-era-list.json' => ['cn_ryuukyuu_era']],
) {
  my ($file_name, $data_keys) = @$_;
  my $path = $root_path->child ($file_name);
  my $json = json_bytes2perl $path->slurp;
  for my $key (keys %{$json->{eras}}) {
    my $data = $json->{eras}->{$key};
    for (@$data_keys) {
      $Data->{eras}->{$key}->{$_} = $data->{$_} if defined $data->{$_};
      use utf8;
      if ($data->{jp_era}) {
        set_tag $key, '日本';
        set_tag $key, '日本の公年号';
        set_tag $key, '日本の公年号 (南北朝を除く)';
      }
      if ($data->{jp_north_era}) {
        set_tag $key, '日本北朝';
        set_tag $key, '日本北朝の公年号';
      }
      if ($data->{jp_south_era}) {
        set_tag $key, '日本南朝';
        set_tag $key, '日本南朝の公年号';
      }
      if ($data->{jp_emperor_era}) {
        set_tag $key, '日本';
        set_tag $key, '天皇即位紀年 (古代)';
      }
    }
  } # $key

  push @{$Data->{_TRANSITIONS}}, @{$json->{_TRANSITIONS} or []};
}

{
  my $path = $root_path->child ('src/era-variants.txt');
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)\s*=\s*(\S+)$/) {
      my $variant = $1;
      my $key = $2;
      die "Era |$key| not defined" unless defined $Data->{eras}->{$key};

      my $name = drop_kanshi $variant;
      push @{$Data->{eras}->{$key}->{_LABELS}->[0]->{labels}->[0]->{reps}},
          {kind => 'name', type => 'han', value => $name};
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

for my $path (
  map { path ($_) }
  sort { $a cmp $b } 
  (glob $root_path->child ('src/era-data*.txt')),
  (glob $root_path->child ('intermediate/x4d/era-data-*.txt')),
  (glob $root_path->child ('intermediate/wikimedia/era-data-*.txt')),
) {
  my $key;
  my $prop;
  my $can_continue = 0;
  my $current_source;
  my $ln = 0;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    $ln++;
    if ($can_continue and /^\s+(\S.*)$/) {
      $Data->{_TRANSITIONS}->[-1]->[2] .= " " . $1;
      $can_continue = 1;
      next;
    } else {
      $can_continue = 0;
    }

    if (/^\s*#/) {
      #
    } elsif (/^%tag /) {
      #
    } elsif (/^\[(.+)\]$/) {
      $key = $1;
      die "Bad key [|$key|] (not defined) in |$path|"
          unless $Data->{eras}->{$key};
      undef $prop;
      undef $current_source;
    } elsif (/^def\[(.+)\]$/) {
      $key = $1;
      die "Bad key def[|$key|] (duplicate) in |$path|"
          if defined $Data->{eras}->{$key} and
             defined $Data->{eras}->{$key}->{key};
      undef $prop;
      undef $current_source;
      $Data->{eras}->{$key}->{key} = $1;
      $Data->{eras}->{$key}->{_LABELS} //= [{labels => [{reps => []}]}];
    } elsif (defined $key and /^(source)$/) {
      push @{$Data->{eras}->{$key}->{sources} ||= []}, $prop = {};
    } elsif (defined $prop and ref $prop eq 'HASH' and
             /^  (title|url):(.+)$/) {
      $prop->{$1} = $2;
    } elsif (defined $key and /^(wref_(?:ja|zh|en|ko|vi|es))\s+(.+)$/) {
      $Data->{eras}->{$key}->{$1} = $2;
    } elsif (defined $key and m{^wref\s*<?https://(zh-yue|zh-min-nan|zh-classical|zh|vi|es|en|ja)\.(wikipedia|wiktionary)\.org/wiki/([^/?#]+)>?\s*$}) {
      my $sd = $1;
      my $page = $2;
      #XXX
    } elsif (defined $key and /^\+?(?:name|abbr|acronym|expanded|bopomofo|pinyin|&)/) {
      names::parse_src_line ($_ => $Data->{eras}->{$key}->{_LABELS});
    } elsif (defined $key and /^(unicode)\s+(.+)$/) {
      $Data->{eras}->{$key}->{_LPROPS}->{$1} = $2;
      $Data->{eras}->{$key}->{_LPROPS}->{names}->{$2} = 1;
    } elsif (defined $key and /^(AD|BC|皇紀|皇紀前)(-?\d+)\s*=\s*(\d+)$/) {
      my $g_year = $2;
      if ($1 eq 'BC') {
        $g_year = 1 - $g_year;
      } elsif ($1 eq '皇紀') {
        $g_year -= 660;
      } elsif ($1 eq '皇紀前') {
        $g_year = 1 - $g_year - 660;
      }
      my $e_year = $3;
      $Data->{eras}->{$key}->{offset} = $g_year - $e_year;
    } elsif (defined $key and
             /^u\s+(-?[0-9]+)(?:-([0-9]+)('|)(?:-([0-9]+(?:\(\w\w\)|)|\w\w)|)|)(?:\s+(\w+)|)$/) {
      push @{$Data->{eras}->{$key}->{_usages} ||= []},
          [[0+$1, $2?0+$2:undef, $3?1:0, $4?$4:undef], $5];
    } elsif (defined $key and /^(sw)\s+(.+)$/) {
      $Data->{eras}->{$key}->{suikawiki} = $2;
    } elsif (defined $key and /^code\s+#(7|2)\s+(.)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = $2;
    } elsif (defined $key and /^code\s+#([1-9][0-9]*)\s+([0-9]+)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = 0+$2;
    } elsif (defined $key and /^code\s+#(20)\s+(-[0-9]+)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = 0+$2;
    } elsif (defined $key and /^code\s+#(16)\s+([A-Z])$/) {
      $Data->{eras}->{$key}->{'code' . $1} = $2;
    } elsif (defined $key and /^code\s+#([1-9][0-9]*)\s+(北[1-9][0-9]*)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = $2;
    } elsif (defined $key and /^code\s+#([1-9][0-9]*)\s+0x([0-9A-Fa-f]+)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = hex $2;
    } elsif (defined $key and /^code\s+#(22)\s+(1-13-[1-9][0-9]?)$/) {
      $Data->{eras}->{$key}->{'code' . $1} = $2;
    } elsif (defined $key and /^en\s+desc\s+(\S+(?: \S+)*)\s*$/) {
      $Data->{eras}->{$key}->{en_desc} = $1;
    } elsif (defined $key and /^tag\s+(\S.*\S|\S)\s*$/) {
      my $tkey = $1;
      set_tag $key => $tkey;
    } elsif (defined $key and /^tag\+country\s+(\S.*\S|\S)\s*$/) {
      my $tkey = $1;
      my $tag = set_tag $key => $tkey;
      $Data->{eras}->{$key}->{country_tag_id} = $tag->{id};
    } elsif (defined $key and /^tag\+monarch\s+(\S.*\S|\S)\s*$/) {
      my $tkey = $1;
      my $tag = set_tag $key => $tkey;
      $Data->{eras}->{$key}->{monarch_tag_id} = $tag->{id};

    } elsif (defined $key and /^s\s*#([\w_()]+)\s*<([^<>]+)>\s*"([^"]+)"\s*$/) {
      my $tkey = $1;
      my $url = $2;
      my $text = $3;
      $tkey =~ s/_/ /g;
      my $source = {tag => $tkey};
      push @{$Data->{eras}->{$key}->{_TEMP}->{sources} ||= []}, $source;
      $current_source = $source;

    } elsif (defined $key and defined $current_source and
             defined $current_source->{tag} and
             /^s\+(\S*)\s*$/) {
      my $x = $1;
      my @x = length $1 ? split /,/, $x : ($key);
      set_tag $_ => $current_source->{tag} for @x;
    } elsif (defined $key and /^<-(\S+)\s+->(\S+)\s+(\S.+\S)\s*$/) {
      push @{$Data->{_TRANSITIONS} ||= []}, [$1 => $2, $3, $current_source];
      $can_continue = 1;
    } elsif (defined $key and /^->(\S+)\s+<-(\S+)\s+(\S.+\S)\s*$/) {
      push @{$Data->{_TRANSITIONS} ||= []}, [$2 => $1, $3, $current_source];
      $can_continue = 1;
    } elsif (defined $key and /^(\+|)<-(\S+)\s+(\S.+\S)\s*$/) {
      push @{$Data->{_TRANSITIONS} ||= []}, [$2 => $key, $1.$3, $current_source];
      $can_continue = 1;
    } elsif (defined $key and /^->(\S+)\s+(\S.+\S)\s*$/) {
      push @{$Data->{_TRANSITIONS} ||= []}, [$key => $1, $2, $current_source];
      $can_continue = 1;
    } elsif (defined $key and /^><\s+(\S.+\S)\s*$/) {
      push @{$Data->{_TRANSITIONS} ||= []}, [$key => undef, $1, $current_source];
      $can_continue = 1;
      
    } elsif (/\S/) {
      die "$path: $ln: Bad line |$_|";
    } else {
      undef $current_source;
    }
  }
}

for (reverse
  'intermediate/wikimedia/wp-cn-eras.json',
  'intermediate/wikimedia/wp-mn-eras.json',
  'intermediate/wikimedia/wp-vn-eras.json',
  'intermediate/wikimedia/wp-tw-eras.json',
  'intermediate/wikimedia/wp-kr-eras.json',
  'intermediate/wikimedia/wp-jp-eras.json',
  'intermediate/wikimedia/wp-jpp-eras.json',
  'intermediate/wikimedia/wp-vi-cn-eras.json',
  'intermediate/wikimedia/wp-vi-vn-eras.json',
  'intermediate/wikimedia/wp-vi-jp-eras.json',
  'intermediate/wikimedia/wp-vi-kr-eras.json',
  'intermediate/wikimedia/wp-ko-mn-eras.json',
  'intermediate/wikimedia/wp-ko-kr-eras.json',
  'intermediate/wikimedia/wp-ko-krr-eras.json',
  'intermediate/wikimedia/wp-ko-cn-eras.json',
  'intermediate/wikimedia/wp-ko-jp-eras.json',
  'intermediate/wikimedia/wp-ko-vn-eras.json',
  'intermediate/wikimedia/wp-en-cn-eras.json',
  'intermediate/wikimedia/wp-en-vn-eras.json',
  'intermediate/wikimedia/wp-en-kr-eras.json',
  'intermediate/wikimedia/wp-en-jp-eras.json',
) {
  my $path = $root_path->child ($_);
  my $json = json_bytes2perl $path->slurp;
  my $wref_key = $json->{wref_key};
  my $default_wref = $json->{page_name};
  for my $src (@{$json->{eras}}) {
    next unless defined $src->{era_id};
    die "Era key for $src->{name} not defined" unless defined $src->{era_key};

    my $data = $Data->{eras}->{$src->{era_key}};
    die "$path: Bad era key |$src->{era_key}|" unless defined $data;

    $data->{$wref_key} //= $src->{wref} // $default_wref;

    my @rep;

    use utf8;
    next if $src->{name} eq '？？';
    if ($wref_key eq 'wref_zh') {
      push @rep,
          {kind => 'name', type => 'han', lang => 'tw', value => $src->{tw}}
          if defined $src->{tw};
      push @rep,
          {kind => 'name', type => 'han', lang => 'cn', value => $src->{cn}}
          if defined $src->{cn};
    } else {
      push @rep,
          {kind => 'name', type => 'han', lang => '', value => $src->{tw}}
          if defined $src->{tw};
      push @rep,
          {kind => 'name', type => 'han', lang => '', value => $src->{cn}}
          if defined $src->{cn};
      push @rep,
          {kind => 'name', type => 'han', lang => '', value => $src->{ja}}
          if defined $src->{ja};
    }
    push @rep,
        {kind => 'name', type => 'alphabetical', lang => 'vi',
         value => $src->{vi}}
        if defined $src->{vi};
    push @rep,
        {kind => 'name', type => 'korean', lang => 'kr',
         value => $src->{hangul}}
        if defined $src->{hangul};
    for (@{$src->{vn_hanguls} or []}) {
      push @rep,
          {kind => 'name', type => 'korean', lang => 'kr_vi',
           value => $_};
    };
    for (@{$src->{ja_hanguls} or []}) {
      use utf8;
      next if $_ eq '아카미도리';
      push @rep,
          {kind => 'name', type => 'korean', lang => 'kr_ja',
           value => $_};
    };
    push @rep,
        {kind => 'name', type => 'alphabetical', lang => 'en_kr',
         value => $src->{kr_latin}}
        if defined $src->{kr_latin};
    push @rep,
        {kind => 'name', type => 'alphabetical', lang => 'en_pinyin',
         value => $src->{en_pinyin}}
        if defined $src->{en_pinyin};
    push @rep,
        {kind => 'name', type => 'alphabetical', lang => 'en',
         value => $src->{en}}
        if defined $src->{en};
    push @rep,
        {kind => 'name', type => 'alphabetical', lang => 'en',
         value => $src->{en2}}
        if defined $src->{en2};

    unshift @{$data->{_LABELS}->[0]->{labels}->[0]->{reps}}, @rep;
  } # $src
}

{
  for (glob $root_path->child ('intermediate/x4d/*.json')) {
    my $path = path ($_);
    my $json = json_bytes2perl $path->slurp;
    for my $data (values %{$json->{eras}}) {
      my $era = $Data->{eras}->{$data->{key}} // die "Bad era";
      if (defined $data->{min}) {
        push @{$era->{_usages} ||= []}, [[$data->{min}]];
      }
      if (defined $data->{max}) {
        push @{$era->{_usages} ||= []}, [[$data->{max}]];
      }
      for (keys %{$data->{tag_keys} or {}}) {
        set_object_tag $era, $_;
      }
    }
  }
  for my $era (values %{$Data->{eras}}) {
    if (defined $era->{offset}) {
      for (@{$era->{_usages} or []}) {
        my $y = $era->{offset} + $_->[0]->[0];
        $era->{known_oldest_year} = $y if
            not defined $era->{known_oldest_year} or
            $era->{known_oldest_year} > $y;
        $era->{known_latest_year} = $y if
            not defined $era->{known_latest_year} or
            $era->{known_latest_year} < $y;
      }
    }
    delete $era->{_usages};
    if (not defined $era->{known_oldest_year} and
        defined $era->{offset}) {
      $era->{known_oldest_year} = $era->{offset} + 1;
    }
    if (defined $era->{known_oldest_year} and
        not defined $era->{known_latest_year}) {
      $era->{known_latest_year} = $era->{known_oldest_year};
    }
  } # $era
}

for my $era (values %{$Data->{eras}}) {
  use utf8;
  if ($era->{tag_ids}->{$TagByKey->{'日本の私年号'}->{id}}) {
    $era->{jp_private_era} = 1;
  }
}

{
  my $path = $root_path->child ('intermediate/era-ids.json');
  my $map = json_bytes2perl $path->slurp;
  my @need_id;
  my $max_id = 0;
  for my $data (sort { $a->{key} cmp $b->{key} } values %{$Data->{eras}}) {
    if (defined $data->{id} and $map->{$data->{key}} != $data->{id}) {
      die "$path: Era ID |$data->{id}|, key |$data->{key}| is not registered";
    }
    my $id = $map->{$data->{key}};
    if (defined $id) {
      $data->{id} = $id;
      $max_id = $id if $max_id < $id;
    } else {
      #push @{$Data->{_errors} ||= []}, "ID for key |$data->{key}| not defined";
      push @need_id, $data;
    }
  }
  for (@need_id) {
    $map->{$_->{key}} = $_->{id} = ++$max_id;
  }
  $path->spew (perl2json_bytes_for_record $map) if @need_id;
}

$Data->{current_jp} = '令和';

print perl2json_bytes_for_record $Data;

## License: Public Domain.
