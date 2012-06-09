#!perl
use strict;
use warnings;
use Test::More;
use t::Util;
use t::CustomizedTable;
use Kappa;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

subtest 'update', sub {
    my $db_for_test = db_for_test($dbh);
    $db_for_test->insert('TEST', { id => 123, value => 'aaa' });
    $db_for_test->update('TEST', { value => 'bbb' }, { id => 123 });
    my $row = $db_for_test->select('TEST', { id => 123 });
    ok( defined $row );
    is( $row->value, 'bbb');

    $db_for_test->insert({ id => 124, value => 'bbb' });
    $db_for_test->update({ value => 'ccc' }, { id => 124 });
    $row = $db_for_test->select('TEST', { id => 124 });
    ok( defined $row );
    is( $row->value, 'ccc');
};




done_testing;

