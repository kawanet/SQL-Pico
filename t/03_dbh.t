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

my $sp;

$sp = SQL::Pico->new(dbh => $nullp);
is($sp->dbh->{Driver}->{Name}, 'NullP', 'NullP - new');

$sp = SQL::Pico->new(dbh => $sponge);
is($sp->dbh->{Driver}->{Name}, 'Sponge', 'Sponge - new');

$sp = SQL::Pico->dbh($nullp);
is($sp->dbh->{Driver}->{Name}, 'NullP', 'NullP - dbh');

$sp->dbh($sponge);
is($sp->dbh->{Driver}->{Name}, 'Sponge', 'Sponge - dbh');

$sp->dbh($nullp);
is($sp->dbh->{Driver}->{Name}, 'NullP', 'NullP - dbh');
