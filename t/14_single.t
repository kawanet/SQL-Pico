use strict;
use Test::More tests => 14;

BEGIN { use_ok 'SQL::Pico::Table' }

my $sqlp = SQL::Pico::Table->new;
$sqlp->table("tbl");
$sqlp->primary("pk");
$sqlp->readable("key");
$sqlp->writable("key");
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
is(std($sql), "SELECT pk FROM tbl", 'index()');

$sql = $sqlp->index(@sql);
is(std($sql), "SELECT pk FROM tbl WHERE key = 'val'", 'index(SQL)');

$sql = $sqlp->select;
is(std($sql), "SELECT key FROM tbl", 'select()');

$sql = $sqlp->select(@sql);
is(std($sql), "SELECT key FROM tbl WHERE key = 'val'", 'select(SQL)');

$sql = $sqlp->select($hash);
is(std($sql), "SELECT key FROM tbl WHERE pk = 'id'", 'select(HASH)');

$sql = $sqlp->insert($hash);
is(std($sql), "INSERT INTO tbl ( key ) VALUES ('val')", 'insert(HASH)');

$sql = $sqlp->update($hash, @sql);
is(std($sql), "UPDATE tbl SET key = 'val' WHERE key = 'val'", 'update(HASH, SQL)');

$sql = $sqlp->update($hash, $hash);
is(std($sql), "UPDATE tbl SET key = 'val' WHERE pk = 'id'", 'update(HASH, HASH)');

$sql = $sqlp->delete(@sql);
is(std($sql), "DELETE FROM tbl WHERE key = 'val'", 'delete(SQL)');

$sql = $sqlp->delete($hash);
is(std($sql), "DELETE FROM tbl WHERE pk = 'id'", 'delete(HASH)');

$sql = $sqlp->count;
is(std($sql), "SELECT count(*) FROM tbl", 'count()');

$sql = $sqlp->count(@sql);
is(std($sql), "SELECT count(*) FROM tbl WHERE key = 'val'", 'count(SQL)');

$sql = $sqlp->count($hash);
is(std($sql), "SELECT count(*) FROM tbl WHERE pk = 'id'", 'count(HASH)');
