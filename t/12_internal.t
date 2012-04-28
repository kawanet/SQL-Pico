use strict;
use Test::More tests => 22;

BEGIN { use_ok 'SQL::Pico::Table' }

my $array;

$array = SQL::Pico::Table::_arrayref();
ok(ref $array, 'null');
is(scalar @$array, 0, 'null length');

$array = SQL::Pico::Table::_arrayref(undef);
ok(ref $array, 'undef');
is(scalar @$array, 1, 'undef length');
ok(! defined $array->[0], 'undef 1st');

$array = SQL::Pico::Table::_arrayref('str');
ok(ref $array, 'str');
is(scalar @$array, 1, 'str length');
is($array->[0], 'str', 'str 1st');

$array = SQL::Pico::Table::_arrayref('foo', 'bar');
ok(ref $array, 'foo bar');
is(scalar @$array, 2, 'foo bar length');
is($array->[0], 'foo', 'foo bar 1st');
is($array->[1], 'bar', 'foo bar 2nd');

$array = SQL::Pico::Table::_arrayref([]);
ok(ref $array, 'zero');
is(scalar @$array, 0, 'zero length');

$array = SQL::Pico::Table::_arrayref(['str']);
ok(ref $array, 'str');
is(scalar @$array, 1, 'arrayref str length');
is($array->[0], 'str', 'arrayref str 1st');

$array = SQL::Pico::Table::_arrayref(['foo', 'bar']);
ok(ref $array, 'foo bar');
is(scalar @$array, 2, 'arrayref foo bar length');
is($array->[0], 'foo', 'arrayref foo bar 1st');
is($array->[1], 'bar', 'arrayref foo bar 2nd');
