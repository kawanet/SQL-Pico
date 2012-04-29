use strict;
use Test::More tests => 14;

BEGIN { use_ok 'SQL::Pico::Table' }

my $sqlp = SQL::Pico::Table->new;
$sqlp->table("tbl");
$sqlp->primary("p1", "p2");
$sqlp->readable("r1", "r2");
$sqlp->writable("w1", "w2");
my $sql;

sub std {
    my $str = shift;
    $str =~ s/[\"\`\s]+/ /sg;
    $str =~ s/\s+$//sg;
    $str;
}

my @sql  = ("WHERE r1 = ? AND w2 = ?", "v1", "v2");
my $hash = { p1 => 'i1', p2 => 'i2', w1 => 'v1', w2 => 'v2' };

$sql = $sqlp->index;
is(std($sql), "SELECT p1 , p2 FROM tbl", 'index()');

$sql = $sqlp->index(@sql);
is(std($sql), "SELECT p1 , p2 FROM tbl WHERE r1 = 'v1' AND w2 = 'v2'", 'index(SQL)');

$sql = $sqlp->select;
is(std($sql), "SELECT r1 , r2 FROM tbl", 'select()');

$sql = $sqlp->select(@sql);
is(std($sql), "SELECT r1 , r2 FROM tbl WHERE r1 = 'v1' AND w2 = 'v2'", 'select(SQL)');

$sql = $sqlp->select($hash);
is(std($sql), "SELECT r1 , r2 FROM tbl WHERE p1 = 'i1' AND p2 = 'i2'", 'select(HASH)');

$sql = $sqlp->insert($hash);
is(std($sql), "INSERT INTO tbl ( w1 , w2 ) VALUES ('v1', 'v2')", 'insert(HASH)');

$sql = $sqlp->update($hash, @sql);
is(std($sql), "UPDATE tbl SET w1 = 'v1', w2 = 'v2' WHERE r1 = 'v1' AND w2 = 'v2'", 'update(HASH, SQL)');

$sql = $sqlp->update($hash, $hash);
is(std($sql), "UPDATE tbl SET w1 = 'v1', w2 = 'v2' WHERE p1 = 'i1' AND p2 = 'i2'", 'update(HASH, HASH)');

$sql = $sqlp->delete(@sql);
is(std($sql), "DELETE FROM tbl WHERE r1 = 'v1' AND w2 = 'v2'", 'delete(SQL)');

$sql = $sqlp->delete($hash);
is(std($sql), "DELETE FROM tbl WHERE p1 = 'i1' AND p2 = 'i2'", 'delete(HASH)');

$sql = $sqlp->count;
is(std($sql), "SELECT count(*) FROM tbl", 'count()');

$sql = $sqlp->count(@sql);
is(std($sql), "SELECT count(*) FROM tbl WHERE r1 = 'v1' AND w2 = 'v2'", 'count(SQL)');

$sql = $sqlp->count($hash);
is(std($sql), "SELECT count(*) FROM tbl WHERE p1 = 'i1' AND p2 = 'i2'", 'count(HASH)');
