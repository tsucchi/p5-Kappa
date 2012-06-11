#!perl
use strict;
use warnings;
use Test::More;
use t::Util;
use t::CustomizedTable;
use Kappa;

my $dbh = prepare_dbh();
prepare_testdata($dbh);

subtest 'delete (normal)', sub {
    my $db = Kappa->new($dbh);
    $db->insert('TEST', { id => 123, value => 'aaa' });
    $db->delete('TEST', { id => 123 });
    my $row = $db->select('TEST', { id => 123 });
    ok( !defined $row );
};

subtest 'delete using table class', sub {
    my $db_for_test = db_for_test($dbh);
    $db_for_test->insert('TEST', { id => 123, value => 'aaa' });
    $db_for_test->delete('TEST', { id => 123 });
    my $row = $db_for_test->select('TEST', { id => 123 });
    ok( !defined $row );

    $db_for_test->insert({ id => 124, value => 'bbb' });
    $db_for_test->delete({ id => 124 });
    $row = $db_for_test->select('TEST', { id => 124 });
    ok( !defined $row );
};




done_testing;

