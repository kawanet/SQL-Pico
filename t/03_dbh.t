use strict;
use Test::More tests => 13;

BEGIN {
    use_ok 'SQL::Pico';
    use_ok 'DBI';
    use_ok 'DBD::NullP';
    use_ok 'DBD::Sponge';
}

my $nullp  = DBI->connect('dbi:NullP:');
ok(ref $nullp, 'NullP');
is($nullp->{Driver}->{Name}, 'NullP', 'NullP - name');

my $sponge = DBI->connect('dbi:Sponge:');
ok(ref $sponge, 'Sponge');
is($sponge->{Driver}->{Name}, 'Sponge', 'Sponge - name');

my $pico;

$pico = SQL::Pico->new(dbh => $nullp);
is($pico->dbh->{Driver}->{Name}, 'NullP', 'NullP - new');

$pico = SQL::Pico->new(dbh => $sponge);
is($pico->dbh->{Driver}->{Name}, 'Sponge', 'Sponge - new');

$pico = SQL::Pico->dbh($nullp);
is($pico->dbh->{Driver}->{Name}, 'NullP', 'NullP - dbh');

$pico->dbh($sponge);
is($pico->dbh->{Driver}->{Name}, 'Sponge', 'Sponge - dbh');

$pico->dbh($nullp);
is($pico->dbh->{Driver}->{Name}, 'NullP', 'NullP - dbh');
