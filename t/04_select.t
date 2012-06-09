#!perl
use strict;
use warnings;
use Test::More;
use t::Util;

use Kappa;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

my $condition = { value => 'aaa' };
my $option = { order_by => 'id' };

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

subtest 'select', sub {
    my $db_for_test = db_for_test();
    my $row = $db_for_test->select($condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');

    $row = $db_for_test->select('TEST', $condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');
};

subtest 'select_row', sub {
    my $db_for_test = db_for_test();
    my $row = $db_for_test->select_row($condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');

    $row = $db_for_test->select_row('TEST', $condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');
};

subtest 'select_all', sub {
    my $db_for_test = db_for_test();
    my @rows = $db_for_test->select_all($condition, $option);
    ok( @rows );
    is( $rows[0]->value, 'aaa');

    @rows = $db_for_test->select_all('TEST', $condition, $option);
    ok( @rows );
    is( $rows[0]->value, 'aaa');
};

subtest 'select_itr', sub {
    my $db_for_test = db_for_test();
    my $itr = $db_for_test->select_itr($condition, $option);
    my $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');

    $itr = $db_for_test->select_itr('TEST', $condition, $option);
    $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');
};


done_testing;

sub db_for_test {
    my $db = Kappa->new($dbh, {
        table_namespace => 'CustomizedTable',
    });
    return $db->create('TEST');
}
