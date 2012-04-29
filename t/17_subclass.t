use strict;
use Test::More tests => 14;

BEGIN { use_ok 'SQL::Pico::Table' }

my $sqlp = MyTestClass->new;
my $sql;

sub std {
    my $str = shift;
    $str =~ s/[\"\`\;\s]+/ /sg;
    $str =~ s/\s+$//sg;
    $str;
}

my @sql  = ("WHERE key = ?", "val");
my $hash = { pk => 'id', key => 'val' };

$sql = $sqlp->index;
is(std($sql), "SELECT pk FROM tbl WHERE deleted = 0", 'index()');

$sql = $sqlp->index(@sql);
is(std($sql), "SELECT pk FROM tbl WHERE deleted = 0 AND key = 'val'", 'index(SQL)');

$sql = $sqlp->select;
is(std($sql), "SELECT key FROM tbl WHERE deleted = 0", 'select()');

$sql = $sqlp->select(@sql);
is(std($sql), "SELECT key FROM tbl WHERE deleted = 0 AND key = 'val'", 'select(SQL)');

$sql = $sqlp->select($hash);
is(std($sql), "SELECT key FROM tbl WHERE deleted = 0 AND pk = 'id'", 'select(HASH)');

$sql = $sqlp->insert($hash);
is(std($sql), "INSERT INTO tbl ( key ) VALUES ('val')", 'insert(HASH)');

$sql = $sqlp->update($hash, @sql);
is(std($sql), "UPDATE tbl SET key = 'val' WHERE deleted = 0 AND key = 'val'", 'update(HASH, SQL)');

$sql = $sqlp->update($hash, $hash);
is(std($sql), "UPDATE tbl SET key = 'val' WHERE deleted = 0 AND pk = 'id'", 'update(HASH, HASH)');

$sql = $sqlp->delete(@sql);
is(std($sql), "DELETE FROM tbl WHERE deleted = 0 AND key = 'val'", 'delete(SQL)');

$sql = $sqlp->delete($hash);
is(std($sql), "DELETE FROM tbl WHERE deleted = 0 AND pk = 'id'", 'delete(HASH)');

$sql = $sqlp->count;
is(std($sql), "SELECT count(*) FROM tbl WHERE deleted = 0", 'count()');

$sql = $sqlp->count(@sql);
is(std($sql), "SELECT count(*) FROM tbl WHERE deleted = 0 AND key = 'val'", 'count(SQL)');

$sql = $sqlp->count($hash);
is(std($sql), "SELECT count(*) FROM tbl WHERE deleted = 0 AND pk = 'id'", 'count(HASH)');

package MyTestClass;
use base 'SQL::Pico::Table';

sub _build_table { "tbl" }
sub _build_primary { "pk" }
sub _build_readable { "key" }
sub _build_writable { "key" }
sub _build_condition { "deleted = 0" }
