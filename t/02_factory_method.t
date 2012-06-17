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

subtest 'default instance', sub {
    my $db = Kappa->new($dbh);
    my $db_for_aaa = $db->model('AAA');
    is( ref $db_for_aaa, 'Kappa');
    is( $db_for_aaa->table_name, undef);
};

subtest 'specify table class namespace(using model method)', sub {
    my $db = Kappa->new($dbh, {
        table_namespace => 'CustomizedTable',
    });
    my $db_for_aaa = $db->model('AAA');
    is( ref $db_for_aaa, 'CustomizedTable');
    is( $db_for_aaa->table_name, undef);

    my $db_for_test = $db->model('TEST');
    is( ref $db_for_test, 'CustomizedTable::TEST');
    is( $db_for_test->table_name, 'TEST');
};

done_testing;
