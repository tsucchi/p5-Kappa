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
    sub test_sql {
        my ($self) = @_;
        return $self->sql_from_data_section(); #using default SQL name
    }
    sub test_sql2 {
        my ($self) = @_;
        return $self->sql; #using default SQL name
    }
}

my $dbh = prepare_dbh();
my $db = Kappa->new($dbh, {
    table_namespace => 't::TEST',
});


subtest 'sql_from_data_section', sub {
    my $db_for_test = $db->model('TEST');
    is( $db_for_test->sql_from_data_section('test_sql'), "SELECT * FROM TEST;\n\n" );
};

subtest 'default SQL name', sub {
    my $db_for_test = $db->model('TEST');
    is( $db_for_test->test_sql(), "SELECT * FROM TEST;\n\n" );
};

subtest 'invalid section name', sub {
    my $db_for_test = $db->model('TEST');
    try {
        $db_for_test->sql_from_data_section('no_exist_sql');
        fail 'exception expected';
    } catch {
        like( $_, qr/^can't find SQL from __DATA__ section : /);
    };
};

subtest 'cannot find SQL because table name is not determined', sub {
    try {
        $db->sql_from_data_section('test_sql');
        fail 'exception expected';
    } catch {
        like( $_, qr/^can't find SQL from __DATA__ section : /);
    };
};

subtest 'default SQL name in sql (method alias)', sub {
    my $db_for_test = $db->model('TEST');
    is( $db_for_test->test_sql2, "SELECT * FROM TEST;\n\n" );
};


done_testing;

