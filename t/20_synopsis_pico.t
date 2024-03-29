use strict;
use Test::More;

eval {
    require DBD::SQLite;
};

if ($@) {
    plan skip_all => 'DBD::SQLite not installed';
} else {
    plan tests => 31;
}

use_ok 'SQL::Pico';

use SQL::Pico ();                         # nothing exported

my($dbh, $sp, $quoted, $sql, @list);

$dbh    = DBI->connect('dbi:SQLite::memory:','','',{});
ok(ref $dbh, 'connect');
my $name = $dbh->{Driver}->{Name} || '';
isnt($name, '', 'Driver Name - '.$name);

$sp   = SQL::Pico->new->dbh($dbh);
isa_ok($sp, 'SQL::Pico');

my $name2 = $sp->dbh->{Driver}->{Name} || '';
is($name2, $name, 'Driver Name - '.$name2);

my $val = 'foo';
$quoted = $sp->quote($val);             # $dbh->quote($val)
is($quoted, "'foo'", 'quote');

my $key = 'bar';
$quoted = $sp->quote_identifier($key);  # $dbh->quote_identifier($key)
is($quoted, '"bar"', 'quote_identifier');

my $table = 'hoge';
my $id = 'fuga';
$sql    = $sp->bind("SELECT * FROM ?? WHERE id = ?", $table, $id);
is($sql, "SELECT * FROM \"hoge\" WHERE id = 'fuga'", 'bind');

my @vals = qw(baz qux);
@list   = $sp->quote(@vals);            # multiple quotes at once
is(scalar(@list), 2, 'quote length');
is($list[0], "'baz'", 'quote 0');
is($list[1], "'qux'", 'quote 1');

my @keys = qw(quux corge);
@list   = $sp->quote_identifier(@keys); # ditto.
is(scalar(@list), 2, 'quote_identifier length');
is($list[0], '"quux"', 'quote_identifier 0');
is($list[1], '"corge"', 'quote_identifier 1');

$quoted = v("string");                    # quotes literal
is($quoted, "'string'", 'v');

$quoted = k("table_name");                # quotes identifier
is($quoted, '"table_name"', 'k');

$sql    = sql("SELECT * FROM ?? WHERE id = ?", $table, $id);
is($sql, "SELECT * FROM \"hoge\" WHERE id = 'fuga'", 'sql');

$sp = SQL::Pico->new(dbh => $dbh);
$name2 = $sp->dbh->{Driver}->{Name} || '';
is($name2, $name, 'Driver Name - '.$name2);

$sp = SQL::Pico->new;
$name2 = $sp->dbh->{Driver}->{Name} || '';
isnt($name2, $name, 'Driver Name - '.$name2);

$sp->dbh($dbh);
$name2 = $sp->dbh->{Driver}->{Name} || '';
is($name2, $name, 'Driver Name - '.$name2);

$quoted = SQL::Pico->new->dbh($dbh)->quote($val);
is($quoted, "'foo'", 'quote');

$quoted = $sp->quote($val);             # $dbh->quote($val)
is($quoted, "'foo'", 'quote');

@list   = $sp->quote(@vals);            # multiple quotes at once
is(scalar(@list), 2, 'quote length');
is($list[0], "'baz'", 'quote 0');
is($list[1], "'qux'", 'quote 1');

$quoted = $sp->quote_identifier($key);  # $dbh->quote_identifier($key)
is($quoted, '"bar"', 'quote_identifier');

@list   = $sp->quote_identifier(@keys); # multiple quotes at once
is(scalar(@list), 2, 'quote_identifier length');
is($list[0], '"quux"', 'quote_identifier 0');
is($list[1], '"corge"', 'quote_identifier 1');

$sql = $sp->bind("SELECT * FROM ?? WHERE id = ?", $table, $id);
is($sql, "SELECT * FROM \"hoge\" WHERE id = 'fuga'", 'sql');

SQL::Pico->dbh($dbh);
$name2 = SQL::Pico->dbh->{Driver}->{Name} || '';
is($name2, $name, 'Driver Name - '.$name2);
