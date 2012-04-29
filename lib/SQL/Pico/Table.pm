package SQL::Pico::Table;
use strict;
use warnings;
use base 'SQL::Pico';

our $VERSION = '0.01';

use Carp;
use Scalar::Util;

sub table {
    my $self = shift;
    return $self->{table} = shift if @_;
    $self->{table} ||= $self->_build_table;
}

sub primary {
    my $self = shift;
    $self->{primary} = _arrayref(@_) if @_;
    my $array = $self->{primary} ||= _arrayref($self->_build_primary);
    wantarray ? @$array : $array->[0] if ref $array;
}

sub readable {
    my $self = shift;
    $self->{readable} = _arrayref(@_) if @_;
    my $array = $self->{readable} ||= _arrayref($self->_build_readable);
    wantarray ? @$array : $array->[0] if ref $array;
}

sub writable {
    my $self = shift;
    $self->{writable} = _arrayref(@_) if @_;
    my $array = $self->{writable} ||= _arrayref($self->_build_writable);
    wantarray ? @$array : $array->[0] if ref $array;
}

sub condition {
    my $self = shift;
    $self->{condition} = _arrayref(@_) if @_;
    my $array = $self->{condition} ||= _arrayref($self->_build_condition);
    wantarray ? @$array : $array->[0] if ref $array;
}

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

    # constant (soft) condition
    if (! @_) {
        my $const = $self->_where_const or return;
        my $where = join " AND " => @$const;
        return "WHERE $where";
    }

    my $arg = shift;
    if (! @_ && ref $arg && Scalar::Util::reftype($arg) eq 'HASH') {
        return $self->_where_primary($arg);
    } else {
        return $self->_where_sql($arg, @_);
    }
}

sub _where_const {
    my $self = shift;
    my $const = _arrayref($self->condition);
    @$const = grep {defined $_ && $_ ne ''} @$const;
    return unless @$const;
    @$const = map {/\Wor\W/i ? "($_)" : $_} @$const;
    $const;
}

sub _where_primary {
    my $self = shift;
    my $cond = shift;
    my $primary = _arrayref($self->primary);
    my $list = [];

    # constant (soft) condition
    my $const = $self->_where_const;
    push(@$list, @$const) if ref $const;

    # dinamyc (primary key) condition
    foreach my $key (@$primary) {
        Carp::croak "Primary key \"$key\" not found in the condition" unless exists $cond->{$key};
        my $qkey = $self->quote_identifier($key);
        my $qcon = $self->bind("$qkey = ?" => $cond->{$key});
        push(@$list, $qcon);
    }

    my $where = join " AND " => @$list;
    "WHERE $where";
}

sub _where_sql {
    my $self  = shift;
    my $state = $self->bind(@_) if @_;

    # constant (soft) condition
    my $const = $self->_where_const;
    return $state unless ref $const;

    my $where = join " AND " => @$const;
    return "WHERE $where" unless defined $state;

    $state =~ s/^\s*(WHERE\s+)/AND /i;
    "WHERE $where $state";
}

sub _is_star {
    my $column = shift;
    (1 == scalar @$column && $column->[0] eq '*') ? '*' : undef;
}

sub index {
    my $self  = shift;
    my $where = $self->_where(@_);

    my $primary  = _arrayref($self->primary);
    my $pjoin = join ", " => $self->quote_identifier(@$primary);

    my $table = $self->quote_identifier($self->table);
    my $sql   = "SELECT $pjoin FROM $table";
    $sql .= " $where" if defined $where;
    $sql;
}

sub select {
    my $self  = shift;
    my $where = $self->_where(@_);

    my $column = _arrayref($self->readable);
    my $cjoin  = _is_star($column);
    $cjoin ||= join ", " => $self->quote_identifier(@$column);

    my $table = $self->quote_identifier($self->table);
    my $sql   = "SELECT $cjoin FROM $table";
    $sql .= " $where" if defined $where;
    $sql;
}

sub insert {
    my $self = shift;
    my $hash = shift or Carp::croak "No column to be inserted";

    my $column = _arrayref($self->writable);
    $column = [sort keys %$hash] if _is_star($column);

    my $keys  = [grep {exists $hash->{$_}} @$column];
    my $vals  = [map {$hash->{$_}} @$keys];

    Carp::croak "INSERT without a column is not allowed" unless @$keys;

    my $kjoin = join ", " => $self->quote_identifier(@$keys);
    my $vjoin = join ", " => $self->quote(@$vals);

    my $table = $self->quote_identifier($self->table);
    my $sql   = "INSERT INTO $table ($kjoin) VALUES ($vjoin)";
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

    # my $sets  = [map {$self->bind("?? = ?" => $_, $hash->{$_})} @$keys];
    # my $sjoin = join ", " => @$sets;

    my $vals  = [map {$hash->{$_}} @$keys];
    my %pairs;
    @pairs{@$keys} = @$vals;
    my $sjoin = join ", " => $self->bind("?? = ?" => %pairs);

    my $table = $self->quote_identifier($self->table);
    my $sql   = "UPDATE $table SET $sjoin $where";
}

sub delete {
    my $self  = shift;
    my $where = $self->_where(@_);
    Carp::croak 'DELETE without a condition is not allowed' unless defined $where;

    my $table = $self->quote_identifier($self->table);
    my $sql   = "DELETE FROM $table $where";
}

sub count {
    my $self = shift;
    my $where = $self->_where(@_);

    my $table = $self->quote_identifier($self->table);
    my $sql   = "SELECT count(*) FROM $table";
    $sql .= " $where" if $where;
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

This specifies a table name to manipulate.

    $mytbl->table('mytable');

=head2 primary

This specifies primary key(s) of the table.

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

This specifies a static condition which is always applied at C<WHERE> statement.

    $mytbl->condition('deleted = 0');

Default value is null which means no static condition is applied.

=head1 METHODS

This module provides four methods to build a SQL statement for basic CRUD
operations and C<index()> and C<count()> methods for your convenience.
Literals and identifiers are propery quoted.

At the sample codes below, parameters are initialized as following.

    $mytbl = SQL::Pico::Table->new;
    $mytbl->table('mytable');
    $mytbl->primary('id');
    $mytbl->readable(qw( name price ));
    $mytbl->writable(qw( name price ));

=head2 select(CONDITION)

This builds a C<SELECT> statement which reads record(s) from database.

    # SELECT name, price FROM mytable WHERE id = '1'
    $sql  = $mytbl->select({id => 1}); 
    $hash = $dbh->selectrow_hashref($sql);

This builds a C<SELECT> statement which returns a record
specified by primary keys.
Only primary keys in given hashref are used as a condition.
Primary keys must be specified by C<primary()> accessor in advance.
Please note that this style is not a generic condition builder.
Any other keys than C<primary> keys in given hashref are ignored.

    # SELECT name, price FROM mytable
    $sql       = $mytbl->select;
    $hasharray = $dbh->selectall_arrayref($sql, {Slice=>{}});

Without a condition applied, this builds a C<SELECT> statement
which returns all records.

=head2 insert(KEYVAL)

This builds an C<INSERT> statement which creates a record.

    # INSERT INTO mytable ( name, price ) VALUES ( 'corge', '100' )
    $sql = $mytbl->insert({name => 'corge', price => '100'});
    $dbh->do($sql) or die "insert failed";

The argument is a hashref which contains C<writable> keys.
Any other keys than C<writable> keys in given hashref are ignored.

=head2 update(KEYVAL, CONDITION)

This builds an C<UPDATE> statement which updates record(s).

    # UPDATE mytable SET name = 'corge', price = '100' WHERE id = '1'
    $sql = $mytbl->update({name => 'corge', price => '100'}, {id => 1});
    $dbh->do($sql) or die "update failed";

The first argument is a hashref which contains C<writable> keys.
Any other keys than C<writable> keys in given hashref are ignored.

The second argument is a hashref which contains C<primary> keys.
Any other keys than C<primary> keys in given hashref are ignored.

=head2 delete(CONDITION)

This builds a C<DELETE> statement which deletes record(s).

    # DELETE FROM mytable WHERE id = '1'
    $sql = $mytbl->delete({id => 1});
    $dbh->do($sql) or die "delete failed";

The argument is a hashref which contains C<primary> keys.
Any other keys than C<primary> keys in given hashref are ignored.

=head2 index(CONDITION)

This builds a C<SELECT> statement which returns only primary keys
of each records.

    # SELECT id FROM mytable
    $sql      = $mytbl->index;
    $arrayref = $dbh->selectcol_arrayref($sql);

Without a condition applied, this builds a C<SELECT> statement
which returns all primary keys on the table.

=head2 count(CONDITION)

This builds a C<SELECT> statement which returns number of records.

    # SELECT count(*) FROM mytable WHERE id = '1'
    $sql   = $mytbl->count({id => 1});
    $exist = $dbh->selectrow_array($sql);

This is available to test whether a specified record exists or not.
The argument is a hashref which contains C<primary> keys.
Any other keys than C<primary> keys in given hashref are ignored.

    # SELECT count(*) FROM mytable
    $sql   = $mytbl->count;
    $total = $dbh->selectrow_array($sql);

Without a condition applied, this builds a C<SELECT> statement
which returns the total number of records.

=head2 Direct Condition

C<select>, C<update>, C<delete>, C<index> and C<count> methods also
allow a string of C<WHERE> clause as their condition argument.
This uses C<bind> method internally to accept placeholders and bind values.

    # SELECT * FROM mytable WHERE price < '100'
    $sql = $mytbl->select("WHERE price < ?", "100");
    $hasharray = $dbh->selectall_arrayref($sql, {Slice=>{}});

    # UPDATE mytable SET name = 'corge' WHERE price < '100'
    $sql = $mytbl->update({name => 'corge'}, "WHERE price < ?", "100");
    $dbh->do($sql) or die "update failed";

    # DELETE FROM mytable WHERE price < '100'
    $sql = $mytbl->delete("WHERE price < ?", "100");
    $dbh->do($sql) or die "delete failed";

    # SELECT id FROM mytable WHERE price < '100'
    $sql = $mytbl->index("WHERE price < ?", "100");
    $arrayref = $dbh->selectcol_arrayref($sql);

    # SELECT count(*) FROM mytable WHERE price < '100'
    $sql = $mytbl->count("WHERE price < ?", "100");
    $total = $dbh->selectrow_array($sql);

=head2 Methods Inherited

C<quote>, C<quote_identifier> and C<bind> methods are also available
as this module inherites L<SQL::Pico> module.

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
Those methods will be called to set initial values on demand.

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

=cut
