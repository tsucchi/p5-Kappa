#!perl
use strict;
use warnings;
use Kappa;
use Test::More;
use t::Util;
use Try::Tiny;
use Carp qw();


BEGIN {
    use t::TEST;
    package t::TEST;
    sub handle_exception {
        my ($self, $sql, $binds_aref, $err) = @_;
        croak $err;
    }
};

my $dbh = prepare_dbh();
my $db = Kappa->new($dbh, {
    table_namespace => 't',
});


subtest 'select_row using model', sub {
    run_and_check_exception(sub {
        $db->model('TEST')->select_row({ id => \'no_exist_func()' }); # causes SQL error
    });
};

subtest 'select_row using default model', sub {
    run_and_check_exception(sub {
        $db->select_row('TEST', { id => \'no_exist_func()' }); # causes SQL error
    });
};


done_testing;

sub run_and_check_exception {
    my ($callback) = @_;
    try {
        $callback->();
        fail 'exception expected';
    } catch {
        #diag "$_\n";
        like( $_, qr/at $0 line \d+/ ); #contains error and line no in this test
    };
}
