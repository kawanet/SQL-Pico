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

SQL::Pico - Prebinded Raw SQL Statement Builder

=head1 SYNOPSIS

    use SQL::Pico ();
    
    $dbh    = DBI->connect(...);
    $sqlp   = SQL::Pico->new->dbh($dbh);
    $quoted = $sqlp->quote($val);             # $dbh->quote($val)
    $quoted = $sqlp->quote_identifier($key);  # $dbh->quote_identifier($key)

    $select = $sqlp->bind("SELECT * FROM ?? WHERE id = ?", $table, $id);
    
    $where  = join(" AND " => $sqlp->bind("?? = ?", %hash));
    $select = $sqlp->bind("SELECT * FROM mytbl WHERE ???", $where);

    $keys   = join(", " => $sqlp->quote_identifier(keys %hash));
    $vals   = join(", " => $sqlp->quote(values %hash));
    $insert = $sqlp->bind("INSERT INTO mytbl (???) VALUES (???)", $keys, $vals);

    $sets   = join(", " => $sqlp->bind("?? = ?", %hash));
    $update = $sqlp->bind("UPDATE mytbl SET ??? WHERE id = ?", $sets, $id);

    $in     = join(", " => v(@list));
    $delete = $sqlp->bind("DELETE mytbl WHERE id IN (???)", $in);

=head1 DESCRIPTION

This provides a simple but safe way to build SQL statements
without learning any other languages than Perl and SQL.

Most of ORM modules and something SQL::Builder modules would have
required you to understand a complex structure or dialectal DSL.
This module provides just one new method of C<bind()>,
which allows you to build raw SQL statements with placeholders,
as well as C<quote()> and C<quote_identifier()> methods
which are wrappers of L<DBI>'s same methods you already know.

=head1 METHODS

=head2 new(PARAMETERS)

This creates a C<SQL::Pico> instance.

    $sqlp = SQL::Pico->new;

This accepts key/value pair(s) as its initial parameters.
Only C<dbh> parameter is available at this module.

    $sqlp = SQL::Pico->new(dbh => $dbh);

=head2 dbh(DBHANDLE)

This is accessor to specify a C<DBI> instance.

    $sqlp = SQL::Pico->new;
    $sqlp->dbh($dbh);

The setter returns the current C<SQL::Pico> instance for you
to chain method calls.

    $quoted = SQL::Pico->new->dbh($dbh)->quote($val);

The quoting format depends on database systems.
For example, a literal string "Don't" would be quoted as
'Don''t', 'Don\'t', "Don't", etc.
You need to specify a C<DBI> instance to make string quoted propery.

=head2 quote(LITERAL)

This calls C<DBI>'s C<quote()> method internally.

    $quoted = $sqlp->quote($val);             # $dbh->quote($val)

This doesn't accept literal's data type specified at its second argument.
The other difference to original is that this accept multiple arguments
and returns them quoted.

    @list   = $sqlp->quote(@vals);            # multiple quotes at once

=head2 quote_identifier(IDENTIFIER)

This calls C<DBI>'s C<quote_identifier()> method internally.

    $quoted = $sqlp->quote_identifier($key);  # $dbh->quote_identifier($key)

Multiple arguments are allowed as well.

    @list   = $sqlp->quote_identifier(@keys); # multiple quotes at once

=head2 bind(SQL, VALUES...)

This builds a SQL statement by using placeholders with bind values.

    $sql = $sqlp->bind("SELECT * FROM ?? WHERE id = ?", $table, $id);

Note that this returns a SQL statement built with values binded
at the method prior to C<DBI>'s <execute()> method called.

Three types of placeholders are allowed at the first argument:

Single character of C<?> represents a placeholder for a literal
which will be escaped by C<quote()>.

Double characters of C<??> represents a placeholder for an identifier
which will be escaped by C<quote_identifier()>.

Triple characters of C<???> represents a placeholder for a raw SQL
string which will not be escaped.

    $hash   = {"qux" => "foo", "quux" => "bar", "corge" => "baz"};
    @list   = $sqlp->bind("?? = ?", %$hash);
    $where  = join(" AND ", @list);
    $select = "SELECT * FROM mytable WHERE $where";

    # WHERE "qux" = 'foo' AND "quux" = 'bar' AND "corge" = 'baz'
    # Note that the order of key/value pairs varies.

In list context, this returns a list of strings repeatedly binded
with parameters following.
It'd be useful to build C<WHERE>, C<VALUES>, C<SET>, C<IN> clause, etc.

=head1 FUNCTIONS

In addition to the OO style described above, this also supports
the functional style and exports three shortcut functions:
C<v()>, C<k()> and C<sql()> per default.

    use SQL::Pico;                            # functions exported
    
    $quoted = v("string");                    # quotes literal
    $quoted = k("table_name");                # quotes identifier
    $sql    = sql("SELECT * FROM ?? WHERE id = ?", $table, $id);

=head2 v(LITERAL)

This is a shortcut for C<quote()> method
which quotes a literal, e.g. string, number, etc.

    $quoted = v("string");                    # quotes literal
    @quoted = v("foo", "bar", "baz");         # multiple literals

=head2 k(IDENTIFIER)

This is a shortcut for C<quote_identifier()> method
which quotes an identifier, e.g. table name, column name, etc.

    $quoted = k("table_name");                # quotes identifier
    @quoted = k("qux", "quux", "corge");      # multiple identifiers

=head2 sql(SQL, VALUES...)

This is a shortcut for C<bind()> method
which builds a SQL statement by using placeholders with bind values.

    $sql  = sql("SELECT * FROM ?? WHERE id = ?", $table, $id);

=head2 dbh(DBHANDLE)

Use C<dbh()> class method to specify the default database handle
for those C<v()>, C<k()> and C<sql()> functions above.

    $dbh = DBI->connect(...);
    SQL::Pico->dbh($dbh);

Note that C<dbh()> method is not exported.

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

L<SQL::Abstract::Query> provides a list of other SQL generators as reference.

=cut
