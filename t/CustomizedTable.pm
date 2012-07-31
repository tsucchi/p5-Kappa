package t::CustomizedTable;
use parent qw(Exporter);
use strict;
use warnings;

our @EXPORT = qw(db_for_test);

sub db_for_test {
    my ($dbh) = @_;
    my $db = Kappa->new($dbh, {
        table_namespace => 'CustomizedTable',
    });
    return $db->model('TEST');
}

{
    package CustomizedTable;
    our @ISA = qw(Kappa);
    sub xxx { return 'xxx' }
}

{
    package CustomizedTable::TEST;
    our @ISA = qw(CustomizedTable);
    sub yyy { return 'yyy' }
}

{
    package CustomizedRow;
    our @ISA = qw(Kappa::Row);
    sub aaa { return 'aaa' }
}

1;
