#!perl
use strict;
use warnings;
use Test::More;
use t::Util;
use t::CustomizedTable;
use Kappa;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

my $condition = { value => 'aaa' };
my $option = { order_by => 'id' };
my $fields = ['id', 'value'];

subtest 'select', sub {
    my $db_for_test = db_for_test($dbh);
    my $row = $db_for_test->select_with_fields($fields, $condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');

    $row = $db_for_test->select_with_fields('TEST', $fields, $condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');
};

subtest 'select_row', sub {
    my $db_for_test = db_for_test($dbh);
    my $row = $db_for_test->select_row_with_fields($fields, $condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');

    $row = $db_for_test->select_row_with_fields('TEST', $fields, $condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');
};

subtest 'select_all', sub {
    my $db_for_test = db_for_test($dbh);
    my @rows = $db_for_test->select_all_with_fields($fields, $condition, $option);
    ok( @rows );
    is( $rows[0]->value, 'aaa');

    @rows = $db_for_test->select_all_with_fields('TEST', $fields, $condition, $option);
    ok( @rows );
    is( $rows[0]->value, 'aaa');
};

subtest 'select_itr', sub {
    my $db_for_test = db_for_test($dbh);
    my $itr = $db_for_test->select_itr_with_fields($fields, $condition, $option);
    my $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');

    $itr = $db_for_test->select_itr_with_fields('TEST', $fields, $condition, $option);
    $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');
};


done_testing;

