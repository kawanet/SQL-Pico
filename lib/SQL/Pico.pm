package SQL::Pico;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.01';
our @EXPORT  = qw(v k sql);
our @DSN     = ("dbi:NullP:");

use Carp;
use DBI;

sub v {
    __PACKAGE__->instance->quote(@_);
}

sub k {
    __PACKAGE__->instance->quote_identifier(@_);
}

sub sql {
    __PACKAGE__->instance->bind(@_);
}

sub new {
    my $class = shift;
    bless {@_}, $class;
}

my $instance;
sub instance {
    my $self = shift;
    Carp::croak "Invalid parameters" if @_;
    $instance ||= $self->new;
}

sub dbh {
    my $self = shift;
    $self = $self->instance unless ref $self;
    if (@_) {
        $self->{dbh} = shift;
        return $self;
    }
    $self->{dbh} ||= DBI->connect(@DSN);
}

sub quote {
    my $self = shift;
    $self = $self->instance unless ref $self;
    my $dbh = $self->dbh;
    return $dbh->quote(shift) unless wantarray;
    map { $dbh->quote($_) } @_;
}

sub quote_identifier {
    my $self = shift;
    $self = $self->instance unless ref $self;
    my $dbh = $self->dbh;
    return $dbh->quote_identifier(shift) unless wantarray;
    map { $dbh->quote_identifier($_) } @_;
}

sub bind {
    my $self = shift;
    my $sql  = shift;
    Carp::croak "SQL statement not given" unless defined $sql;
    $self = $self->instance unless ref $self;
    my $dbh   = $self->dbh;
    my $list  = [];
    while (1) {
        my $str = "$sql"; # copy
        my $cnt = ($str =~ s{(\?+)}{
            Carp::croak "Parameter shortage" unless @_;
            $1 eq '?' ? $dbh->quote(shift) :
            $1 eq '??' ? $dbh->quote_identifier(shift) :
            $1 eq '???' ? shift :
            Carp::croak "Invalid placeholder: '$1'";
        }ge);
        push(@$list, $str);
        last unless @_;
        Carp::croak "Placeholder not found while parameters given" unless $cnt;
        Carp::croak "Too many parameters given" unless wantarray;
    }
    wantarray ? @$list : shift @$list;
}

1;
__END__
=encoding utf-8

=head1 NAME

SQL::Pico - Prebuilt Raw SQL Statement Builder

=head1 SYNOPSIS

    use SQL::Pico ();
    
    $dbh    = DBI->connect(...);
    $sp     = SQL::Pico->new->dbh($dbh);
    $quoted = $sp->quote($val);             # $dbh->quote($val)
    $quoted = $sp->quote_identifier($key);  # $dbh->quote_identifier($key)

    $select = $sp->bind("SELECT * FROM ?? WHERE id = ?", $table, $id);
    
    $where  = join(" AND " => $sp->bind("?? = ?", %hash));
    $select = $sp->bind("SELECT * FROM mytbl WHERE ???", $where);

    $keys   = join(", " => $sp->quote_identifier(keys %hash));
    $vals   = join(", " => $sp->quote(values %hash));
    $insert = $sp->bind("INSERT INTO mytbl (???) VALUES (???)", $keys, $vals);

    $sets   = join(", " => $sp->bind("?? = ?", %hash));
    $update = $sp->bind("UPDATE mytbl SET ??? WHERE id = ?", $sets, $id);

    $in     = join(", " => $sp->quote(@list));
    $delete = $sp->bind("DELETE mytbl WHERE id IN (???)", $in);

=head1 DESCRIPTION

This provides a simple but safe way to build raw SQL statements
without learning any other languages than Perl and SQL.
C<SQL::Pico> is lightweight and doesn't require any non-core modules
except for L<DBI>.

C<SQL::Pico>'s C<bind()> method generates a SQL statement
which placeholders are filled with immediate values bound.
This makes you free from handling bind values and calling C<prepare()>.
See C<RECIPES> section below.

=head2 Why "Prebuilt" SQL?

Because SQL is the most simplest language to comunicate with RDBMS.

The most of ORM modules and something I<SQL::Builder>-ish modules would have
required you to understand its complex class structure or dialectal DSL.

This module simply provides just one of new method, C<bind()>,
which allows you to build SQL statements using placeholders,
as well as C<quote()> and C<quote_identifier()> methods
which are wrappers for C<DBI>'s methods with the same name you already know.

The most of modern Web applications would not cache prepared C<$sth>
instances though they would cache a connected C<$dbh> instance.
It means you don't need to worry about its performance (dis)advantage
when you don't use bind values at C<execute()>.

=head1 METHODS

=head2 new(PARAMETERS)

This creates a C<SQL::Pico> instance.

    $sp = SQL::Pico->new;

This accepts key/value pair(s) as its initial parameters.
Only C<dbh> parameter is available at this module.

    $sp = SQL::Pico->new(dbh => $dbh);

=head2 dbh(DBHANDLE)

This is an accessor to specify a C<DBI> instance.

    $sp = SQL::Pico->new;
    $sp->dbh($dbh);

The setter returns the current C<SQL::Pico> instance
for you to chain method calls.

    $quoted = SQL::Pico->new->dbh($dbh)->quote($val);

Please note that quoting formats for literals and identifiers
depend on RDBMS server you connect.
For example, a literal string "Don't" would be quoted as
'Don''t' in a server, as well as 'Don\'t', "Don't", etc. in others.

This supports SQL-92 Standard's quoting format, per default,
under L<DBD::NullP> driver which is included in C<DBI> distribution.
You could specify a C<DBI> instance to make string quoted properly
for your RDBMS server.

=head2 quote(LITERAL)

This calls C<DBI>'s C<quote()> method internally.

    $quoted = $sp->quote($val);             # $dbh->quote($val)

This doesn't accept literal's data type specified at its second argument.
The other difference to original is that this accept multiple arguments
and returns them quoted.

    @list   = $sp->quote(@vals);            # multiple quotes at once

=head2 quote_identifier(IDENTIFIER)

This calls C<DBI>'s C<quote_identifier()> method internally.

    $quoted = $sp->quote_identifier($key);  # $dbh->quote_identifier($key)

Multiple arguments are allowed as well.

    @list   = $sp->quote_identifier(@keys); # multiple quotes at once

=head2 bind(SQL, VALUES...)

This builds a SQL statement by using placeholders with bind values.

    $sql = $sp->bind("SELECT * FROM ?? WHERE id = ?", $table, $id);

Note that this returns a SQL statement built with values bound
at the method prior to C<DBI>'s <execute()> method called.

Three types of placeholders are allowed at the first argument:

Single character of C<?> represents a placeholder for a literal
which will be escaped by C<quote()>.

Double characters of C<??> represents a placeholder for an identifier
which will be escaped by C<quote_identifier()>.

Triple characters of C<???> represents a placeholder for a raw SQL
string which will not be escaped.

    $hash   = {"category" => "foo", "price" => "100"};
    @list   = $sp->bind("?? = ?", %$hash);
    $where  = join(" AND ", @list);
    $select = "SELECT * FROM mytable WHERE $where";

    # SELECT * FROM mytable WHERE "category" = 'foo' AND "price" = '100'
    # Note that the order of key/value pairs vary.

In list context, this returns a list of strings repeatedly built
with parameters following.

=head1 FUNCTIONS

In addition to the OO style described above, this also supports
the functional style below by exporting three shortcut functions:
C<v()>, C<k()> and C<sql()> per default.

    use SQL::Pico;                            # functions exported
    
=head2 v(LITERAL)

This is a shortcut for C<quote()> method
which quotes a literal, e.g. string, number, etc.

    $quoted = v("string");                    # quotes literal
    @quoted = v("foo", "bar", "100");         # multiple literals

=head2 k(IDENTIFIER)

This is a shortcut for C<quote_identifier()> method
which quotes an identifier, e.g. table name, column name, etc.

    $quoted = k("table_name");                # quotes identifier
    @quoted = k("category", "name", "price"); # multiple identifiers

=head2 sql(SQL, VALUES...)

This is a shortcut for C<bind()> method
which builds a SQL statement by using placeholders with bind values.

    $select = sql("SELECT * FROM ?? WHERE id = ?", $table, $id);

=head2 dbh(DBHANDLE)

Call C<dbh()> class method to specify the database handle
for those C<v()>, C<k()> and C<sql()> functions above.

    $dbh = DBI->connect(...);
    SQL::Pico->dbh($dbh);

Note that C<dbh()> method is not exported.

=head1 RECIPES

The recipes show which C<DBI> methods would follow SQL statements
built by C<sql()> function.

    # fetch a single record as a hahsref
    $sql   = sql("SELECT * FROM mytable WHERE id = ?", $id);
    $hash  = $dbh->selectrow_hashref($sql);
    
    # fetch multiple records as an arrayref of hashrefs
    $in    = join(", " => v(@list));
    $sql   = sql("SELECT * FROM mytable WHERE id IN (???)", $in);
    $array = $dbh->selectall_arrayref($sql, {Slice=>{}});
    
    # fetch a list of a single column as an arrayref
    $sql   = sql("SELECT id FROM mytable WHERE price < ?", $price);
    $array = $dbh->selectcol_arrayref($sql);
    
    # fetch a list of a pair column as an arrayref then a hashref
    $sql   = sql("SELECT id, name FROM mytable WHERE price < ?", $price);
    $array = $dbh->selectall_arrayref($sql);
    $hash  = +{ map { $_->[0] => $_->[1] } @$array };
    
    # check a record exists as a scalar
    $sql   = sql("SELECT count(*) FROM mytable WHERE id = ?", $id);
    $exist = $dbh->selectrow_array($sql);
    
    # count total number of records as a scalar
    $sql   = sql("SELECT count(*) FROM mytable WHERE price < ?", $price);
    $count = $dbh->selectrow_array($sql);
    
    # insert a record with a hashref
    $keys  = join(", " => k(keys %$hash));
    $vals  = join(", " => v(values %$hash));
    $sql   = sql("INSERT INTO mytable (???) VALUES (???)", $keys, $vals);
    $dbh->do($sql) or die "insert failed";
    
    # update a record with a hashref
    $sets  = join(", " => sql("?? = ?", %$hash));
    $sql   = sql("UPDATE mytable SET ??? WHERE id = ?", $sets, $id);
    $dbh->do($sql) or die "update failed";
    
    # delete a record
    $sql   = sql("DELETE mytable WHERE id = ?", $id);
    $dbh->do($sql) or die "delete failed";

=head1 AUTHOR

Yusuke Kawasaki http://www.kawa.net/

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2012 Yusuke Kawasaki

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBI> executes SQL statements built by the module.

=cut
