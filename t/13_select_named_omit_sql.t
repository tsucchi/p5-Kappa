#!perl
use strict;
use warnings;
use Test::More;
use Kappa;
use t::Util;
use Try::Tiny;

BEGIN {
    use t::TEST;
    package t::TEST;
    my $condition = { value => 'aaa' };

    sub test_select_named {
        my ($self) = @_;
        return $self->select_named($condition);
    }
    sub test_select_row_named {
        my ($self) = @_;
        return $self->select_row_named($condition);
    }
    sub test_select_all_named {
        my ($self) = @_;
        return $self->select_all_named($condition);
    }
    sub test_select_itr_named {
        my ($self) = @_;
        return $self->select_itr_named($condition);
    }
}

my $dbh = prepare_dbh();
prepare_testdata($dbh);
my $db = Kappa->new($dbh, {
    table_namespace => 't::TEST',
});

subtest 'select_named', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_select_named'), "SELECT * FROM TEST WHERE value = :value;\n");
    my $row = $model->test_select_named;
    ok( defined $row );
    is( $row->value, 'aaa');
};


subtest 'select_row_named', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_select_row_named'), "SELECT * FROM TEST WHERE value = :value;\n");
    my $row = $model->test_select_row_named;
    ok( defined $row );
    is( $row->value, 'aaa');
};

subtest 'select_all_named', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_select_all_named'), "SELECT * FROM TEST WHERE value = :value;\n");

    my @rows = $model->test_select_all_named();
    ok( @rows );
    is( $rows[0]->value, 'aaa');
};

subtest 'select_itr_named', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_select_itr_named'), "SELECT * FROM TEST WHERE value = :value;\n");

    my $itr = $model->test_select_itr_named();
    my $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');
};



done_testing;

