use strict;
use Test::More tests => 18;

BEGIN { use_ok 'SQL::Pico::Table' }

my $pico = SQL::Pico::Table->new;
my $test;
my @test;

$pico->table('str1');
$test = $pico->table;
ok(! ref $test, 'table scalar');
is($test, 'str1', 'table str');

# scalar

$pico->readable('str2');
$test = $pico->readable;
is($test, 'str2', 'readable str');

$pico->writable('str3');
$test = $pico->writable;
is($test, 'str3', 'writable str');

$pico->condition('str4');
$test = $pico->condition;
is($test, 'str4', 'condition str');

# array

$pico->readable('foo', 'bar');
@test = $pico->readable;
is($test[0], 'foo', 'readable 2 foo');
is($test[1], 'bar', 'readable 2 bar');

$pico->writable('foo', 'bar');
@test = $pico->writable;
is($test[0], 'foo', 'writable 2 foo');
is($test[1], 'bar', 'writable 2 bar');

$pico->condition('foo', 'bar');
@test = $pico->condition;
is($test[0], 'foo', 'condition 2 foo');
is($test[1], 'bar', 'condition 2 bar');

# arrayref

$pico->readable(['foo', 'bar']);
@test = $pico->readable;
is($test[0], 'foo', 'readable 3 foo');
is($test[1], 'bar', 'readable 3 bar');

$pico->writable(['foo', 'bar']);
@test = $pico->writable;
is($test[0], 'foo', 'writable 3 foo');
is($test[1], 'bar', 'writable 3 bar');

$pico->condition(['foo', 'bar']);
@test = $pico->condition;
is($test[0], 'foo', 'condition 3 foo');
is($test[1], 'bar', 'condition 3 bar');
