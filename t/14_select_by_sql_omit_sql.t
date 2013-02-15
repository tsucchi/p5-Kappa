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
    my $params = ['aaa'];

    sub test_select_by_sql {
        my ($self) = @_;
        return $self->select_by_sql($params);
    }
    sub test_select_row_by_sql {
        my ($self) = @_;
        return $self->select_row_by_sql($params);
    }
    sub test_select_all_by_sql {
        my ($self) = @_;
        return $self->select_all_by_sql($params);
    }
    sub test_select_itr_by_sql {
        my ($self) = @_;
        return $self->select_itr_by_sql($params);
    }
}

my $dbh = prepare_dbh();
prepare_testdata($dbh);
my $db = Kappa->new($dbh, {
    table_namespace => 't::TEST',
});

subtest 'select_by_sql', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_select_by_sql'), "SELECT * FROM TEST WHERE value = ?;\n\n");
    my $row = $model->test_select_by_sql;
    ok( defined $row );
    is( $row->value, 'aaa');
};


subtest 'select_row_by_sql', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_select_row_by_sql'), "SELECT * FROM TEST WHERE value = ?;\n\n");
    my $row = $model->test_select_row_by_sql;
    ok( defined $row );
    is( $row->value, 'aaa');
};

subtest 'select_all_by_sql', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_select_all_by_sql'), "SELECT * FROM TEST WHERE value = ?;\n\n");

    my @rows = $model->test_select_all_by_sql();
    ok( @rows );
    is( $rows[0]->value, 'aaa');
};

subtest 'select_itr_by_sql', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_select_itr_by_sql'), "SELECT * FROM TEST WHERE value = ?;\n\n");

    my $itr = $model->test_select_itr_by_sql();
    my $row = $itr->next;
    ok( defined $row );
    is( $row->value, 'aaa');
};



done_testing;

