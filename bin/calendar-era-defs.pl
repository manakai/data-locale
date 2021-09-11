use strict;
use warnings;
use utf8;
use Path::Tiny;
use lib glob path (__FILE__)->parent->child ('modules/*/lib');
use JSON::PS;
use Web::URL::Encoding;
binmode STDERR, qw(:encoding(utf-8));

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
  my $path = $root_path->child ('data/tags.json');
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
  my $path = $root_path->child ('intermediate/wp-cn-eras.json');
  my $json = json_bytes2perl $path->slurp;
  for my $src (@{$json->{eras}}) {
    next unless defined $src->{era_id};
    die "Era key for $src->{name} not defined" unless defined $src->{era_key};
    $Data->{eras}->{$src->{era_key}} = my $data = {};
    $data->{id} = $src->{era_id};
    $data->{key} = $src->{era_key};
    $data->{_LABELS} //= [{labels => [{reps => []}]}];
    $data->{offset} = $src->{offset} if defined $src->{offset};
    $data->{wref_zh} = $src->{wref} if defined $src->{wref};

    push @{$data->{_LABELS}->[0]->{labels}->[0]->{reps}},
        {kind => 'name', type => 'han', lang => 'tw', value => $src->{name}},
        {kind => 'name', type => 'han', lang => 'cn', value => $src->{cn}};
    
    warn "Wikipedia cn != my: $src->{cn} $src->{my}"
        if $src->{cn} ne $src->{my};
    warn "Wikipedia cn != sg: $src->{cn} $src->{sg}"
        if $src->{cn} ne $src->{sg};
    warn "Wikipedia tw != hk: $src->{tw} $src->{hk}"
        if $src->{tw} ne $src->{hk};
    warn "Wikipedia tw != mo: $src->{tw} $src->{mo}"
        if $src->{tw} ne $src->{mo};
  } # $src
}

for my $path (
  $root_path->child ('src/era-viet.txt'),
  $root_path->child ('src/era-korea.txt'),
) {
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^(\S+)(?:\s+(BC|)(\d+)|)(?:$|-)/) {
      my $first_year = defined $3 ? $2 ? 1 - $3 : $3 : undef;
      my @name = split /,/, $1;
      my @n;
      for (@name) {
        if (defined $Data->{name_to_key}->{jp}->{$_} or
            defined $Data->{eras}->{$_}) {
          die "Duplicate era |$_| ($_(@{[$first_year]})) in $path";
        } else {
          push @n, $_;
        }
      }
      next unless @n;
      my $d = $Data->{eras}->{$n[0]} ||= {};
      $d->{key} = $n[0];
      $d->{_LABELS} //= [{labels => [{reps => []}]}];
      if (defined $first_year) {
        $d->{offset} = $first_year - 1;
      }

      my @nn = map { drop_kanshi $_ } @n;
      push @{$d->{_LABELS}->[0]->{labels}->[0]->{reps}},
          {kind => 'name', type => 'han', value => $_} for @nn;
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

sub set_object_tag ($$) {
  my ($obj, $tkey) = @_;
  my $item = $TagByKey->{$tkey};
  die "Tag |$tkey| not defined" unless defined $item;

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
} # set_object_tag

sub set_tag ($$) {
  my ($key, $tkey) = @_;
  set_object_tag $Data->{eras}->{$key} ||= {}, $tkey;
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
  glob $root_path->child ('src/era-data*.txt')
) {
  my $key;
  my $prop;
  for (split /\x0D?\x0A/, $path->slurp_utf8) {
    if (/^\s*#/) {
      #
    } elsif (/^%tag /) {
      #
    } elsif (/^\[(.+)\]$/) {
      $key = $1;
      die "Bad key |$key|" unless $Data->{eras}->{$key};
      undef $prop;
    } elsif (/^def\[(.+)\]$/) {
      $key = $1;
      die "Bad key |$key|"
          if defined $Data->{eras}->{$key} and
             defined $Data->{eras}->{$key}->{key};
      undef $prop;
      $Data->{eras}->{$key}->{key} = $1;
      $Data->{eras}->{$key}->{_LABELS} //= [{labels => [{reps => []}]}];
    } elsif (defined $key and /^(source)$/) {
      push @{$Data->{eras}->{$key}->{sources} ||= []}, $prop = {};
    } elsif (defined $prop and ref $prop eq 'HASH' and
             /^  (title|url):(.+)$/) {
      $prop->{$1} = $2;
    } elsif (defined $key and /^(wref_(?:ja|zh|en|ko))\s+(.+)$/) {
      $Data->{eras}->{$key}->{$1} = $2;
    } elsif (defined $key and /^name(!|)\s+(\p{Han}+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name', type => 'han', value => $2, preferred => $1};
    } elsif (defined $key and /^name_kana\s+(.+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'yomi', type => 'yomi', kana_modern => $1};
    } elsif (defined $key and /^name_(ja|cn|tw|ko)(!|)\s+([\p{Han}]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name', type => 'han', lang => $1, value => $3,
           preferred => $2};
    } elsif (defined $key and /^name\((en|la|en_la|it|fr|es|po|vi|ja_latin|ja_latin_old)\)(!|)\s+([\p{Latn}\s%0-9A-F'-]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'alphabetical',
           lang => $1,
           preferred => $2,
           value => percent_decode_c $3};
    } elsif (defined $key and /^name\((ja)\)(!|)\s+([\p{Hiragana}\p{Katakana}\x{30FC}\N{KATAKANA MIDDLE DOT}\x{3001}\p{Han}\p{Latn}\[\]|:!,()\p{Geometric Shapes}\s]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'jpan',
           preferred => $2,
           value => $3};
    } elsif (defined $key and /^name\((cn|tw)\)(!|)\s+([\N{KATAKANA MIDDLE DOT}\p{Han}()]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'zh',
           lang => $1,
           preferred => $2,
           value => $3};
    } elsif (defined $key and /^name\((ko|kr|kp)\)(!|)\s+([\p{Hang}]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'korean',
           lang => $1,
           preferred => $2,
           value => $3};
    } elsif (defined $key and /^expanded\((en|la|en_la|it|fr|es|po|vi|ja_latin)\)\s+([\p{Latn}\s%0-9A-F'\[\]-]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'expanded',
           type => 'alphabetical',
           lang => $1,
           value => percent_decode_c $2};
    } elsif (defined $key and /^name_man\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([a-z%0-9A-F ]+),([a-z ]+),([a-z'%0-9A-F ]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'manchu',
           manchu => (percent_decode_c $1),
           moellendorff => (percent_decode_c $2),
           abkai => $3,
           xinmanhan => (percent_decode_c $4)};
    } elsif (defined $key and /^name_man\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([a-z%0-9A-F ]+),([a-z ]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'manchu',
           manchu => (percent_decode_c $1),
           moellendorff => (percent_decode_c $2),
           abkai => $3};
    } elsif (defined $key and /^name_man\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([a-z%0-9A-F ]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'manchu',
           manchu => (percent_decode_c $1),
           moellendorff => (percent_decode_c $2)};
    } elsif (defined $key and /^name_man\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'manchu',
           manchu => (percent_decode_c $1)};
    } elsif (defined $key and /^name_mn\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([\p{Cyrl}%0-9A-F ]+),([a-z%0-9A-F ]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'mongolian',
           mongolian => (percent_decode_c $1),
           cyrillic => (percent_decode_c $2),
           vpmc => (percent_decode_c $3)};
    } elsif (defined $key and /^name_mn\s+((?:%[0-9A-F]{2})+(?: (?:%[0-9A-F]{2})+)*),([\p{Cyrl}%0-9A-F ]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'mongolian',
           mongolian => (percent_decode_c $1),
           cyrillic => (percent_decode_c $2)};
    } elsif (defined $key and /^abbr_(ja|tw)\s+(\p{Hani})\s+(\2\p{Hani}*)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name', abbr => 'single', type => 'han',
           lang => $1, value => $2},
          {kind => 'expanded',
           to_abbr => 'single',
           type => 'han',
           lang => $1,
           value => percent_decode_c $3};
    } elsif (defined $key and /^abbr_(ja|tw)\s+(\p{Hani})\s+(\p{Hani}*)\[(\p{Hani})\](\p{Hani}*)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name', abbr => 'single', type => 'han',
           lang => $1, value => $2},
          {kind => 'expanded',
           to_abbr => 'single',
           type => 'han',
           lang => $1,
           value => $3.$4.$5,
           abbr_index => length $3};
    } elsif (defined $key and /^acronym\((en|la|en_la|it|fr|es|po|vi|ja_latin)\)\s+([\p{Latn}.\N{KATAKANA MIDDLE DOT}%0-9A-F]+)$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}->[-1]->{reps}},
          {kind => 'name',
           type => 'alphabetical',
           abbr => 'acronym',
           lang => $1,
           value => percent_decode_c $2};
    } elsif (defined $key and /^&$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}->[-1]->{labels}},
          {reps => []};
    } elsif (defined $key and /^&&$/) {
      push @{$Data->{eras}->{$key}->{_LABELS}},
          {labels => [{reps => []}]};
    } elsif (defined $key and /^(unicode)\s+(.+)$/) {
      $Data->{eras}->{$key}->{$1} = $2;
      $Data->{eras}->{$key}->{names}->{$2} = 1;
    } elsif (defined $key and /^(AD|BC)(-?\d+)\s*=\s*(\d+)$/) {
      my $g_year = $1 eq 'BC' ? 1 - $2 : $2;
      my $e_year = $3;
      $Data->{eras}->{$key}->{offset} = $g_year - $e_year;
    } elsif (defined $key and
             /^u\s+(-?[0-9]+)(?:-([0-9]+)('|)(?:-([0-9]+)|)|)(?:\s+(\w+)|)$/) {
      push @{$Data->{eras}->{$key}->{_usages} ||= []},
          [[0+$1, $2?0+$2:undef, $3?1:0, $4?0+$4:undef], $5];
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

    } elsif (defined $key and /^<-(\S+)\s+(\S.+\S)\s*$/) {
      push @{$Data->{_TRANSITIONS} ||= []}, [$1 => $key, $2];
    } elsif (defined $key and /^->(\S+)\s+(\S.+\S)\s*$/) {
      push @{$Data->{_TRANSITIONS} ||= []}, [$key => $1, $2];
    } elsif (defined $key and /^><\s+(\S.+\S)\s*$/) {
      push @{$Data->{_TRANSITIONS} ||= []}, [$key => undef, $1];
      
    } elsif (/\S/) {
      die "Bad line |$_|";
    }
  }
}

{
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

{

  sub serialize_segmented_text ($) {
    my $st = shift;
    die $st, Carp::longmess () if not ref $st or not ref $st eq 'ARRAY';
    return join '', map {
      if (ref $_) {
        join '', map {
          if (/^:/) {
            return undef; # not serializable
          } else {
            $_;
          }
        } @$_;
      } elsif (/^\./) {
        use utf8;
        {
          '._' => ' ',
          '.・' => '',
          '..' => '',
          ".'" => "'",
          '.-' => '-',
        }->{$_} // die "Bad segment separator |$_|";
      } else {
        $_;
      }
    } @$st;
  } # serialize_segmented_text

  sub serialize_segmented_text_for_key ($) {
    my $st = shift;
    return join '', map {
      if (ref $_) {
        '['.(join '', map {
          '['.$_.']';
        } @$_).']';
      } else {
        '[['.$_.']]';
      }
    } @$st;
  } # serialize_segmented_text_for_key
}

my $LeaderKeys = [];
{
  my $Leaders = {};

  my $rpath = $root_path->child ("local/cluster-root.json");
  my $root = json_bytes2perl $rpath->slurp;
  my $x = [];
  $x->[0] = 'all';
  for (values %{$root->{leader_types}}) {
    $x->[$_->{index}] = $_->{key};
    push @$LeaderKeys, $_->{key};
  }
  
  my $path = $root_path->child ("local/char-leaders.jsonl");
  my $file = $path->openr;
  local $/ = "\x0A";
  while (<$file>) {
    my $json = json_bytes2perl $_;
    my $r = {};
    for (0..$#$x) {
      $r->{$x->[$_]} = $json->[1]->[$_]; # or undef
    }
    $Leaders->{$json->[0]} = $r;
  }

  sub segmented_text_to_han_variants ($) {
    my $ss = shift;

    my @r;
    for (@$ss) {
      for (ref $_ ? @$_ : split //, $_) {
        my $v = to_han_variants $_;
        return undef unless defined $v;
        warn "<$_> => @$v";
        push @r, $v;
      }
    }

    return \@r;
  } # segmented_text_to_han_variants

  sub is_same_han ($$) {
    my ($v, $w) = @_;
    return 0 unless @$v == @$w;
    my $r = 2;
    for (0..$#$v) {
      if ($v->[$_] eq $w->[$_]) {
        #
      } else {
        my $vv = $Leaders->{$v->[$_]}->{all} // $v->[$_];
        my $ww = $Leaders->{$w->[$_]}->{all} // $w->[$_];
        if ($vv eq $ww) {
          $r = 1;
        } else {
          return 0;
        }
      }
    }
    return $r;
    ## 0 not equal
    ## 1 equivalent but not same
    ## 2 same
  } # is_same_han

  sub fill_han_variants ($) {
    my $x = shift;
    my $w = $x->{jp} //
            $x->{tw} //
            $x->{cn} //
            $x->{kr} //
            $x->{others}->[0];

    my $has_value = {};
    LANG: for my $lang (@$LeaderKeys) {
      my $v = [map {
        if (ref $_) {
          [map {
            my $c = $Leaders->{$_}->{$lang};
            next LANG if not defined $c;
            $c;
          } @$_];
        } else {
          my $c = $Leaders->{$_}->{$lang};
          next LANG if not defined $c;
          if (1 == length $c) {
            $c;
          } else {
            [$c];
          }
        }
      } @$w];

      if (defined $v) {
        if (not defined $x->{$lang}) {
          $x->{$lang} = $v;
        } else {
          my $vs = serialize_segmented_text_for_key $v;
          my $xs = serialize_segmented_text_for_key $x->{$lang};
          unless ($vs eq $xs) {
            push @{$x->{others} ||= []}, $v;
            push @{$x->{_ERRORS} ||= []}, "$lang=$xs ($vs expected)";
          }
        }
      }

      $has_value->{serialize_segmented_text_for_key $x->{$lang}} = 1
          if defined $x->{$lang};
    }
    $x->{others} = [grep {
      my $v = serialize_segmented_text_for_key $_;
      if ($has_value->{$v}) {
        0;
      } else {
        $has_value->{$v} = 1;
        1;
      }
    } @{$x->{others} or []}];
    delete $x->{others} unless @{$x->{others}};
  } # fill_han_variants
}

{
  my $ToLatin = {qw(
    あ a い i う u え e お o
    か ka き ki く ku け ke こ ko
    さ sa し shi す su せ se そ so
    た ta ち chi つ tsu て te と to
    な na に ni ぬ nu ね ne の no
    は ha ひ hi ふ fu へ he ほ ho
    ま ma み mi む mu め me も mo
    や ya ゆ yu よ yo
    ら ra り ri る ru れ re ろ ro
    わ wa ん n
    が ga ぎ gi ぐ gu げ ge ご go
    ざ za じ ji ず zu ぜ ze ぞ zo
    だ da で de ど do
    ば ba び bi ぶ bu べ be ぼ bo
    ぱ pa ぴ pi ぷ pu ぺ pe ぽ po
    きゃ kya きゅ kyu きょ kyo
    しゃ sha しゅ shu しょ sho
    ちゃ cha ちゅ chu ちょ cho
    にゃ nya にゅ nyu にょ nyo
    ひゃ hya ひゅ hyu ひょ hyo
    みゃ mya みゅ myu みょ myo
    りゃ rya りゅ ryu りょ ryo
    ぎゃ gya ぎゅ gyu ぎょ gyo
    じゃ ja じゅ ju じょ jo
    びゃ bya びゅ byu びょ byo
    ぴゃ pya ぴゅ pyu ぴょ pyo

    ちぇ che
  )};
  sub romaji ($) {
    my $s = shift;
    $s =~ s/([きしちにひみりぎじびぴ][ゃゅょぇ])/$ToLatin->{$1}/g;
    $s =~ s/([あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわんがぎぐげござじずぜぞだでどばびぶべぼぱぴぷぺぽ])/$ToLatin->{$1}/g;
    #$s =~ s/^(\S+ \S+) (\S+ \S+)$/$1 - $2/g;
    $s =~ s/ (ten nou|ki [gn]en)$/ - $1/g;
    $s =~ s/ (kou gou) (seっ shou)$/ - $1 - $2/g;
    $s =~ s/^(\S+) (\S+) (reki)$/$1 $2 - $3/g;
    $s =~ s/n ([aiueoyn])/n ' $1/g;
    $s =~ s/っ ([ksthyrwgzdbp])/$1 $1/g;
    $s =~ s{([aiueo])ー}{
      {a => "\x{0101}", i => "\x{012B}", u => "\x{016B}",
       e => "\x{0113}", o => "\x{014D}"}->{$1};
    }ge;
    #$s =~ s/ //g;
    die $s if $s =~ /\p{Hiragana}/;
    #return ucfirst $s;
    return $s;
  }

  sub romaji2 ($) {
    #my $s = lcfirst romaji $_[0];
    my $s = romaji $_[0];
    $s =~ s/ou/\x{014D}/g;
    $s =~ s/uu/\x{016B}/g;
    #$s =~ s/ii/\x{012B}/g;
    #return ucfirst $s;
    return $s;
  }

  sub romaji_variants (@) {
    my @s = @_;
    my $found = {};
    $found->{$_} = 1 for @s;
    my @r = @s;
    for (@s) {
      {
        my $s = $_;
        $s =~ s/n( ?[mpb])/m$1/g;
        push @r, $s;

        $s =~ s/m m([aiueo\x{0101}\x{016B}\x{016B}\x{0113}\x{014D}y])/m ' m$1/g;
        push @r, $s;
      }
      {
        my $s = $_;
        $s =~ s/n ' n/n n/g;
        push @r, $s;
      }
    }
    {
      my @t = @r;
      for (@t) {
        my $s = $_;
        $s =~ s/m( ?)(?:' |)([mpb])/n$1$2/g;
        $s =~ s/sh([i\x{012B}])/s$1/g;
        $s =~ s/ch([i\x{012B}])/t$1/g;
        $s =~ s/j([i\x{012B}])/z$1/g;
        $s =~ s/ts([u\x{016B}])/t$1/g;
        $s =~ s/sh([aueo\x{0101}\x{016B}\x{0113}\x{014D}])/sy$1/g;
        $s =~ s/ch([aueo\x{0101}\x{016B}\x{0113}\x{014D}])/ty$1/g;
        $s =~ s/j([aueo\x{0101}\x{016B}\x{0113}\x{014D}])/zy$1/g;
        push @r, $s;
      }
    }
    return [grep { not $found->{$_}++ } sort { $a cmp $b } @r];
  } # romaji_variants

  sub to_hiragana ($) {
    use utf8;
    my $s = shift;
    $s =~ tr/アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォッャュョヮ/あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎ/;
    return $s;
  } # to_hiragana

  sub to_katakana ($) {
    use utf8;
    my $s = shift;
    $s =~ tr/あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわゐゑをんがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽぁぃぅぇぉっゃゅょゎ/アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヰヱヲンガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポァィゥェォッャュョヮ/;
    return $s;
  } # to_katakana

  sub fill_rep_yomi ($) {
    my $rep = shift;

    if (defined $rep->{kana_modern}) {
      my $ih = sub {
        if ($rep->{insert_22hyphen}) {
          my $s = shift;
          $s =~ s/^(\S+ \S+) (\S+ \S+)$/$1 - $2/g;
          return $s;
        } else {
          return $_[0];
        }
      };
      
      $rep->{kana} //= $rep->{kana_modern};
      $rep->{latin_normal} //= $ih->(romaji $rep->{kana_modern});
      $rep->{latin_macron} //= $ih->(romaji2 $rep->{kana_modern});
      $rep->{latin} //= $rep->{latin_macron};

      my $variants = romaji_variants $rep->{latin_normal}, $rep->{latin_macron};
      push @{$rep->{latin_others}}, @$variants;
    }
  } # fill_rep_yomi

  sub fill_yomi_from_rep ($$) {
    my ($rep => $v) = @_;

    $v->{hiragana} = [split / /,
                      $rep->{kana} //
                      $rep->{kana_modern} //
                      $rep->{kana_classic} //
                      $rep->{kana_others}->[0] // ''];
    delete $v->{hiragana} unless @{$v->{hiragana}};
    $v->{hiragana_modern} = [split / /, $rep->{kana_modern}]
        if defined $rep->{kana_modern};
    $v->{hiragana_classic} = [split / /, $rep->{kana_classic}]
        if defined $rep->{kana_classic};

    for (@{$rep->{kana_others} or []}) {
      push @{$v->{hiragana_others} ||= []}, [split / /, $_];
    }
    for (@{$rep->{kana_wrongs} or []}) {
      push @{$v->{hiragana_wrongs} ||= []}, [split / /, $_];
    }
    for (@{$rep->{hans} or []}) {
      push @{$v->{han_others} ||= []}, [split / /, to_hiragana $_];
    }
    for my $key (qw(hiragana_others hiragana_wrongs han_others)) {
      next unless defined $v->{$key};
      my $found = {};
      $v->{$key} = [map { $_->[0] } sort { $a->[1] cmp $b->[1] } grep {
        not $found->{$_->[1]}++;
      } map {
        [$_, serialize_segmented_text_for_key $_];
      } @{$v->{$key}}];
    }

    my $found = {};
    for (qw(latin latin_normal latin_macron)) {
      $v->{$_} = [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ } split /( (?:['-] |))/, $rep->{$_}]
          if defined $rep->{$_};
      $found->{serialize_segmented_text_for_key $v->{$_}} = 1
          if defined $v->{$_};
    }
    for (@{$rep->{latin_others} or []}) {
      push @{$v->{latin_others} ||= []},
          [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ } split /( (?:['-] |))/, $_];
    }
    if (defined $v->{latin_others}) {
      $v->{latin_others} = [map {
        $_->[0];
      } grep { not $found->{$_->[1]}++ } map {
        [$_, serialize_segmented_text_for_key $_];
      } @{$v->{latin_others}}];
    } # fill_yomi_from_rep
  }

  sub fill_kana ($) {
    my $v = shift;
    use utf8;

    my $s = $v->{kana} // $v->{hiragana};
    $v->{hiragana_modern} //= [map {
      to_hiragana $_;
    } @$s];
    $v->{hiragana} //= $v->{hiragana_modern};
    $v->{katakana_modern} //= [map {
      to_katakana $_;
    } @$s];
    $v->{katakana} //= $v->{katakana_modern};

    my $rep = {};
    $rep->{kana_modern} = join ' ', map {
      {'.・' => '._'}->{$_} // $_;
    } @{$v->{hiragana_modern}};
    fill_rep_yomi $rep;

    my $found = {};
    for (qw(latin latin_normal latin_macron)) {
      $v->{$_} = [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ } split /( (?:['-] |))/, $rep->{$_}]
          if defined $rep->{$_};
      $found->{serialize_segmented_text_for_key $v->{$_}} = 1
          if defined $v->{$_};
    }
    for (@{$rep->{latin_others} or []}) {
      push @{$v->{latin_others} ||= []},
          grep { not $found->{serialize_segmented_text_for_key $_}++ }
          [map { $_ eq ' ' ? () : $_ eq " ' " ? ".'" : $_ eq ' - ' ? '.-' : $_ }
           split /( (?:['-] |))/, $_];
    }
  } # fill_kana
}

## Name shorthands
{
  sub filter_labels ($) {
    my $labels = shift;
    return [grep { @{$_->{texts}} or @{$_->{expandeds} or []} } @$labels];
  } # filter_labels
  
  sub reps_to_labels ($$$);
  sub reps_to_labels ($$$) {
    my ($reps => $labels, $has_preferred) = @_;

    my $label = {texts => []};
    my $label_added = 0;
    if (@$labels) {
      $label = $labels->[-1];
      $label_added = 1;
    }

    for my $rep (@$reps) {
      if ($rep->{next_label}) {
        push @$labels, $label unless $label_added;
        $label = {texts => []};
        $label_added = 0;
        next;
      }
      
      my $value = {};
      my $value_added = 0;

      if (defined $rep->{kind}) {
        if ($rep->{kind} eq 'expanded') {
          if (@{$label->{texts}} and
              defined $label->{texts}->[-1]->{abbr}) {
            $value = $label->{texts}->[-1];
            $value_added = 1;
          }
          $rep->{kind} = '(expanded)';
          $value->{expandeds} ||= [];
          reps_to_labels [$rep] => $value->{expandeds}, {jp=>1,cn=>1,tw=>1};
        } else {
          my $v = {};
          my $v_added = 0;

          if ($rep->{type} eq 'han') {
            for (@{$label->{texts}}) {
              if ($_->{type} eq 'han') {
                $value = $_;
                $value_added = 1;
              } elsif ($_->{type} eq 'korean') {
                $value = $_;
                $value_added = 1;
                for my $v (@{$_->{form_sets}}) {
                  $v->{form_set_type} = 'korean';
                }
              }
            }
            $value->{type} = 'han';
            $v->{form_set_type} = 'hanzi';
            
            my $w = [split //, $rep->{value}];
            for my $x (@{$value->{form_sets}}) {
              next unless $x->{form_set_type} eq 'hanzi';
              my $eq = is_same_han $w,
                      $x->{jp} //
                      $x->{tw} //
                      $x->{cn} //
                      $x->{kr} //
                      $x->{others}->[0];
              if ($eq == 2 and
                  (not defined $rep->{lang} or defined $x->{$rep->{lang}})) {
                $v_added = 1;
              } elsif ($eq) {
                $v = $x;
                $v_added = 1;
              }
            }

            my $lang = {
              ja => 'jp',
              ko => 'kr',
            }->{$rep->{lang} // ''} // $rep->{lang};
            if (defined $lang and
                not defined $v->{$lang}) {
              $v->{$lang} = $w;
              if ($lang eq 'jp' or $lang eq 'tw' or $lang eq 'cn') {
                if (not $has_preferred->{$lang}) {
                  $v->{is_preferred}->{$lang} = 1;
                  $has_preferred->{$lang} = 1;
                }
              }
            } else {
              push @{$v->{others} ||= []}, $w;
            }

            $value->{abbr} = $rep->{abbr} if defined $rep->{abbr};
            if (defined $rep->{to_abbr} and $rep->{to_abbr} eq 'single') {
              $v->{abbr_indexes} = [map { undef } @$w];
              $v->{abbr_indexes}->[$rep->{abbr_index} // 0] = 0;
            }
          } elsif ($rep->{type} eq 'yomi') {
            if (not defined $rep->{source}) {
              my $vtype = $rep->{is_ja} ? 'ja' : 'han';
              my $han_value;
            for (@{$label->{texts}}) {
              if ($_->{type} eq $vtype) {
                $value = $_;
                $value_added = 1;
              } elsif ($_->{type} eq 'han') {
                $han_value = $_;
              } elsif ($_->{type} eq 'korean' and $vtype ne 'ja') {
                $value = $_;
                $value_added = 1;
                for my $v (@{$_->{form_sets}}) {
                  $v->{form_set_type} = 'korean';
                }
              }
            }

              $value->{type} = $vtype;
              fill_rep_yomi $rep;
              
            if ($vtype eq 'ja' and defined $han_value and
                not @{$value->{form_sets} or []}) {
              for my $fs (@{$han_value->{form_sets}}) {
                if ($fs->{form_set_type} eq 'hanzi') {
                  my $new_fs = {form_set_type => 'hanzi',
                                others => [$fs->{jp} //
                                           $fs->{tw} //
                                           $fs->{cn} //
                                           $fs->{kr} //
                                           $fs->{others}->[0]]};
                  if (not $rep->{kana} =~ / /) {
                    $new_fs->{others}->[0] = [[map {
                      if (ref $_) {
                        @$_;
                      } else {
                        split //, $_;
                      }
                    } @{$new_fs->{others}->[0]}]];
                  }
                  push @{$value->{form_sets} ||= []}, $new_fs;
                }
              }
            }

              $v->{form_set_type} = 'yomi';
              fill_yomi_from_rep $rep => $v;
            } elsif ($rep->{source} eq '6034') {
              $value_added = 1;
              $v_added = 1;
              my $found = {};
              for (map { [split / /, $_] } grep { not $found->{$_}++ } sort { $a cmp $b } @{$rep->{value}}) {
                my $value = {};
                $value->{type} = 'alphabetical';
                my $v = {};
                $v->{form_set_type} = 'alphabetical';
                $v->{ja_latin_old} = $_;
                push @{$value->{form_sets} ||= []}, $v;
                push @{$label->{texts} ||= []}, $value;
              }
            } elsif ($rep->{source} eq '6036') {
              $value->{type} = 'alphabetical';
              $v->{form_set_type} = 'alphabetical';
              my $found = {};
              $v->{ja_latin_old_wrongs} = [map { [split / /, $_] } sort { $a cmp $b } grep { not $found->{$_}++ } @{$rep->{value}}];
            } else {
              die "Bad source |$rep->{source}|";
            }
          } elsif ($rep->{type} eq 'alphabetical') {
            if (@{$label->{texts}} and
                $label->{texts}->[-1]->{type} eq 'alphabetical' and
                not $rep->{lang} eq 'ja_latin_old') {
              $value = $label->{texts}->[-1];
              $value_added = 1;
            }
            $value->{type} = 'alphabetical';
            $v->{form_set_type} = 'alphabetical';
            my $w;
            my $abbr_indexes;
            if (defined $rep->{abbr}) {
                if ($rep->{abbr} eq 'acronym') {
                  use utf8;
                  if ($rep->{value} =~ /[.・]/) {
                    $w = [map { ($_ eq '.' or $_ eq "・") ? '..' : $_ } split /([.・])/, $rep->{value}];
                  } else {
                    $w = [split //, $rep->{value}];
                  }
                  if ($rep->{abbr} eq 'acronym' and
                      (@$w == 1 or
                       (@$w == 2 and $w->[1] eq '..'))) {
                    $value->{abbr} = 'one';
                  } else {
                    $value->{abbr} = $rep->{abbr};
                  }
                } else {
                  die "Unknown abbr type |$rep->{abbr}|";
                }
              } else {
                $w = [grep { length } map { /\s+/ ? '._' : $_ } split /(\s+|\[[^\[\]]+\])/, $rep->{value}];
                my @abbr;
                my $j = 0;
                for my $i (0..$#$w) {
                  if ($w->[$i] =~ s/\A\[// and $w->[$i] =~ s/\]\z//) {
                    push @abbr, $j++;
                  } elsif ($w->[$i] =~ /^\./) {
                    #
                  } else {
                    push @abbr, undef;
                  }
                }
                $abbr_indexes = \@abbr unless $j == 0;
              }

            my $w_length = @{[grep { not /^\./ } @$w]};
            if (@{$value->{form_sets} || []} and
                ((not defined $abbr_indexes and
                  not defined $value->{form_sets}->[-1]->{abbr_indexes}) or
                  (defined $abbr_indexes and
                   defined $value->{form_sets}->[-1]->{abbr_indexes} and
                   @$abbr_indexes == @{$value->{form_sets}->[-1]->{abbr_indexes}} and
                   join ($;, map { $_ // '' } @$abbr_indexes) eq
                   join ($;, map { $_ // '' } @{$value->{form_sets}->[-1]->{abbr_indexes}}))) and
                   ($value->{form_sets}->[-1]->{segment_length} == $w_length)) {
            $v = $value->{form_sets}->[-1];
            $v_added = 1;
          }
            if (not defined $v->{$rep->{lang}}) {
              $v->{$rep->{lang}} = $w;
            } else {
              push @{$v->{others} ||= []}, $w;
            }
            $v->{segment_length} = $w_length;
            $v->{abbr_indexes} = $abbr_indexes if defined $abbr_indexes;
          } elsif ($rep->{type} eq 'jpan' or
                   $rep->{type} eq 'zh') {
            my @value;
            while (length $rep->{value}) {
              use utf8;
              if ($rep->{value} =~ s/\A([\p{Hiragana}|\p{Katakana}ー、][\p{Hiragana}|\p{Katakana}ー、・]*)//) {
                $value->{type} = 'kana';
                $v->{form_set_type} = 'kana';
                my $w = [map {
                  /^\s+$/ ? '._' : $_ eq "・" ? '.・' : $_ eq "、" ? '.・' : $_;
                } grep { length } split /([・、]|\s+)/, $1];
                $v->{kana} = $w;
                if ($rep->{value} =~ s/\A\[J:\]//) {
                  $value->{type} = 'ja';
                }
              } elsif ($rep->{value} =~ s/\A([\p{Han}|]+)//) {
                $value->{type} = 'han';
                $v->{form_set_type} = 'hanzi';
                my $w = [split //, $1];
                push @{$v->{others} ||= []}, $w;
                while ($rep->{value} =~ s/\A\[(!|)(J:|)(,*[\p{Hiragana}\p{Han}]+(?:[\s,]+[\p{Hiragana}\p{Han}]+)*)\]//) {
                  my $is_wrong = $1;
                  my $is_ja = $2;
                  if ($is_ja) {
                    $value->{type} = 'ja';
                    $v->{others} = [map {
                      my $r = [[]];
                      for (@$_) {
                        if ($_ eq '|') {
                          push @$r, [];
                        } else {
                          push @{$r->[-1]}, $_;
                        }
                      }
                      $r;
                    } @{$v->{others}}] if $v->{form_set_type} eq 'hanzi';
                  }
                  push @{$value->{form_sets}}, $v;
                  $v = {};

                  my $kanas = [split /,/, $3];
                  my $rep = {};
                  die if $is_wrong and
                         (length $kanas->[0] or length $kanas->[1]);
                  $rep->{kana_modern} = $kanas->[0]
                      if @$kanas >= 1 and length $kanas->[0];
                  $rep->{kana_classic} = $kanas->[1]
                      if @$kanas >= 2 and length $kanas->[1];
                  shift @$kanas;
                  shift @$kanas;
                  if ($is_wrong) {
                    $rep->{kana_wrongs} = $kanas;
                  } else {
                    for (@$kanas) {
                      if (/\p{Han}/) {
                        push @{$rep->{hans} ||= []}, $_;
                      } else {
                        push @{$rep->{kana_others} ||= []}, $_;
                      }
                    }
                  }
                  fill_rep_yomi $rep;

                  $v->{form_set_type} = 'yomi';
                  fill_yomi_from_rep $rep => $v;
                }
                if ($rep->{value} =~ s/\A\[J:\]//) {
                  $value->{type} = 'ja';
                  $v->{others} = [map {
                    my $r = [[]];
                    for (@$_) {
                      if ($_ eq '|') {
                        push @$r, [];
                      } else {
                        push @{$r->[-1]}, $_;
                      }
                    }
                    $r;
                  } @{$v->{others}}];
                }
              } elsif ($rep->{value} =~ s/\A(\p{Latn}+)//) {
                $value->{type} = 'alphabetical';
                $v->{form_set_type} = 'alphabetical';
                my $w = [$1];
                push @{$v->{others} ||= []}, $w;
              } elsif ($rep->{value} =~ s/\A([()\p{Geometric Shapes}・]+)//) {
                $value->{type} = 'symbols';
                $v->{form_set_type} = 'symbols';
                my $w = [{'・' => '.・'}->{$1} // $1];
                push @{$v->{others} ||= []}, $w;
              } else {
                die "Bad compound value |$rep->{value}|";
              }
              push @{$value->{form_sets}}, $v;
              $v = {};
              push @value, $value;
              $value = {form_sets => []};
            }
            if (@value == 1) {
              $value = $value[0];
            } else {
              $value = {type => 'compound', items => \@value};
              my $lang = {
                jpan => 'jp',
                cn => 'cn',
                tw => 'tw',
              }->{$rep->{lang} // $rep->{type}};
              if (not $has_preferred->{$lang}) {
                $value->{is_preferred}->{$lang} = 1;
                $has_preferred->{$lang} = 1;
              }
            }
            $v_added = 1;
          } elsif ($rep->{type} eq 'korean') { # Korean alphabet
            for (@{$label->{texts}}) {
              if ($_->{type} eq 'han') {
                $value = $_;
                $value_added = 1;
              }
            }
            $value->{type} = 'korean' unless $value_added;

            $v->{form_set_type} = 'korean';
            my $w = [split //, $rep->{value}];
            if (not defined $v->{$rep->{lang}}) {
              $v->{$rep->{lang}} = $w;
            } else {
              push @{$v->{others} ||= []}, $w;
            }
          } elsif ($rep->{type} eq 'manchu') {
            $value->{type} = 'manchu';
            $v->{form_set_type} = 'manchu';
            for my $key (qw(manchu),
                         qw(moellendorff abkai xinmanhan)) { # latin
              $v->{$key} = [map { $_ =~ /\s/ ? '._' : $_ } split /(\s+)/, $rep->{$key}]
                  if defined $rep->{$key};
            }
          } elsif ($rep->{type} eq 'mongolian') {
            $value->{type} = 'mongolian';
            $v->{form_set_type} = 'mongolian';
            $rep->{cyrillic} = lc $rep->{cyrillic} if defined $rep->{cyrillic};
            for my $key (qw(mongolian),
                         qw(cyrillic),
                         qw(vpmc)) { # latin
              $v->{$key} = [map { $_ =~ /\s/ ? '._' : $_ } split /(\s+)/, $rep->{$key}]
                  if defined $rep->{$key};
            }
          } else {
            die "Unknown type |$rep->{type}|";
          }

          if ($rep->{kind} eq 'name') {
            $label->{is_name} = \1;
            if ($rep->{preferred} and defined $rep->{lang}) {
              my $lang = {
                ja => 'jp',
                ko => 'kr',
              }->{$rep->{lang}} // $rep->{lang};
              if ($value->{type} eq 'compound') {
                $value->{is_preferred}->{$lang} = \1;
              } else {
                $v->{is_preferred}->{$lang} = \1;
              }
            }
          } elsif ($rep->{kind} eq '(expanded)' or
                   $rep->{kind} eq 'yomi') {
            #
          } else {
            die "Unknown type |$rep->{kind}|";
          }
          push @{$value->{form_sets}}, $v if not $v_added and keys %$v;
        }
      } else { # XXX old style
        $value = $rep;
      }
      
      $value->{expandeds} = filter_labels $value->{expandeds}
          if defined $value->{expandeds};
      push @{$label->{texts}}, $value unless $value_added;
    } # $rep

    push @$labels, $label unless $label_added;
  } # reps_to_labels
  
  for my $era (values %{$Data->{eras}}) {
    my $has_preferred = {};
    for my $label_set (@{$era->{_LABELS}}) {
      for my $label (@{$label_set->{labels}}) {
        for my $rep (@{$label->{reps}}) {
          if ($rep->{preferred} and defined $rep->{lang}) {
            $has_preferred->{$rep->{lang}} = 1;
          }
        }
      }
    }

    $era->{label_sets} = [];
    for my $label_set (@{$era->{_LABELS}}) {
      my $new_label_set = {labels => []};
      reps_to_labels [map { (@{$_->{reps}}, {next_label => 1}) } @{$label_set->{labels}}] => $new_label_set->{labels}, $has_preferred;
      $new_label_set->{labels} = filter_labels $new_label_set->{labels};
      push @{$era->{label_sets}}, $new_label_set if @{$new_label_set->{labels}};
    }
  } # $era
  
  for my $era (values %{$Data->{eras}}) {
    for my $label_set (@{$era->{label_sets}}) {
      for my $label (@{$label_set->{labels}}) {
        if ($label->{is_name}) {
          for my $text (@{$label->{texts}}) {
            if ($text->{type} eq 'han' or
                $text->{type} eq 'ja' or
                $text->{type} eq 'kana') {
              for my $value (@{$text->{form_sets}}) {
                if ($value->{form_set_type} eq 'hanzi') {
                  for my $lang (qw(jp tw cn)) {
                    if (defined $value->{$lang} and
                        not defined $text->{abbr} and
                        (not defined $era->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} or
                         ($value->{is_preferred} or {})->{$lang})) {
                      $era->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} = serialize_segmented_text $value->{$lang};
                      $era->{name} //= $era->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang};
                    }
                  if (defined $value->{$lang} and
                      defined $text->{abbr} and $text->{abbr} eq 'single') {
                    $era->{abbr} //= serialize_segmented_text $value->{$lang};
                  }
                    $era->{names}->{serialize_segmented_text $value->{$lang}} = 1
                        if defined $value->{$lang};
                  }
                  for ($value->{kr} // undef, @{$value->{others} or []}) {
                    next unless defined;
                    my $s = serialize_segmented_text $_;
                    $era->{names}->{$s} = 1;
                    $era->{name} //= $s;
                  }
                } elsif ($text->{type} eq 'kana') {
                  if (defined $value->{kana}) {
                    my $name = serialize_segmented_text $value->{kana};
                    if (not defined $era->{name_ja} or
                        ($value->{is_preferred} or {})->{jp}) {
                      $era->{name_ja} = $name;
                      $era->{name} //= $era->{name_ja};
                    }
                    $era->{names}->{$name} = 1;
                  }

                  if (defined $value->{hiragana_modern}) {
                    my $kana = serialize_segmented_text $value->{hiragana_modern};
                    $era->{name_kana} //= $kana;
                    $era->{name_kanas}->{$kana} = 1;
                  }
                } elsif ($value->{form_set_type} eq 'korean') {
                  for my $lang (qw(ko kr kp)) {
                    if (defined $value->{$lang} and
                        (not defined $era->{name_ko} or
                         ($value->{is_preferred} or {})->{$lang})) {
                      $era->{name_ko} = serialize_segmented_text $value->{$lang};
                      $era->{name} //= $era->{name_ko};
                    }
                  }
                }
              }
            } elsif ($text->{type} eq 'alphabetical') {
              for my $value (@{$text->{form_sets}}) {
                  if (defined $value->{en} and
                      (not defined $era->{name_en} or
                       ($value->{is_preferred} or {})->{en})) {
                    $era->{name_en} = serialize_segmented_text $value->{en};
                    $era->{name} //= $era->{name_en};
                  }
                  if (defined $value->{ja_latin} and
                      (not defined $era->{abbr_latn} or
                       ($value->{is_preferred} or {})->{ja_latin}) and
                       defined $text->{abbr} and
                       $text->{abbr} eq 'one') {
                    $era->{abbr_latn} = serialize_segmented_text $value->{ja_latin};
                  }
                }
              } elsif ($text->{type} eq 'korean') {
                for my $value (@{$text->{form_sets}}) {
                  for my $lang (qw(ko kr kp)) {
                    if (defined $value->{$lang} and
                        (not defined $era->{name_ko} or
                         ($value->{is_preferred} or {})->{$lang})) {
                      $era->{name_ko} = serialize_segmented_text $value->{$lang};
                      $era->{name} //= $era->{name_ko};
                    }
                  }
                }
              } elsif ($text->{type} eq 'compound') {
                my $name = join '', map {
                  my $x = $_->{form_sets}->[0];
                  my $v = serialize_segmented_text (($x->{form_set_type} eq 'kana' ? $x->{kana} : $x->{others}->[0]) // die);
                  $v;
                } @{$text->{items}};
                $era->{names}->{$name} = 1;
                if ((not defined $era->{name_ja} or
                     ($text->{is_preferred} or {})->{jp})) {
                  $era->{name_ja} = $name;
                  my $no_kana = 0;
                  my $kana = join '', map {
                    if ($_->{type} eq 'kana') {
                      to_hiragana serialize_segmented_text ($_->{form_sets}->[0]->{kana} // die);
                    } elsif ($_->{type} eq 'han') {
                      my $yomi = [grep {
                        $_->{form_set_type} eq 'yomi';
                      } @{$_->{form_sets}}]->[0];
                      if (defined $yomi) {
                        serialize_segmented_text $yomi->{hiragana_modern};
                      } else {
                        $no_kana = 1;
                      }
                    } elsif ($_->{type} eq 'ja') {
                      my $yomi = [grep {
                        $_->{form_set_type} eq 'kana';
                      } @{$_->{form_sets}}]->[0];
                      if (defined $yomi) {
                        serialize_segmented_text $yomi->{hiragana_modern};
                      } else {
                        $no_kana = 1;
                      }
                    } elsif ($_->{type} eq 'symbols') {
                      #
                    } else {
                      $no_kana = 1;
                    }
                  } @{$text->{items}};
                  unless ($no_kana) {
                    $era->{name_kana} = $kana;
                    $era->{name_kanas}->{$kana} = 1;
                  }
                  $era->{name} //= $era->{name_ja};
                }
                if ((#not defined $era->{name_cn} or
                     ($text->{is_preferred} or {})->{cn})) {
                  $era->{name_cn} = $name;
                }
                if ((#not defined $era->{name_tw} or
                     ($text->{is_preferred} or {})->{tw})) {
                  $era->{name_tw} = $name;
                }
              }
            }
        } # is_name
      } # $label
    } # $label_set
    for my $label_set (@{$era->{label_sets}}) {
      for my $label (@{$label_set->{labels}}) {
        for my $text (@{$label->{texts}}) {
          if ($text->{type} eq 'han' or
              $text->{type} eq 'ja') {
            for my $value (@{$text->{form_sets}}) {
              if ($value->{form_set_type} eq 'hanzi') {
                fill_han_variants $value;
              for my $lang (qw(tw jp cn)) {
                if ($label->{is_name} and
                    defined $value->{$lang} and
                    not defined $text->{abbr} and
                    not defined $era->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang}) {
                  $era->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang} = serialize_segmented_text $value->{$lang};
                  $era->{name} //= $era->{$lang eq 'jp' ? 'name_ja' : 'name_'.$lang};
                }
              }
              for my $lang (@$LeaderKeys) {
                if ($label->{is_name} and defined $value->{$lang}) {
                  my $v = serialize_segmented_text $value->{$lang};
                  $era->{names}->{$v} = 1 if defined $v;
                  }
                }
              } elsif ($value->{form_set_type} eq 'yomi') {
                $era->{name_kana} //= serialize_segmented_text $value->{hiragana_modern};
                for (grep { defined }
                     $value->{hiragana} // undef,
                     $value->{hiragana_modern} // undef,
                     $value->{hiragana_classic} // undef,
                     @{$value->{hiragana_others} or []}) {
                  my $v = serialize_segmented_text $_;
                  $era->{name_kanas}->{$v} = 1;
                }

                if (defined $value->{latin} and
                    not defined $era->{name_latn}) {
                  $era->{name_latn} = serialize_segmented_text $value->{latin};
                  $era->{name_latn} =~ s/^([a-zāīūēō])/uc $1/e;
                }
              } elsif ($value->{form_set_type} eq 'kana') {
                fill_kana $value;
              }
            }
          } elsif ($text->{type} eq 'kana') {
            for my $value (@{$text->{form_sets}}) {
              fill_kana $value;
              if (defined $value->{latin} and
                  not defined $era->{name_latn}) {
                $era->{name_latn} = serialize_segmented_text $value->{latin};
                $era->{name_latn} =~ s/^([a-zāīūēō])/uc $1/e;
              }
            }
          } elsif ($text->{type} eq 'compound') {
            for my $text (@{$text->{items}}) {
              if ($text->{type} eq 'han' or
                  $text->{type} eq 'ja') {
                for my $value (@{$text->{form_sets}}) {
                  if ($value->{form_set_type} eq 'hanzi') {
                    fill_han_variants $value;
                  } elsif ($value->{form_set_type} eq 'kana') {
                    fill_kana $value;
                  }
                }
              } elsif ($text->{type} eq 'kana') {
                for my $value (@{$text->{form_sets}}) {
                  fill_kana $value;
                }
              }
            }
          }
          for my $label (@{$text->{expandeds} or []}) {
            for my $text (@{$label->{texts}}) {
              if ($text->{type} eq 'han') {
                for my $value (@{$text->{form_sets}}) {
                  if ($value->{form_set_type} eq 'hanzi') {
                    fill_han_variants $value;
                  }
                }
              }
            }
          }
        } # $text
      }
    }
    
    delete $era->{_LABELS};
  } # $era
}

{
  my $path = $root_path->child ('src/era-codes-14.txt');
  my $i = 1;
  for (grep { length } split /\x0D?\x0A/, $path->slurp_utf8) {
    ($Data->{eras}->{$_} or die "Era |$_| not found")->{code14} = $i;
    $i++;
  }
}
{
  my $path = $root_path->child ('src/era-codes-15.txt');
  my $i = 1;
  for (grep { length } split /\x0D?\x0A/, $path->slurp_utf8) {
    ($Data->{eras}->{$_} or die "Era |$_| not found")->{code15} = $i;
    $i++;
  }
}
{
  my $path = $root_path->child ('src/era-codes-24.txt');
  my $i = 1;
  for (grep { length } split /\x0D?\x0A/, $path->slurp_utf8) {
    ($Data->{eras}->{$_} or die "Era |$_| not found")->{code24} = $i;
    $i++;
  }
}
{
  my $path = $root_path->child ('local/cldr-core-json/ja.json');
  my $json = json_bytes2perl $path->slurp;
  for my $i (0..$#{$json->{"dates_calendar_japanese_era"}}) {
    my $v = $json->{"dates_calendar_japanese_era"}->[$i];
    next unless defined $v;
    ($Data->{eras}->{$v} or die "Era |$v| not found")->{code10} = $i;
  }
}

{
  my $Scores = {};
  for my $era (values %{$Data->{eras}}) {
    use utf8;
    if ($era->{tag_ids}->{$TagByKey->{'日本の私年号'}->{id}}) {
      $era->{jp_private_era} = 1;
    }
    $Scores->{$era->{key}} = 0;
    $Scores->{$era->{key}} += 50000
        if $era->{jp_era} or $era->{jp_emperor_era} or
           $era->{jp_north_era} or $era->{jp_south_era};
    $Scores->{$era->{key}} += 40000 if $era->{jp_private_era};
    $Scores->{$era->{key}} += 10000
        if defined $era->{name_cn};
    $Scores->{$era->{key}} += 10000 - $era->{offset} if defined $era->{offset};
  }
  my $Names = {};
  for my $era (sort {
    $Scores->{$b->{key}} <=> $Scores->{$a->{key}} ||
    $a->{key} cmp $b->{key};
  } values %{$Data->{eras}}) {
    my @all_name = keys %{$era->{names} or {}};
    for (sort { $a cmp $b } @all_name) {
      $Names->{$_}->{$era->{key}} = 1;
      $Data->{name_to_key}->{jp}->{$_} //= $era->{key};
    }
  }

  for my $name (keys %$Names) {
    next unless 2 <= keys %{$Names->{$name}};
    $Data->{name_conflicts}->{$name} = $Names->{$name};
  }
}

{
  my $path = $root_path->child ('local/number-values.json');
  my $json = json_bytes2perl $path->slurp;
  my $is_number = {};
  for (keys %$json) {
    if (defined $json->{$_}->{cjk_numeral}) {
      $is_number->{$_} = 1;
    }
  }
  my $path2 = $root_path->child ('data/numbers/kanshi.json');
  my $json2 = json_bytes2perl $path2->slurp;
  for (split //, $json2->{name_lists}->{kanshi}) {
    $is_number->{$_} = 1 unless $_ eq ' ';
  }
  $is_number->{$_} = 1 for qw(元 正 𠙺 端 冬 臘 腊 初 𡔈 末 前 中 後 建 閏); # 元年, 正月, 初七日, 初年, 初期, 前半, ...
  $is_number->{$_} = 1 for qw(年 𠡦 𠦚 載 𡕀 𠧋 歳 月 囝 日 𡆠 時 分 秒 世 紀 星 期 曜 旬 半 火 水 木 金 土);
  my $number_pattern = join '|', map { quotemeta $_ } keys %$is_number;
  for my $data (values %{$Data->{eras}}) {
    for (keys %{$data->{names}}) {
      while (/($number_pattern)/go) {
        $Data->{numbers_in_era_names}->{$1}->{$_} = 1;
      }
    }
  }
}

for my $data (values %{$Data->{eras}}) {
  for (keys %{$data->{names}}) {
    $Data->{name_to_keys}->{$_}->{$data->{key}} = 1;
  }
}

{
  my $path = $root_path->child ('intermediate/era-ids.json');
  my $map = json_bytes2perl $path->slurp;
  my @need_id;
  my $max_id = 0;
  for my $data (sort { $a->{key} cmp $b->{key} } values %{$Data->{eras}}) {
    if (defined $data->{id} and $map->{$data->{key}} != $data->{id}) {
      die "Era ID |$data->{id}|, key |$data->{key}| is not registered";
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
