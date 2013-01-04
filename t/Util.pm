package t::Util;
use parent qw(Exporter);
use strict;
use warnings;
use DBI;

our @EXPORT = qw(prepare_dbh prepare_testdata prepare_table args_for_connect);

sub args_for_connect {
    return ("dbi:SQLite:dbname=:memory:","","", { RaiseError => 1, PrintError => 0 });
}

sub prepare_dbh {
    my $dbh = DBI->connect( args_for_connect() );
    prepare_table($dbh);
    return $dbh;
}

sub prepare_table {
    my ($dbh) = @_;
    $dbh->do('CREATE TABLE TEST ( id int, value text )');
    $dbh->do('CREATE TABLE TEST2 ( id int, value text )');
}

sub prepare_testdata {
    my ($dbh) = @_;
    $dbh->do("INSERT INTO TEST VALUES (1, 'aaa')");
    $dbh->do("INSERT INTO TEST VALUES (2, 'aaa')");
    $dbh->do("INSERT INTO TEST VALUES (3, 'bbb')");

    $dbh->do("INSERT INTO TEST2 VALUES (1, 'aaa')");
    $dbh->do("INSERT INTO TEST2 VALUES (2, 'aaa')");
    $dbh->do("INSERT INTO TEST2 VALUES (3, 'bbb')");

}


1;
