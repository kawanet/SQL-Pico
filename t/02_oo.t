use strict;
use Test::More tests => 18;

BEGIN { use_ok 'SQL::Pico' }

my $sqlp = SQL::Pico->new;
ok(ref $sqlp, 'new');

my $test;
my @test;

$test = $sqlp->quote("string");
is($test, "'string'", 'quote(LITERAL)');

@test = $sqlp->quote("foo", "bar");
is(scalar(@test), 2, 'quote(L1, L2)');
is($test[0], "'foo'", 'quote(L1, L2) - L1');
is($test[1], "'bar'", 'quote(L1, L2) - L2');

$test = $sqlp->bind("SELECT * FROM table WHERE id = ?", "id");
is($test, "SELECT * FROM table WHERE id = 'id'", 'bind(SQL, L1)');

$test = $sqlp->bind("SELECT * FROM table WHERE id = ? AND date < ?", "id", "2012-04-27");
is($test, "SELECT * FROM table WHERE id = 'id' AND date < '2012-04-27'", 'bind(SQL, L1, L2)');

$test = $sqlp->quote_identifier("table_name");
is($test, '"table_name"', 'quote_identifier(IDENTIFIER)');

@test = $sqlp->quote_identifier("foo", "bar");
is(scalar(@test), 2, 'quote_identifier(L1, L2)');
is($test[0], '"foo"', 'quote_identifier(L1, L2) - L1');
is($test[1], '"bar"', 'quote_identifier(L1, L2) - L2');

$test = $sqlp->bind("SELECT * FROM ?? WHERE deleted = 0", "table_name");
is($test, 'SELECT * FROM "table_name" WHERE deleted = 0', 'bind(SQL, I1)');

$test = $sqlp->bind("SELECT * FROM ?? WHERE ?? = 0", "table_name", "deleted");
is($test, 'SELECT * FROM "table_name" WHERE "deleted" = 0', 'bind(SQL, I1, I2)');

$test = $sqlp->bind("SELECT * FROM ?? WHERE id = ?", "table_name", "id");
is($test, 'SELECT * FROM "table_name" WHERE id = '."'id'", 'bind(SQL, I1, L1)');

my $hash = { k1 => 'v1', k2 => 'v2' };
my $where;

$where = join " AND " => map {$sqlp->bind("?? = ?", $_, $hash->{$_})} sort keys %$hash;
is($where, q{"k1" = 'v1' AND "k2" = 'v2'}, 'join map bind sort keys');

$where = join " AND " => sort $sqlp->bind("?? = ?", %$hash);
is($where, q{"k1" = 'v1' AND "k2" = 'v2'}, 'join sort bind');

$test = $sqlp->bind("SELECT * FROM ?? WHERE ???", "table_name", $where);
is($test, q{SELECT * FROM "table_name" WHERE "k1" = 'v1' AND "k2" = 'v2'}, 'bind(I1, S1)');
