use strict;
use Test::More tests => 15;

BEGIN { use_ok 'SQL::Pico' }

my $pico = SQL::Pico->new;
ok(ref $pico, 'new');

my $test;
my @test;

$test = $pico->quote("string");
is($test, "'string'", 'quote(LITERAL)');

@test = $pico->quote("foo", "bar");
is(scalar(@test), 2, 'quote(L1, L2)');
is($test[0], "'foo'", 'quote(L1, L2) - L1');
is($test[1], "'bar'", 'quote(L1, L2) - L2');

$test = $pico->bind("SELECT * FROM table WHERE id = ?", "id");
is($test, "SELECT * FROM table WHERE id = 'id'", 'bind(SQL, L1)');

$test = $pico->bind("SELECT * FROM table WHERE id = ? AND date < ?", "id", "2012-04-27");
is($test, "SELECT * FROM table WHERE id = 'id' AND date < '2012-04-27'", 'bind(SQL, L1, L2)');

$test = $pico->quote_identifier("table_name");
is($test, '"table_name"', 'quote_identifier(IDENTIFIER)');

@test = $pico->quote_identifier("foo", "bar");
is(scalar(@test), 2, 'quote_identifier(L1, L2)');
is($test[0], '"foo"', 'quote_identifier(L1, L2) - L1');
is($test[1], '"bar"', 'quote_identifier(L1, L2) - L2');

$test = $pico->bind("SELECT * FROM ?? WHERE deleted = 0", "table_name");
is($test, 'SELECT * FROM "table_name" WHERE deleted = 0', 'bind_identifier(SQL, I1)');

$test = $pico->bind("SELECT * FROM ?? WHERE ?? = 0", "table_name", "deleted");
is($test, 'SELECT * FROM "table_name" WHERE "deleted" = 0', 'bind_identifier(SQL, I1, I2)');

$test = $pico->bind("SELECT * FROM ?? WHERE id = ?", "table_name", "id");
is($test, 'SELECT * FROM "table_name" WHERE id = '."'id'", 'sql(SQL, I1, L1)');
