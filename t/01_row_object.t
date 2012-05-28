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
    package CustomizedRow;
    our @ISA = qw(Kappa::Row);
    sub aaa { return 'aaa' };
}

{
    package CustomizedRow::TEST;
    our @ISA = qw(CustomizedRow);
    sub bbb { return 'bbb' }
}

subtest 'default row object', sub {
    my $db = Kappa->new($dbh);
    my $row = $db->select_row('TEST', $condition, $option);
    ok( $row->isa('Kappa::Row') );
    is( $row->id, 1);
    is( $row->value, 'aaa');
    is( $row->table_name, 'TEST');
};

subtest 'customized row object(global)', sub {
    my $db = Kappa->new($dbh, {
        row_namespace => 'CustomizedRow',
    });
    my $row = $db->select_row('TEST2', $condition, $option);
    ok( $row->isa('CustomizedRow') );
    is( $row->id, 1);
    is( $row->value, 'aaa');
    is( $row->aaa,   'aaa');
    is( $row->table_name, 'TEST2');
};

subtest 'customized row object(each table)', sub {
    my $db = Kappa->new($dbh, {
        row_namespace => 'CustomizedRow',
    });
    my $row = $db->select_row('TEST', $condition, $option);#table TEST has row class
    ok( $row->isa('CustomizedRow::TEST') );
    is( $row->id, 1);
    is( $row->value, 'aaa');
    is( $row->aaa,   'aaa');
    is( $row->table_name, 'TEST');
};


done_testing();
