use strict;
use Test::More tests => 14;

BEGIN { use_ok 'SQL::Pico::Table' }

my $sp = MyTestClass->new;
my $sql;

sub std {
    my $str = shift;
    $str =~ s/[\"\`\;\s]+/ /sg;
    $str =~ s/\s+$//sg;
    $str;
}

my @sql  = ("WHERE key = ?", "val");
my $hash = { pk => 'id', key => 'val' };

$sql = $sp->index;
is(std($sql), "SELECT pk FROM tbl WHERE deleted = 0", 'index()');

$sql = $sp->index(@sql);
is(std($sql), "SELECT pk FROM tbl WHERE deleted = 0 AND key = 'val'", 'index(SQL)');

$sql = $sp->select;
is(std($sql), "SELECT key FROM tbl WHERE deleted = 0", 'select()');

$sql = $sp->select(@sql);
is(std($sql), "SELECT key FROM tbl WHERE deleted = 0 AND key = 'val'", 'select(SQL)');

$sql = $sp->select($hash);
is(std($sql), "SELECT key FROM tbl WHERE deleted = 0 AND pk = 'id'", 'select(HASH)');

$sql = $sp->insert($hash);
is(std($sql), "INSERT INTO tbl ( key ) VALUES ('val')", 'insert(HASH)');

$sql = $sp->update($hash, @sql);
is(std($sql), "UPDATE tbl SET key = 'val' WHERE deleted = 0 AND key = 'val'", 'update(HASH, SQL)');

$sql = $sp->update($hash, $hash);
is(std($sql), "UPDATE tbl SET key = 'val' WHERE deleted = 0 AND pk = 'id'", 'update(HASH, HASH)');

$sql = $sp->delete(@sql);
is(std($sql), "DELETE FROM tbl WHERE deleted = 0 AND key = 'val'", 'delete(SQL)');

$sql = $sp->delete($hash);
is(std($sql), "DELETE FROM tbl WHERE deleted = 0 AND pk = 'id'", 'delete(HASH)');

$sql = $sp->count;
is(std($sql), "SELECT count(*) FROM tbl WHERE deleted = 0", 'count()');

$sql = $sp->count(@sql);
is(std($sql), "SELECT count(*) FROM tbl WHERE deleted = 0 AND key = 'val'", 'count(SQL)');

$sql = $sp->count($hash);
is(std($sql), "SELECT count(*) FROM tbl WHERE deleted = 0 AND pk = 'id'", 'count(HASH)');

package MyTestClass;
use base 'SQL::Pico::Table';

sub _build_table { "tbl" }
sub _build_primary { "pk" }
sub _build_readable { "key" }
sub _build_writable { "key" }
sub _build_condition { "deleted = 0" }
