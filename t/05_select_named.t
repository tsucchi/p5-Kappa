#!perl
use strict;
use warnings;
use Test::More;
use t::Util;

use Kappa;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

my $sql = "SELECT * FROM TEST WHERE value = :value ORDER BY id";
my $condition = { value => 'aaa' };

{
    package CustomizedTable;
    our @ISA = qw(Kappa);
    sub xxx { return 'xxx' }
}

{
    package CustomizedTable::TEST;
    our @ISA = qw(CustomizedTable);
    sub yyy { return 'yyy' }
}

subtest 'select_named', sub {
    my $db_for_test = db_for_test();
    is( $db_for_test->table_name, 'TEST');
    my $row = $db_for_test->select_named($sql, $condition);
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

subtest 'select_row_named', sub {
    my $db_for_test = db_for_test();
    is( $db_for_test->table_name, 'TEST');
    my $row = $db_for_test->select_row_named($sql, $condition);
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

subtest 'select_row_all_named', sub {
    my $db_for_test = db_for_test();
    is( $db_for_test->table_name, 'TEST');
    my @rows = $db_for_test->select_all_named($sql, $condition);
    ok( @rows );
    is( $rows[0]->value, 'aaa');
    is( $rows[0]->table_name, 'TEST');
};

subtest 'select_itr_named', sub {
    my $db_for_test = db_for_test();
    is( $db_for_test->table_name, 'TEST');
    my $itr = $db_for_test->select_itr_named($sql, $condition);
    my $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

done_testing;

sub db_for_test {
    my $db = Kappa->new($dbh, {
        table_namespace => 'CustomizedTable',
    });
    return $db->create('TEST');
}
