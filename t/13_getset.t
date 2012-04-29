use strict;
use Test::More tests => 18;

BEGIN { use_ok 'SQL::Pico::Table' }

my $sqlp = SQL::Pico::Table->new;
my $test;
my @test;

$sqlp->table('str1');
$test = $sqlp->table;
ok(! ref $test, 'table scalar');
is($test, 'str1', 'table str');

# scalar

$sqlp->readable('str2');
$test = $sqlp->readable;
is($test, 'str2', 'readable str');

$sqlp->writable('str3');
$test = $sqlp->writable;
is($test, 'str3', 'writable str');

$sqlp->condition('str4');
$test = $sqlp->condition;
is($test, 'str4', 'condition str');

# array

$sqlp->readable('foo', 'bar');
@test = $sqlp->readable;
is($test[0], 'foo', 'readable 2 foo');
is($test[1], 'bar', 'readable 2 bar');

$sqlp->writable('foo', 'bar');
@test = $sqlp->writable;
is($test[0], 'foo', 'writable 2 foo');
is($test[1], 'bar', 'writable 2 bar');

$sqlp->condition('foo', 'bar');
@test = $sqlp->condition;
is($test[0], 'foo', 'condition 2 foo');
is($test[1], 'bar', 'condition 2 bar');

# arrayref

$sqlp->readable(['foo', 'bar']);
@test = $sqlp->readable;
is($test[0], 'foo', 'readable 3 foo');
is($test[1], 'bar', 'readable 3 bar');

$sqlp->writable(['foo', 'bar']);
@test = $sqlp->writable;
is($test[0], 'foo', 'writable 3 foo');
is($test[1], 'bar', 'writable 3 bar');

$sqlp->condition(['foo', 'bar']);
@test = $sqlp->condition;
is($test[0], 'foo', 'condition 3 foo');
is($test[1], 'bar', 'condition 3 bar');
