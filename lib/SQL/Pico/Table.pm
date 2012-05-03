package SQL::Pico::Table;
use strict;
use warnings;
use base 'SQL::Pico';

our $VERSION = '0.01';

use Carp;
use Scalar::Util;

SQL::Pico::Util::Accessor->import(qw( table primary readable writable condition ));

sub _build_table {
    Carp::croak "table name not defined";
}

sub _build_primary {
    Carp::croak "primary key not defined";
}

sub _build_readable {
    ['*'];
}

sub _build_writable {
    ['*'];
}

sub _build_condition {
    [];
}

sub _arrayref {
    return \@_ if (1 < scalar @_);
    return $_[0] if (scalar @_ && ref $_[0] && Scalar::Util::reftype($_[0]) eq 'ARRAY');
    \@_;
}

sub _where {
    my $self = shift;

    my $const = $self->_where_const;
    return $const unless @_;

    my $hashash = (ref $_[0] && Scalar::Util::reftype($_[0]) eq 'HASH');
    my $primary = $self->_where_primary(shift) if $hashash;

    my $rest = $self->bind(@_) if @_;

    my $where = $const;
    if ($where && $primary) {
        $primary =~ s/^\s*(WHERE\s+)/AND /i;
        $where = "$where $primary";
    } elsif ($primary) {
        $where = $primary;
    }

    if ($where && $rest) {
        $rest =~ s/^\s*(WHERE\s+)/AND /i;
        $where = "$where $rest";
    } elsif ($rest) {
        $where = $rest;
    }

    $where;
}

sub _where_const {
    my $self = shift;
    my $const = _arrayref($self->condition);
    @$const = grep {defined $_ && $_ ne ''} @$const;
    return unless @$const;
    @$const = map {/^[^\(].*\Wor\W.*[^\)]$/is ? "($_)" : $_} @$const;
    my $where = join " AND " => @$const;
    "WHERE $where";
}

sub _where_primary {
    my $self = shift;
    my $cond = shift;

    my $primary = _arrayref($self->primary);
    my $keys    = [grep {exists $cond->{$_}} @$primary];

    if (scalar @$primary != scalar @$keys) {
        my $miss  = [grep {! exists $cond->{$_}} @$primary];
        my $mjoin = join '", "' => @$miss;
        Carp::croak "Primary key \"$mjoin\" not found in the condition";
    }

    my $pair  = [map {$_ => $cond->{$_}} @$keys];
    my $where = join " AND " => $self->bind("?? = ?" => @$pair);
    "WHERE $where";
}

sub _is_star {
    my $column = shift;
    (1 == scalar @$column && $column->[0] eq '*') ? '*' : undef;
}

sub index {
    my $self  = shift;
    my $where = $self->_where(@_);

    my $keys = _arrayref($self->primary);
    my $join = join ", " => $self->quote_identifier(@$keys);

    my $sql = $self->bind("SELECT ??? FROM ??", $join, $self->table);
    $sql .= " $where" if defined $where;
    $sql;
}

sub select {
    my $self  = shift;
    my $where = $self->_where(@_);

    my $column = _arrayref($self->readable);
    my $join   = _is_star($column);
    $join ||= join ", " => $self->quote_identifier(@$column);

    my $sql = $self->bind("SELECT ??? FROM ??", $join, $self->table);
    $sql .= " $where" if defined $where;
    $sql;
}

sub insert {
    my $self = shift;
    my $hash = shift or Carp::croak "No column to be inserted";

    my $column = _arrayref($self->writable);
    $column = [sort keys %$hash] if _is_star($column);

    my $keys  = [grep {exists $hash->{$_}} @$column];
    Carp::croak "INSERT without a column is not allowed" unless @$keys;

    my $vals  = [map {$hash->{$_}} @$keys];
    my $kjoin = join ", " => $self->quote_identifier(@$keys);
    my $vjoin = join ", " => $self->quote(@$vals);

    my $sql = $self->bind("INSERT INTO ?? (???) VALUES (???)", $self->table, $kjoin, $vjoin);
}

sub update {
    my $self  = shift;
    my $hash  = shift or Carp::croak "No column to be updated";
    my $where = $self->_where(@_);
    Carp::croak 'UPDATE without a condition is not allowed' unless defined $where;

    my $column = _arrayref($self->writable);
    $column = [sort keys %$hash] if _is_star($column);

    my $keys = [grep {exists $hash->{$_}} @$column];
    Carp::croak "No column will be updated" unless @$keys;

    my $pair  = [map {$_ => $hash->{$_}} @$keys];
    my $sjoin = join ", " => $self->bind("?? = ?" => @$pair);

    my $sql = $self->bind("UPDATE ?? SET ???", $self->table, $sjoin);
    $sql .= " $where" if defined $where;
    $sql;
}

sub delete {
    my $self  = shift;
    my $where = $self->_where(@_);
    Carp::croak 'DELETE without a condition is not allowed' unless defined $where;

    my $sql = $self->bind("DELETE FROM ??", $self->table);
    $sql .= " $where" if defined $where;
    $sql;
}

sub count {
    my $self  = shift;
    my $where = $self->_where(@_);

    my $sql = $self->bind("SELECT count(*) FROM ??", $self->table);
    $sql .= " $where" if defined $where;
    $sql;
}

1;
__END__
=encoding utf-8

=for stopwords

=head1 NAME

SQL::Pico::Table - Simple SQL Statement Builder

=head1 SYNOPSIS

    use MyTable;

    $mytbl = SQL::Pico::Table->new;
    $mytbl->dbh($dbh);
    $mytbl->table('mytable');
    $mytbl->primary('id');

    $sql  = $mytbl->select({id => 1});
    $hash = $dbh->selectrow_hashref($sql);

    $sql = $mytbl->insert({name => 'foobar'});
    $dbh->do($sql) or die "insert failed";

    $sql = $mytbl->update({name => 'foobar'}, {id => 1});
    $dbh->do($sql) or die "update failed";

    $sql = $mytbl->delete({id => 1});
    $dbh->do($sql) or die "delete failed";

=head1 DESCRIPTION

This is an yet another SQL statement builder for basic CRUD operations.

=head1 PARAMETERS

This has accessor methods for C<dbh>, C<table>, C<primary>, C<readable>,
C<writable> and C<condition> parameters.

C<primary>, C<readable>, C<writable> and C<condition> accessors supports
multiple values represented as an array at both side of getter and setter,
in addition to a single value of scalar as usual, transparently.

=head2 dbh

This specifies L<DBI> instance to call a valid C<quote()> method for each driver.

    $dbh = DBI->connect(...);
    $mytbl->dbh($dbh);

=head2 table

This is required to specify a table name to manipulate.

    $mytbl->table('mytable');

=head2 primary

This is required to specify primary key(s) of the table.

    $mytbl->primary('id');

C<primary> accepts multiple primary keys as well.

    $mytbl->primary('category', 'name');

=head2 readable

This specifies readable columns which will returned by C<SELECT> statement.

    $mytbl->readable(qw( id category name price ));

Note that all parameters must be column name.
SQL functions and alias name like C<count(*) AS counts> are not allowed.
Use C<CREATE VIEW> or construct a statement by hand in those cases.

Default value is C<'*'> which means all columns are readable.

=head2 writable

This specifies writable columns which are allowed for C<INSERT> and
C<UPDATE> statements to set values.

    $mytbl->writable(qw( category name price ));

Default value is C<'*'> which means all columns are writable.

=head2 condition

This specifies a static condition which is always applied at C<WHERE> clause.

    $mytbl->condition('deleted = 0');

Default value is an empty which means no static condition is applied.

=head1 METHODS

This module provides four methods to build a SQL statement for basic CRUD
operations and C<index()> and C<count()> methods for your convenience.
Literals and identifiers are properly quoted.

At the sample codes below, parameters are initialized as following.

    $mytbl = SQL::Pico::Table->new;
    $mytbl->table('mytable');
    $mytbl->primary('id');
    $mytbl->readable(qw( name price ));
    $mytbl->writable(qw( name price ));

=head2 select(CONDITION, CLAUSE...)

This builds a C<SELECT> statement which reads record(s) from database.

    # SELECT name, price FROM mytable WHERE id = '1'
    $sql  = $mytbl->select({id => 1}); 
    $hash = $dbh->selectrow_hashref($sql);

This builds a C<SELECT> statement which returns a record
specified by primary keys given as a hashref.
C<WHERE> clause is built by using only primary keys
which are specified by C<primary()> accessor in advance.
Any other keys than C<primary> keys in given hashref are ignored.

Please note that a hashref is used to build a condition using
primary key but is not to build a generic condition.
A hashref is not pretty enough to build a complex condition you need.
Don't use Perl for it and use SQL to build a full condition instead.

The first hashref argument is optional.
This also accept a C<WHERE> clause which supports bind values.

    # SELECT * FROM mytable WHERE price < '100'
    $sql = $mytbl->select("WHERE price < ?", "100");
    $hasharray = $dbh->selectall_arrayref($sql, {Slice=>{}});

C<ORDER BY> clause and and some other clauses are allowed as well.

    # SELECT name, price FROM mytable ORDER BY price DESC
    $sql  = $mytbl->select("ORDER BY price DESC");
    $hasharray = $dbh->selectall_arrayref($sql, {Slice=>{}});

Without a condition nor clauses applied,
this builds a C<SELECT> statement which returns all records.

    # SELECT name, price FROM mytable
    $sql       = $mytbl->select;
    $hasharray = $dbh->selectall_arrayref($sql, {Slice=>{}});

=head2 insert(KEYVAL)

This builds an C<INSERT> statement which creates a record.

    # INSERT INTO mytable ( name, price ) VALUES ( 'corge', '100' )
    $sql = $mytbl->insert({name => 'corge', price => '100'});
    $dbh->do($sql) or die "insert failed";

The first argument is a required hashref which contains C<writable> keys.
Any other keys than C<writable> keys in given hashref are ignored.

=head2 update(KEYVAL, CONDITION, CLAUSE...)

This builds an C<UPDATE> statement which updates record(s).

    # UPDATE mytable SET name = 'corge', price = '100' WHERE id = '1'
    $sql = $mytbl->update({name => 'corge', price => '100'}, {id => 1});
    $dbh->do($sql) or die "update failed";

The first argument is a required hashref which contains C<writable> keys.
Any other keys than C<writable> keys in given hashref are ignored.

The second argument is an optional hashref which contains C<primary> keys.
Any other keys than C<primary> keys in given hashref are ignored.

This also accepts more arguments of C<WHERE> clause which supports bind values.
This allows you to build more complex conditions.

    # UPDATE mytable SET name = 'corge' WHERE price < '100'
    $sql = $mytbl->update({name => 'corge'}, "WHERE price < ?", "100");
    $dbh->do($sql) or die "update failed";

=head2 delete(CONDITION, CLAUSE...)

This builds a C<DELETE> statement which deletes record(s).

    # DELETE FROM mytable WHERE id = '1'
    $sql = $mytbl->delete({id => 1});
    $dbh->do($sql) or die "delete failed";

The argument is a optional hashref which contains C<primary> keys.
Any other keys than C<primary> keys in given hashref are ignored.

This also accepts more arguments of C<WHERE> clause which supports bind values.
This allows you to build more complex conditions.

    # DELETE FROM mytable WHERE price < '100'
    $sql = $mytbl->delete("WHERE price < ?", "100");
    $dbh->do($sql) or die "delete failed";

=head2 index(CONDITION, CLAUSE...)

This builds a C<SELECT> statement which returns only primary keys
of each records.

    # SELECT id FROM mytable WHERE price < '100'
    $sql = $mytbl->index("WHERE price < ?", "100");
    $arrayref = $dbh->selectcol_arrayref($sql);

This accepts C<WHERE> and some other clause which supports bind values.

    # SELECT id FROM mytable ORDER BY price DESC
    $sql = $mytbl->index("ORDER BY price DESC");
    $arrayref = $dbh->selectcol_arrayref($sql);

Without a clause applied,
this builds a C<SELECT> statement which returns all primary keys on the table.

    # SELECT id FROM mytable
    $sql      = $mytbl->index;
    $arrayref = $dbh->selectcol_arrayref($sql);

=head2 count(CONDITION, CLAUSE...)

This builds a C<SELECT> statement which returns number of records.
This is available to test whether a specified record exists or not.

    # SELECT count(*) FROM mytable WHERE id = '1'
    $sql   = $mytbl->count({id => 1});
    $exist = $dbh->selectrow_array($sql);

The first argument is an optional hashref which contains C<primary> keys.
Any other keys than C<primary> keys in given hashref are ignored.

This also accepts more arguments of C<WHERE> clause which supports bind values.
This allows you to build more complex conditions.

    # SELECT count(*) FROM mytable WHERE price < '100'
    $sql = $mytbl->count("WHERE price < ?", "100");
    $total = $dbh->selectrow_array($sql);

Without a condition nor clauses applied,
this builds a C<SELECT> statement which returns the total number of records.

    # SELECT count(*) FROM mytable
    $sql   = $mytbl->count;
    $total = $dbh->selectrow_array($sql);

=head2 quote(LITERAL)

This is inherited from L<SQL::Pico> module.

=head2 quote_identifier(IDENTIFIER)

This is inherited from L<SQL::Pico> module.

=head2 bind(CLAUSE, VALUES...)

This is inherited from L<SQL::Pico> module.

=head1 SUBCLASSING

C<SQL::Pico::Table> can be subclassed to specify default value for
parameters.

    package MyTable;
    use base 'SQL::Pico::Table';

    sub _build_table { 'mytable' }
    sub _build_primary { 'id' }
    sub _build_readable {qw( id category name price )}
    sub _build_writable {qw( category name price )}
    sub _build_condition { 'deleted = 0' }

    package main;
    
    $mytbl = MyTable->new;
    $sql   = $mytbl->select({id => 1});
    $hash  = $dbh->selectrow_hashref($sql);

You need to provide a couple of methods C<_build_table()> and
C<_build_primary()> to provide those default values at least.
Those methods will be called to set initial values on demand
like L<Moose>'s C<lazy_build> optoin does.

C<_build_readable()>, C<_build_writable()> and C<_build_condition()>
methods are available as well.

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

L<SQL::Pico> is the parent class of this.

L<SQL::Abstract::Query> provides a list of other SQL generators as reference.

=cut
