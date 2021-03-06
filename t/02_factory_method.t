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
    is( $db_for_aaa->table_name, 'AAA');
};

subtest 'specify table class namespace(using model method)', sub {
    my $db = Kappa->new($dbh, {
        table_namespace => 'CustomizedTable',
    });
    my $db_for_aaa = $db->model('AAA');
    is( ref $db_for_aaa, 'CustomizedTable');
    is( $db_for_aaa->table_name, 'AAA');

    my $db_for_test = $db->model('TEST');
    is( ref $db_for_test, 'CustomizedTable::TEST');
    is( $db_for_test->table_name, 'TEST');
};

subtest 'default model for customized $db', sub {
    my $db = CustomizedDB->new($dbh);
    my $db_for_default_model = $db->model('NO_EXIST_TABLE');
    is( ref $db_for_default_model, 'CustomizedDB');# NOT Kappa
};


done_testing;
