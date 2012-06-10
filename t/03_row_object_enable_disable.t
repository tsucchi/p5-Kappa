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
    package CustomizedRow::TEST;
    our @ISA = qw(Kappa::Row);
    sub bbb { return 'bbb' }
}

subtest 'disable row object', sub {
    my $db = Kappa->new($dbh);
    my $row = $db->select_row('TEST', $condition, $option);
    ok( $row->isa('Kappa::Row') );
    {
        my $guard = $db->row_object_enable(0);
        $row = $db->select_row('TEST', $condition, $option);
        is( ref $row, 'HASH' );
    }
    # dismiss guard
    $row = $db->select_row('TEST', $condition, $option);
    ok( $row->isa('Kappa::Row') );

    $db->row_object_enable(0);
    $row = $db->select_row('TEST', $condition, $option);
    is( ref $row, 'HASH' );
};


subtest 'enable row object', sub {
    my $db = Kappa->new($dbh);
    $db->row_object_enable(0);
    my $row = $db->select_row('TEST', $condition, $option);
    is( ref $row, 'HASH' );
    {
        my $guard = $db->row_object_enable(1);
        $row = $db->select_row('TEST', $condition, $option);
        ok( $row->isa('Kappa::Row') );
    }
    # dismiss guard
    $row = $db->select_row('TEST', $condition, $option);
    is( ref $row, 'HASH' );

    {
        $db->row_object_enable(1);
        $row = $db->select_row('TEST', $condition, $option);
        ok( $row->isa('Kappa::Row') );
    }
};

subtest 'enable row object for customized row object', sub {
    my $db = Kappa->new($dbh, {
        row_namespace => 'CustomizedRow',
    });
    my $row = $db->select_row('TEST', $condition, $option);
    ok( $row->isa('CustomizedRow::TEST') );
    {
        my $guard = $db->row_object_enable(0);
        $row = $db->select_row('TEST', $condition, $option);
        is( ref $row, 'HASH' );
    }
    # dismiss guard
    $row = $db->select_row('TEST', $condition, $option);
    ok( $row->isa('CustomizedRow::TEST') );
};

subtest 'nested guard', sub {
    my $db = Kappa->new($dbh);
    my $row = $db->select_row('TEST', $condition, $option);
    ok( $row->isa('Kappa::Row') );
    {
        my $guard = $db->row_object_enable(0);
        $row = $db->select_row('TEST', $condition, $option);
        is( ref $row, 'HASH' );
        {
            my $guard = $db->row_object_enable(0);
            $row = $db->select_row('TEST', $condition, $option);
            is( ref $row, 'HASH' );
        }
        $row = $db->select_row('TEST', $condition, $option);
        is( ref $row, 'HASH' );
    }
    # dismiss guard
    $row = $db->select_row('TEST', $condition, $option);
    ok( $row->isa('Kappa::Row') );

};


done_testing();
