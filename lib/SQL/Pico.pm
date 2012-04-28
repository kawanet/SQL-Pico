package SQL::Pico;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '1.0';
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
    $self = $self->instance unless ref $self;
    my $dbh   = $self->dbh;
    my $param = @_;
    my $count = ($sql =~ s{(\?+)}{
        $1 eq '?' ? $dbh->quote(shift) :
        $1 eq '??' ? $dbh->quote_identifier(shift) :
        Carp::croak "Invalid placeholder: '$1'";
    }ge);
    Carp::croak "Place holder mismatch: holder=$count param=$param" if ($count != $param);
    $sql;
}

1;
__END__
=encoding utf-8

=head1 NAME

SQL::Pico - A wrapper for DBI's quote and quote_identifier methods

=head1 SYNOPSIS

OO style:
    
    use SQL::Pico ();                         # nothing exported

    $dbh    = DBI->connect(...);
    $pico   = SQL::Pico->new->dbh($dbh);

    $quoted = $pico->quote($val);             # $dbh->quote($val)
    $quoted = $pico->quote_identifier($key);  # $dbh->quote_identifier($key)
    $sql    = $pico->bind("SELECT * FROM ?? WHERE id = ?", $table, $id);

    @list   = $pico->quote(@vals);            # multiple quotes at once
    @list   = $pico->quote_identifier(@keys); # ditto.

Functional style:

    use SQL::Pico;                            # methods exported
    
    $quoted = v("string");                    # quotes literal
    $quoted = k("table_name");                # quotes identifier
    $sql    = sql("SELECT * FROM ?? WHERE id = ?", $table, $id);

=head1 DESCRIPTION

This is a simple wrapper for L<DBI>'s C<quote()> and C<quote_identifier()>
methods with some useful features.

=head1 METHODS

=head2 new(PARAMETERS)

This returns a C<SQL::Pico> instance.

    $pico = SQL::Pico->new;

This accepts key/value pair(s) as its initial parameters.
Only C<dbh> parameter is available at this module.

    $pico = SQL::Pico->new(dbh => $dbh);

=head2 dbh(DBHANDLE)

This is accessor to specify L<DBI> instance.

    $pico = SQL::Pico->new;
    $pico->dbh($dbh);

The setter returns the current C<SQL::Pico> instance for you
to chain method calls.

    $quoted = SQL::Pico->new->dbh($dbh)->quote($val);

=head2 quote(LITERAL)

This calls L<DBI>'s C<quote()> method internally.

    $quoted = $pico->quote($val);             # $dbh->quote($val)
    @list   = $pico->quote(@vals);            # multiple quotes at once

This doesn't accept literal's data type specified at its second argument.
The other difference to original is that this accept multiple arguments
and returns them quoted.

=head2 quote_identifier(IDENTIFIER)

This calls L<DBI>'s C<quote_identifier()> method internally.

    $quoted = $pico->quote_identifier($key);  # $dbh->quote_identifier($key)
    @list   = $pico->quote_identifier(@keys); # multiple quotes at once

Multiple arguments are allowed as well.

=head2 bind(SQL, VALUES...)

This builds a SQL statement by using placeholders with bind values

    $sql = $pico->bind("SELECT * FROM ?? WHERE id = ?", $table, $id);

Note that this returns a SQL statement built with values binded
at the method prior to L<DBI>'s <execute()> method called.

Single C<?> string represents a placeholder for a literal.
As this module's additional feature,
C<??> string represents a placeholder for an identifier,
on the other hand.

=head1 FUNCTIONS

In addition to the OO style described above, this also supports
the functional style and exports three shortcut functions:
C<v()>, C<k()> and C<sql()> per default.

=head2 v(LITERAL)

This is a shortcut for C<quote()> method
which quotes a literal, e.g. string, number, etc.

    $quoted = v("string");                    # quotes literal

=head2 k(IDENTIFIER)

This is a shortcut for C<quote_identifier()> method
which quotes an identifier, e.g. table name, column name, etc.

    $quoted = k("table_name");                # quotes identifier

=head2 sql(SQL, VALUES...)

This is a shortcut for C<bind()> method
which builds a SQL statement by using placeholders with bind values.

    $sql = sql("SELECT * FROM ?? WHERE id = ?", $table, $id);

=head2 Database Handle

The escaping style varies.
For example, a literal string C<Don't> would be quoted as
C<'Don''t'>, C<'Don\'t'>, C<"Don't">, etc. It depends on database systems.
Use C<dbh()> method to specify database handle which will be used to call C<quote()>.

    $dbh = DBI->connect(...);
    SQL::Pico->dbh($dbh);

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
