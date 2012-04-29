use strict;
use Test::More tests => 11;

BEGIN { use_ok 'SQL::Pico' }

my $sqlp = SQL::Pico->new;
ok(ref $sqlp, 'new');

my( @res, $res );

eval { $res = $sqlp->bind("SELECT * FROM table WHERE id = ?", "id", "2012-04-27"); };
like($@, qr/Too many parameters/i, 'SCALAR bind("?", L1, L2) - too many parameters');

eval { $res = $sqlp->bind("SELECT * FROM table_name", "table_name"); };
like($@, qr/Placeholder not found/i, 'SCALAR bind("", L1) - placeholder not found');

eval { $res = $sqlp->bind("SELECT * FROM table WHERE id = ?"); };
like($@, qr/Parameter shortage/i, 'SCALAR bind("?") - parameter shortage');

eval { $res = $sqlp->bind("SELECT * FROM table WHERE id = ? AND date < ?", "id"); };
like($@, qr/Parameter shortage/i, 'SCALAR bind("? ?", L1) - parameter shortage');

eval { $res = $sqlp->bind("SELECT * FROM ????", "foobar"); };
like($@, qr/Invalid placeholder/i, 'SCALAR bind("????", L1) - invalid placeholder');

eval { @res = $sqlp->bind("SELECT * FROM table_name", "table_name"); };
like($@, qr/Placeholder not found/i, 'ARRAY bind("", L1) - placeholder not found');

eval { @res = $sqlp->bind("SELECT * FROM table WHERE id = ?"); };
like($@, qr/Parameter shortage/i, 'ARRAY bind("?") - parameter shortage');

eval { @res = $sqlp->bind("SELECT * FROM table WHERE id = ? AND date < ?", "id"); };
like($@, qr/Parameter shortage/i, 'ARRAY bind("? ?", L1) - parameter shortage');

eval { @res = $sqlp->bind("SELECT * FROM ????", "foobar"); };
like($@, qr/Invalid placeholder/i, 'ARRAY bind("????", L1) - invalid placeholder');
