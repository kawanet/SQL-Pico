use strict;
use Test::More tests => 6;

BEGIN { use_ok 'SQL::Pico' }

my $pico = SQL::Pico->new;
ok(ref $pico, 'new');

sub evaltest {
    my $name = shift;
    my $sub  = shift;
    local $@;
    eval { &$sub(); };
    ok($@, $name);
}


evaltest 'bind(?, L1, L2)'
=> sub { $pico->bind("SELECT * FROM table WHERE id = ?", "id", "2012-04-27"); };

evaltest 'bind(??, L1)'
=> sub { $pico->bind("SELECT * FROM table WHERE id = ? AND date < ?", "id"); };

evaltest 'bind_identifier(?, L1, L2)'
=> sub { $pico->bind_identifier("SELECT * FROM ? WHERE deleted = 0", "table_name", "deleted"); };

evaltest 'bind_identifier(??, L1)'
=> sub { $pico->bind_identifier("SELECT * FROM ? WHERE ? = 0", "table_name"); };

