use strict;
use Test::More tests => 14;

BEGIN { use_ok 'SQL::Pico::Table' }

my $sp = SQL::Pico::Table->new;
$sp->table("tbl");
$sp->primary("p1", "p2");
$sp->readable("r1", "r2");
$sp->writable("w1", "w2");
my $sql;

sub std {
    my $str = shift;
    $str =~ s/[\"\`\s]+/ /sg;
    $str =~ s/\s+$//sg;
    $str;
}

my @sql  = ("WHERE r1 = ? AND w2 = ?", "v1", "v2");
my $hash = { p1 => 'i1', p2 => 'i2', w1 => 'v1', w2 => 'v2' };

$sql = $sp->index;
is(std($sql), "SELECT p1 , p2 FROM tbl", 'index()');

$sql = $sp->index(@sql);
is(std($sql), "SELECT p1 , p2 FROM tbl WHERE r1 = 'v1' AND w2 = 'v2'", 'index(SQL)');

$sql = $sp->select;
is(std($sql), "SELECT r1 , r2 FROM tbl", 'select()');

$sql = $sp->select(@sql);
is(std($sql), "SELECT r1 , r2 FROM tbl WHERE r1 = 'v1' AND w2 = 'v2'", 'select(SQL)');

$sql = $sp->select($hash);
is(std($sql), "SELECT r1 , r2 FROM tbl WHERE p1 = 'i1' AND p2 = 'i2'", 'select(HASH)');

$sql = $sp->insert($hash);
is(std($sql), "INSERT INTO tbl ( w1 , w2 ) VALUES ('v1', 'v2')", 'insert(HASH)');

$sql = $sp->update($hash, @sql);
is(std($sql), "UPDATE tbl SET w1 = 'v1', w2 = 'v2' WHERE r1 = 'v1' AND w2 = 'v2'", 'update(HASH, SQL)');

$sql = $sp->update($hash, $hash);
is(std($sql), "UPDATE tbl SET w1 = 'v1', w2 = 'v2' WHERE p1 = 'i1' AND p2 = 'i2'", 'update(HASH, HASH)');

$sql = $sp->delete(@sql);
is(std($sql), "DELETE FROM tbl WHERE r1 = 'v1' AND w2 = 'v2'", 'delete(SQL)');

$sql = $sp->delete($hash);
is(std($sql), "DELETE FROM tbl WHERE p1 = 'i1' AND p2 = 'i2'", 'delete(HASH)');

$sql = $sp->count;
is(std($sql), "SELECT count(*) FROM tbl", 'count()');

$sql = $sp->count(@sql);
is(std($sql), "SELECT count(*) FROM tbl WHERE r1 = 'v1' AND w2 = 'v2'", 'count(SQL)');

$sql = $sp->count($hash);
is(std($sql), "SELECT count(*) FROM tbl WHERE p1 = 'i1' AND p2 = 'i2'", 'count(HASH)');
