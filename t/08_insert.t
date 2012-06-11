#!perl
use strict;
use warnings;
use Test::More;
use t::Util;
use t::CustomizedTable;
use Kappa;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

subtest 'insert (normal)', sub {
    my $db = Kappa->new($dbh);
    $db->insert('TEST', { id => 121, value => 'aaa' });
    my $row = $db->select('TEST', { id => 121 });
    ok( defined $row );
    is( $row->value, 'aaa');
};

subtest 'insert_multi (normal)', sub {
    my $db = Kappa->new($dbh);
    $db->insert_multi('TEST', [{ id => 122, value => 'bbb' }]);
    my $row = $db->select('TEST', { id => 122 });
    ok( defined $row );
    is( $row->value, 'bbb');
};

subtest 'insert using table class', sub {
    my $db_for_test = db_for_test($dbh);
    $db_for_test->insert('TEST', { id => 123, value => 'aaa' });
    my $row = $db_for_test->select('TEST', { id => 123 });
    ok( defined $row );
    is( $row->value, 'aaa');

    $db_for_test->insert({ id => 124, value => 'bbb' });
    $row = $db_for_test->select('TEST', { id => 124 });
    ok( defined $row );
    is( $row->value, 'bbb');
};

subtest 'insert_multi', sub {
    my $db_for_test = db_for_test($dbh);
    $db_for_test->insert_multi('TEST', [{ id => 125, value => 'aaa' }]);
    my $row = $db_for_test->select('TEST', { id => 125 });
    ok( defined $row );
    is( $row->value, 'aaa');

    $db_for_test->insert_multi([{ id => 126, value => 'bbb' }]);
    $row = $db_for_test->select('TEST', ({ id => 126 }));
    ok( defined $row );
    is( $row->value, 'bbb');
};



done_testing;

