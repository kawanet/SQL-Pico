use strict;
use Test::More tests => 10;

BEGIN { use_ok 'SQL::Pico' }

my( $where, $select, $keys, $vals, $insert, $sets, $update, $in, $delete );

my %hash = qw( k1 v1 k2 v2 k3 v3 );
my @list = qw( i1 i2 i3 );

    $where  = join(" AND " => sql("?? = ?", %hash));

$where =~ s/\d/0/g;
is($where, q{"k0" = 'v0' AND "k0" = 'v0' AND "k0" = 'v0'}, 'where');

    $select = sql("SELECT * FROM mytbl WHERE ???", $where);

is($select, q{SELECT * FROM mytbl WHERE "k0" = 'v0' AND "k0" = 'v0' AND "k0" = 'v0'}, 'select');

    $keys   = join(", " => k(keys %hash));

$keys =~ s/\d/0/g;
is($keys, q{"k0", "k0", "k0"}, "keys");

    $vals   = join(", " => v(values %hash));

$vals =~ s/\d/0/g;
is($vals, q{'v0', 'v0', 'v0'}, 'vals');

    $insert = sql("INSERT INTO mytbl (???) VALUES (???)", $keys, $vals);

is($insert, q{INSERT INTO mytbl ("k0", "k0", "k0") VALUES ('v0', 'v0', 'v0')}, "insert");

    $sets   = join(", " => sql("?? = ?", %hash));

$sets =~ s/\d/0/g;
is($sets, q{"k0" = 'v0', "k0" = 'v0', "k0" = 'v0'}, 'sets');

    $update = sql("UPDATE mytbl SET ??? WHERE ???", $sets, $where);

is($update, q{UPDATE mytbl SET "k0" = 'v0', "k0" = 'v0', "k0" = 'v0' WHERE "k0" = 'v0' AND "k0" = 'v0' AND "k0" = 'v0'}, 'update');

    $in     = join(", " => v(@list));

is($in, q{'i1', 'i2', 'i3'}, 'in');

    $delete = sql("DELETE mytbl WHERE id IN (???)", $in);

is($delete, q{DELETE mytbl WHERE id IN ('i1', 'i2', 'i3')}, 'delete');
