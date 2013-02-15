#!perl
use strict;
use warnings;
use Test::More;
use t::Util;
use t::CustomizedTable;
use Kappa;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

my $sql = "SELECT * FROM TEST WHERE value = :value ORDER BY id";
my $condition = { value => 'aaa' };

subtest 'select_named', sub {
    my $db_for_test = db_for_test($dbh);
    is( $db_for_test->table_name, 'TEST');
    my $row = $db_for_test->select_named($sql, $condition);
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

subtest 'select_named with row class', sub {
    my $db = Kappa->new($dbh, { row_namespace => 'CustomizedRow' });
    is( $db->table_name, undef);
    my $row = $db->select_named($sql, $condition);
    ok( defined $row );
    is( $row->value, 'aaa');
};


subtest 'select_row_named', sub {
    my $db_for_test = db_for_test($dbh);
    is( $db_for_test->table_name, 'TEST');
    my $row = $db_for_test->select_row_named($sql, $condition);
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

subtest 'select_all_named', sub {
    my $db_for_test = db_for_test($dbh);
    is( $db_for_test->table_name, 'TEST');
    my @rows = $db_for_test->select_all_named($sql, $condition);
    ok( @rows );
    is( $rows[0]->value, 'aaa');
    is( $rows[0]->table_name, 'TEST');
};

subtest 'select_itr_named', sub {
    my $db_for_test = db_for_test($dbh);
    is( $db_for_test->table_name, 'TEST');
    my $itr = $db_for_test->select_itr_named($sql, $condition);
    my $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

done_testing;

