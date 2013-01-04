#!perl
use strict;
use warnings;
use Test::More;
use t::Util;
use t::CustomizedTable;
use Kappa;


my $condition = { value => 'aaa' };
my $option = { order_by => 'id' };

subtest 'select_row', sub {
    my ($dsn, $user, $pass, $opt) =  args_for_connect();
    my $db = Kappa->connect($dsn, $user, $pass, $opt, {
        table_namespace => 'CustomizedTable',
    });
    prepare_table($db->handler->dbh);
    prepare_testdata($db->handler->dbh);
    my $db_for_test = $db->model('TEST');
    my $row = $db_for_test->select_row($condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');

    $row = $db_for_test->select_row('TEST', $condition, $option);
    ok( defined $row );
    is( $row->value, 'aaa');
};



done_testing;

