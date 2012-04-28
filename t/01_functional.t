use strict;
use Test::More tests => 8;

BEGIN { use_ok 'SQL::Pico' }

my $test;

$test = v("string");
is($test, "'string'", 'v(LITERAL)');

$test = sql("SELECT * FROM table WHERE id = ?", "id");
is($test, "SELECT * FROM table WHERE id = 'id'", 'sql(SQL, L1)');

$test = sql("SELECT * FROM table WHERE id = ? AND date < ?", "id", "2012-04-27");
is($test, "SELECT * FROM table WHERE id = 'id' AND date < '2012-04-27'", 'sql(SQL, L1, L2)');

$test = k("table_name");
is($test, '"table_name"', 'k(IDENTIFIER)');

$test = sql("SELECT * FROM ?? WHERE deleted = 0", "table_name");
is($test, 'SELECT * FROM "table_name" WHERE deleted = 0', 'sql(SQL, I1)');

$test = sql("SELECT * FROM ?? WHERE ?? = 0", "table_name", "deleted");
is($test, 'SELECT * FROM "table_name" WHERE "deleted" = 0', 'sql(SQL, I1, I2)');

$test = sql("SELECT * FROM ?? WHERE id = ?", "table_name", "id");
is($test, 'SELECT * FROM "table_name" WHERE id = '."'id'", 'sql(SQL, I1, L1)');

