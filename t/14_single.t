use strict;
use Test::More tests => 14;

BEGIN { use_ok 'SQL::Pico::Table' }

my $pico = SQL::Pico::Table->new;
$pico->table("tbl");
$pico->primary("pk");
$pico->readable("key");
$pico->writable("key");
my $sql;

sub std {
    my $str = shift;
    $str =~ s/[\"\`\;\s]+/ /sg;
    $str =~ s/\s+$//sg;
    $str;
}

my @sql  = ("WHERE key = ?", "val");
my $hash = { pk => 'id', key => 'val' };

$sql = $pico->index;
is(std($sql), "SELECT pk FROM tbl", 'index()');

$sql = $pico->index(@sql);
is(std($sql), "SELECT pk FROM tbl WHERE key = 'val'", 'index(SQL)');

$sql = $pico->select;
is(std($sql), "SELECT key FROM tbl", 'select()');

$sql = $pico->select(@sql);
is(std($sql), "SELECT key FROM tbl WHERE key = 'val'", 'select(SQL)');

$sql = $pico->select($hash);
is(std($sql), "SELECT key FROM tbl WHERE pk = 'id'", 'select(HASH)');

$sql = $pico->insert($hash);
is(std($sql), "INSERT INTO tbl ( key ) VALUES ('val')", 'insert(HASH)');

$sql = $pico->update($hash, @sql);
is(std($sql), "UPDATE tbl SET key = 'val' WHERE key = 'val'", 'update(HASH, SQL)');

$sql = $pico->update($hash, $hash);
is(std($sql), "UPDATE tbl SET key = 'val' WHERE pk = 'id'", 'update(HASH, HASH)');

$sql = $pico->delete(@sql);
is(std($sql), "DELETE FROM tbl WHERE key = 'val'", 'delete(SQL)');

$sql = $pico->delete($hash);
is(std($sql), "DELETE FROM tbl WHERE pk = 'id'", 'delete(HASH)');

$sql = $pico->count;
is(std($sql), "SELECT count(*) FROM tbl", 'count()');

$sql = $pico->count(@sql);
is(std($sql), "SELECT count(*) FROM tbl WHERE key = 'val'", 'count(SQL)');

$sql = $pico->count($hash);
is(std($sql), "SELECT count(*) FROM tbl WHERE pk = 'id'", 'count(HASH)');
