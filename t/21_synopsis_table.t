use strict;
use Test::More;

eval {
    require DBD::SQLite;
};

if ($@) {
    plan skip_all => 'DBD::SQLite not installed';
} else {
    plan tests => 64;
}

use_ok 'SQL::Pico::Table';

my($mytbl, $dbh, $sql, $hash, $hasharray, $arrayref, $exist, $total, $rv, @list, $name);

$dbh    = DBI->connect('dbi:SQLite::memory:','','',{});
ok(ref $dbh, 'dbh connect');
$name = $dbh->{Driver}->{Name} || '';
isnt($name, '', 'dbh Driver Name - '.$name);

$rv = $dbh->do(<<SQL);
CREATE TABLE mytable (
    id integer primary key autoincrement,
    name varchar(10),
    price int,
    category varchar(10),
    deleted int);
SQL
ok($rv, 'CREATE TABLE mytable');
$rv = $dbh->do("INSERT INTO mytable (id, name) VALUES ('1', 'buzqux')");
ok($rv, 'INSERT INTO mytable (buzquz)');

           $mytbl = SQL::Pico::Table->new;
           $mytbl->dbh($dbh);
           $mytbl->table('mytable');
           $mytbl->primary('id');

isa_ok($mytbl, 'SQL::Pico::Table');
is($mytbl->dbh->{Driver}->{Name}, $name, 'dbh Driver Name');
is($mytbl->table, 'mytable', 'synopsis table');
is($mytbl->primary, 'id', 'synopsis primary');

           $sql  = $mytbl->select({id => 1});
           $hash = $dbh->selectrow_hashref($sql);

is($sql, "SELECT * FROM \"mytable\" WHERE \"id\" = '1'", 'synopsis select');
is(ref $hash, 'HASH', 'synopsis selectrow_hashref');
is($hash->{id}, '1', 'synopsis selectrow_hashref id');
is($hash->{name}, 'buzqux', 'synopsis selectrow_hashref name');

           $sql = $mytbl->insert({name => 'foobar'});
           $dbh->do($sql) or die "insert failed";

is($sql, "INSERT INTO \"mytable\" (\"name\") VALUES ('foobar')", 'synopsis insert');
ok($rv, 'synopsis INSERT INTO (foobar)');

           $sql = $mytbl->update({name => 'foobar'}, {id => 1});
           $dbh->do($sql) or die "update failed";

is($sql, "UPDATE \"mytable\" SET \"name\" = 'foobar' WHERE \"id\" = '1'", 'synopsis update');
ok($rv, 'synopsis UPDATE mytable');

           $sql = $mytbl->delete({id => 1});
           $rv = $dbh->do($sql); # or die "delete failed";

is($sql, "DELETE FROM \"mytable\" WHERE \"id\" = '1'", 'synopsis delete');
ok($rv, 'synopsis DELETE FROM mytable');
$rv = $dbh->do("INSERT INTO mytable (id, name) VALUES ('1', 'garply')");
ok($rv, 'synopsis INSERT INTO mytable (garply)');

           $mytbl->primary('category', 'name');
           $mytbl->readable(qw( id category name price ));
           $mytbl->writable(qw( category name price ));
           $mytbl->condition('deleted = 0');

@list = $mytbl->primary;
is_deeply(\@list, ['category', 'name'], 'param primary');
@list = $mytbl->readable;
is_deeply(\@list, [qw( id category name price )], 'param readable');
@list = $mytbl->writable;
is_deeply(\@list, [qw( category name price )], 'param writable');
@list = $mytbl->condition;
is_deeply(\@list, ['deleted = 0'], 'param condition');
 
           $mytbl = SQL::Pico::Table->new;
           $mytbl->table('mytable');
           $mytbl->primary('id');
           $mytbl->readable(qw( name price ));
           $mytbl->writable(qw( name price ));

@list = $mytbl->table;
is_deeply(\@list, ['mytable'], 'param table');
@list = $mytbl->primary;
is_deeply(\@list, ['id'], 'param primary');
@list = $mytbl->readable;
is_deeply(\@list, [qw( name price )], 'param readable');
@list = $mytbl->writable;
is_deeply(\@list, [qw( name price )], 'param writable');

           # SELECT name, price FROM mytable WHERE id = '1'
           $sql  = $mytbl->select({id => 1});
           $hash = $dbh->selectrow_hashref($sql);

is($sql, "SELECT \"name\", \"price\" FROM \"mytable\" WHERE \"id\" = '1'", 'select 1');
is(ref $hash, 'HASH', 'select 1 selectrow_hashref');
is($hash->{name}, 'garply', 'select 1 name');

           # SELECT name, price FROM mytable
           $sql       = $mytbl->select;
           $hasharray = $dbh->selectall_arrayref($sql, {Slice=>{}});

is($sql, q{SELECT "name", "price" FROM "mytable"}, 'select all');
is(ref $hasharray, 'ARRAY', 'select all selectall_arrayref');
is(ref($hasharray->[0]), 'HASH', 'select all selectall_arrayref->[0]');
ok($hasharray->[0]->{name}, 'select all selectall_arrayref name');

           # INSERT INTO mytable ( name, price ) VALUES ( 'corge', '100' )
           $sql = $mytbl->insert({name => 'corge', price => '100'});
           $rv = $dbh->do($sql); ## or die "insert failed";

is($sql, q{INSERT INTO "mytable" ("name", "price") VALUES ('corge', '100')}, 'insert');
ok($rv, 'insert INSERT INTO mytable (corge)');

           # UPDATE mytable SET name = 'corge', price = '100' WHERE id = '1'
           $sql = $mytbl->update({name => 'corge', price => '100'}, {id => 1});
           $rv = $dbh->do($sql); ## or die "update failed";

is($sql, q{UPDATE "mytable" SET "name" = 'corge', "price" = '100' WHERE "id" = '1'}, 'update');
ok($rv, 'update UPDATE mytable');

           # DELETE FROM mytable WHERE id = '1'
           $sql = $mytbl->delete({id => 1});
           $rv = $dbh->do($sql); ## or die "delete failed";

is($sql, q{DELETE FROM "mytable" WHERE "id" = '1'}, 'delete');
ok($rv, 'delete DELETE FROM mytable');
$rv = $dbh->do("INSERT INTO mytable (id, name, price) VALUES ('1', 'waldo', '50')");
ok($rv, 'delete INSERT INTO mytable (waldo)');

           # SELECT id FROM mytable
           $sql      = $mytbl->index;
           $arrayref = $dbh->selectcol_arrayref($sql);

is($sql, q{SELECT "id" FROM "mytable"}, 'index');
is(ref $arrayref, 'ARRAY', 'index ref');
ok(scalar(@$arrayref), 'index scalar');

           # SELECT count(*) FROM mytable WHERE id = '1'
           $sql   = $mytbl->count({id => 1});
           $exist = $dbh->selectrow_array($sql);

is($sql, q{SELECT count(*) FROM "mytable" WHERE "id" = '1'}, "count");
ok($exist, 'count exist');

           # SELECT count(*) FROM mytable
           $sql   = $mytbl->count;
           $total = $dbh->selectrow_array($sql);

is($sql, q{SELECT count(*) FROM "mytable"}, "count");
ok($total, 'count total');

           # SELECT * FROM mytable WHERE price < '100'
           $sql = $mytbl->select("WHERE price < ?", "100");
           $hasharray = $dbh->selectall_arrayref($sql, {Slice=>{}});

is($sql, q{SELECT "name", "price" FROM "mytable" WHERE price < '100'}, "where select");
is(ref $hasharray, 'ARRAY', 'where selectall_arrayref ARRAY');
is(ref($hasharray->[0]), 'HASH', 'where selectall_arrayref ARRAY HASH');
is($hasharray->[0]->{name}, 'waldo', 'where selectall_arrayref name');

           # UPDATE mytable SET name = 'corge' WHERE price < '100'
           $sql = $mytbl->update({name => 'corge'}, "WHERE price < ?", "100");
           $rv = $dbh->do($sql); # or die "update failed";

is($sql, q{UPDATE "mytable" SET "name" = 'corge' WHERE price < '100'}, "where update");
ok($rv, 'update UPDATE mytable');

           # DELETE FROM mytable WHERE price < '100'
           $sql = $mytbl->delete("WHERE price < ?", "100");
           ## $dbh->do($sql) or die "delete failed";

is($sql, q{DELETE FROM "mytable" WHERE price < '100'}, "where delete");
$rv = $dbh->do("INSERT INTO mytable (name, price, deleted) VALUES ('grault', 50, 0)");
ok($rv, 'where INSERT INTO mytable (grault)');

           # SELECT id FROM mytable WHERE price < '100'
           $sql = $mytbl->index("WHERE price < ?", "100");
           $arrayref = $dbh->selectcol_arrayref($sql);

is($sql, q{SELECT "id" FROM "mytable" WHERE price < '100'}, "where index");
is(ref $arrayref, 'ARRAY', 'where selectcol_arrayref');

           # SELECT count(*) FROM mytable WHERE price < '100'
           $sql = $mytbl->count("WHERE price < ?", "100");
           $total = $dbh->selectrow_array($sql);

is($sql, q{SELECT count(*) FROM "mytable" WHERE price < '100'}, "where count");
ok($total, 'where total');

           package MyTable;
           use base 'SQL::Pico::Table';

           sub _build_table { 'mytable' }
           sub _build_primary { 'id' }
           sub _build_readable {qw( id category name price )}
           sub _build_writable {qw( category name price )}
           sub _build_condition { 'deleted = 0' }

           package main;

           $mytbl     = MyTable->new;
           $sql       = $mytbl->select({id => 1});

$mytbl->dbh($dbh);
$sql = $mytbl->select({id => 4});

           $hash = $dbh->selectrow_hashref($sql);

is($sql, q{SELECT "id", "category", "name", "price" FROM "mytable" WHERE deleted = 0 AND "id" = '4'}, 'subclass select');
is(ref $hash, 'HASH', 'subclass selectrow_hashref HASH');
is($hash->{id}, '4', 'subclass id');

;1;
