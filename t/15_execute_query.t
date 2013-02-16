#!perl
use strict;
use warnings;
use Test::More;
use t::Util;
use Kappa;

BEGIN {
    use t::TEST;
    package t::TEST;

    sub test_insert_by_execute_query {
        my ($self, $id, $value) = @_;
        return $self->execute_query([$id, $value]);
    }

    sub test_insert_by_execute_query_named {
        my ($self, $id, $value) = @_;
        return $self->execute_query_named({ id => $id, value => $value });
    }
}

my $dbh = prepare_dbh();
prepare_testdata($dbh);
my $db = Kappa->new($dbh, {
    table_namespace => 't::TEST',
});

my $sql  = "INSERT INTO TEST (id, value) VALUES (?, ?);\n\n";
my $sql2 = "INSERT INTO TEST (id, value) VALUES (:id, :value);\n\n";

subtest 'execute_query', sub {
    $db->execute_query($sql, [121, 'aaa']);
    my $row = $db->select('TEST', { id => 121 });
    ok( defined $row );
    is( $row->value, 'aaa');
};

subtest 'execute_query omit sql', sub {
    my $model = $db->model('TEST');
    is( $model->sql('test_insert_by_execute_query'), $sql);
    $model->test_insert_by_execute_query(122, 'bbb');
    my $row = $db->select('TEST', { id => 122 });
    ok( defined $row );
    is( $row->value, 'bbb');
};

subtest 'execute_query_named', sub {
    $db->execute_query_named($sql, { id => 123, value => 'ccc' });
    my $row = $db->select('TEST', { id => 123 });
    ok( defined $row );
    is( $row->value, 'ccc');
};

# subtest 'execute_query omit sql', sub {
#     my $model = $db->model('TEST');
#     is( $model->sql('test_insert_by_execute_query'), $sql);
#     $model->test_insert_by_execute_query(122, 'bbb');
#     my $row = $db->select('TEST', { id => 122 });
#     ok( defined $row );
#     is( $row->value, 'bbb');
# };

done_testing;

