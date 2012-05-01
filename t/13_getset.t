use strict;
use Test::More tests => 18;

BEGIN { use_ok 'SQL::Pico::Table' }

my $sp = SQL::Pico::Table->new;
my $test;
my @test;

$sp->table('str1');
$test = $sp->table;
ok(! ref $test, 'table scalar');
is($test, 'str1', 'table str');

# scalar

$sp->readable('str2');
$test = $sp->readable;
is($test, 'str2', 'readable str');

$sp->writable('str3');
$test = $sp->writable;
is($test, 'str3', 'writable str');

$sp->condition('str4');
$test = $sp->condition;
is($test, 'str4', 'condition str');

# array

$sp->readable('foo', 'bar');
@test = $sp->readable;
is($test[0], 'foo', 'readable 2 foo');
is($test[1], 'bar', 'readable 2 bar');

$sp->writable('foo', 'bar');
@test = $sp->writable;
is($test[0], 'foo', 'writable 2 foo');
is($test[1], 'bar', 'writable 2 bar');

$sp->condition('foo', 'bar');
@test = $sp->condition;
is($test[0], 'foo', 'condition 2 foo');
is($test[1], 'bar', 'condition 2 bar');

# arrayref

$sp->readable(['foo', 'bar']);
@test = $sp->readable;
is($test[0], 'foo', 'readable 3 foo');
is($test[1], 'bar', 'readable 3 bar');

$sp->writable(['foo', 'bar']);
@test = $sp->writable;
is($test[0], 'foo', 'writable 3 foo');
is($test[1], 'bar', 'writable 3 bar');

$sp->condition(['foo', 'bar']);
@test = $sp->condition;
is($test[0], 'foo', 'condition 3 foo');
is($test[1], 'bar', 'condition 3 bar');
