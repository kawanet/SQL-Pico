use strict;
use Test::More tests => 27;

use_ok 'SQL::Pico';

MyClass->SQL::Pico::Util::Accessor::mk_accessors(qw( foo bar buz ));

test1();
test2();
test3();
test4();
test5();

sub test1 {
  my $o = MyClass->new();
  my($t, @t);

  my $scalar = 'buz';
  my @array  = qw(quux corge);
  my $aref   = [qw(grault garply)];
  my $href   = {waldo => 'fred'};

  $o->foo($scalar);
  $t = $o->foo;
  is($t, $scalar, 'in:scalar out:scalar');

  @t = $o->foo;
  is_deeply(\@t, [$scalar], 'in:scalar out:array');

  $o->foo(@array);
  $t = $o->foo;
  is($t, $array[0], 'in:array out:scalar');

  @t = $o->foo;
  is_deeply(\@t, \@array, 'in:array out:array');

  $o->foo($aref);
  $t = $o->foo;
  is_deeply($t, $aref, 'in:arrayref out:scalar');

  @t = $o->foo;
  is_deeply(\@t, [$aref], 'in:arrayref out:array');

  $o->foo($href);
  $t = $o->foo;
  is_deeply($t, $href, 'in:hashref out:scalar');

  @t = $o->foo;
  is_deeply(\@t, [$href], 'in:hashref out:array');
}

sub test2 {
  my $o = MyClass->new();
  my($t, @t);

  $o->foo('thud');
  $o->bar('plugh');
  $o->buz('xyzzy');

  $t = $o->foo;
  is($t, 'thud', 'in:scalar out:scalar (foo)');

  $t = $o->bar;
  is($t, 'plugh', 'in:scalar out:scalar (bar)');

  $t = $o->buz;
  is($t, 'xyzzy', 'in:scalar out:scalar (buz)');
}

sub test3 {
  my $o = MyClass->new(foo => 'thud', bar => 'plugh', buz => 'xyzzy');
  my($t, @t);

  $t = $o->foo;
  is($t, 'thud', 'default:scalar out:scalar (foo)');

  $t = $o->bar;
  is($t, 'plugh', 'default:scalar out:scalar (bar)');

  $t = $o->buz;
  is($t, 'xyzzy', 'default:scalar out:scalar (buz)');
}

sub test4 {
  my $o = MyClass->new;
  my($t, @t);

  $t = $o->foo;
  is($t, 'foofoo', 'build:scalar out:scalar');

  @t = $o->foo;
  is_deeply(\@t, ['foofoo'], 'build:scalar out:array');

  $t = $o->bar;
  is($t, 'barbar', 'build:array out:scalar');

  @t = $o->bar;
  is_deeply(\@t, ['barbar', 'rabrab'], 'build:array out:array');

  $t = $o->buz;
  is_deeply($t, ['buzbuz', 'zubzub'], 'build:arrayref out:scalar');

  @t = $o->buz;
  is_deeply(\@t, [['buzbuz', 'zubzub']], 'build:arrayref out:array');
}

sub test5 {
  my $str = 'qux';
  my $o = MyClass->new( foo => [1, 2, 3], bar => {key => 'val'}, buz => \$str);
  my($t, @t);

  $t = $o->foo;
  is($t, 1, 'default:arrayref out:scalar');

  @t = $o->foo;
  is_deeply(\@t, [1, 2, 3], 'default:arrayref out:array');

  $t = $o->bar;
  is_deeply($t, {key => 'val'}, 'default:hashref out:scalar');

  @t = $o->bar;
  is_deeply(\@t, [{key => 'val'}], 'default:arrayref out:array');

  $t = $o->buz;
  is_deeply($t, \$str, 'default:scalarref out:scalar');

  @t = $o->buz;
  is_deeply(\@t, [\$str], 'default:scalarref out:array');
}

package MyClass;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub _build_foo { 'foofoo' }

sub _build_bar { 'barbar', 'rabrab' }

sub _build_buz {['buzbuz', 'zubzub']}
