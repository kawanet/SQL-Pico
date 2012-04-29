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

my $sqlp;

$sqlp = SQL::Pico->new(dbh => $nullp);
is($sqlp->dbh->{Driver}->{Name}, 'NullP', 'NullP - new');

$sqlp = SQL::Pico->new(dbh => $sponge);
is($sqlp->dbh->{Driver}->{Name}, 'Sponge', 'Sponge - new');

$sqlp = SQL::Pico->dbh($nullp);
is($sqlp->dbh->{Driver}->{Name}, 'NullP', 'NullP - dbh');

$sqlp->dbh($sponge);
is($sqlp->dbh->{Driver}->{Name}, 'Sponge', 'Sponge - dbh');

$sqlp->dbh($nullp);
is($sqlp->dbh->{Driver}->{Name}, 'NullP', 'NullP - dbh');
