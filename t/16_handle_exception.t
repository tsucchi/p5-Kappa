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
    sub handle_exception {
        my ($self, $sql, $binds_aref, $err) = @_;
        die "customized error : $err";
    }
}

my $dbh = prepare_dbh();
my $db = Kappa->new($dbh, {
    table_namespace => 't::TEST',
});


subtest 'handle_exception', sub {
    try {
        $db->model('TEST')->select_row({ id => \'no_exist_func()' }); # causes SQL error
        fail 'exception expected';
    } catch {
        #warn $_;
        like( $_, qr/^customized error :/ );
    }
};


done_testing;

