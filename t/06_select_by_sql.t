#!perl
use strict;
use warnings;
use Test::More;
use t::Util;
use t::CustomizedTable;
use Kappa;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

my $sql = "SELECT * FROM TEST WHERE value = ? ORDER BY id";
my $param = ['aaa'];

subtest 'select_by_sql', sub {
    my $db_for_test = db_for_test($dbh);
    is( $db_for_test->table_name, 'TEST');
    my $row = $db_for_test->select_by_sql($sql, $param);
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

subtest 'select_row_by_sql', sub {
    my $db_for_test = db_for_test($dbh);
    is( $db_for_test->table_name, 'TEST');
    my $row = $db_for_test->select_row_by_sql($sql, $param);
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

subtest 'select_all_by_sql', sub {
    my $db_for_test = db_for_test($dbh);
    is( $db_for_test->table_name, 'TEST');
    my @rows = $db_for_test->select_all_by_sql($sql, $param);
    ok( @rows );
    is( $rows[0]->value, 'aaa');
    is( $rows[0]->table_name, 'TEST');
};

subtest 'select_itr_by_sql', sub {
    my $db_for_test = db_for_test($dbh);
    is( $db_for_test->table_name, 'TEST');
    my $itr = $db_for_test->select_itr_by_sql($sql, $param);
    my $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

done_testing;
