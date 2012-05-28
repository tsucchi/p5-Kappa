package t::Util;
use parent qw(Exporter);
use strict;
use warnings;
use DBI;

our @EXPORT = qw(prepare_dbh prepare_testdata remove_db_file);

my $dbfile = "t/testdata.db";

INIT {
    remove_db_file();
}

END {
    remove_db_file();
}

sub prepare_dbh {
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","", { RaiseError => 1, PrintError => 0 });
    $dbh->do('CREATE TABLE TEST ( id int, value text )');
    $dbh->do('CREATE TABLE TEST2 ( id int, value text )');
    return $dbh;
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

sub remove_db_file {
    unlink $dbfile if ( -e $dbfile );
}


1;
