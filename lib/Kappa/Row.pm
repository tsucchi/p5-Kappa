package Kappa::Row;
use strict;
use warnings;
use Carp qw();

sub new {
    my ($class, $row, $db, $table_name, $option_href) = @_;
    my $self = {
        db         => $db,
        row_value  => $row,
        table_name => $table_name,
    };
    if( !!$option_href->{use_anonymous_class} ) {
        my $class_basename = defined $table_name ? $table_name : "_anon";
        my $select_id = $option_href->{select_id};
        my $class_orig = $class;
        $class = $class . "::" . $class_basename . "-" . $select_id;
        no strict 'refs';
        @{$class . "::ISA"} = $class_orig;
    }
    bless $self, $class;
}

sub table_name {
    my ($self) = @_;
    return $self->{table_name};
}

sub db {
    my ($self) = @_;
    my $db = $self->{db};
    return $db->model($self->table_name);
}

sub row_value {
    my ($self) = @_;
    return %{ $self->{row_value} || {} };
}

sub get_columns {
    my ($self) = @_;
    my %value = $self->row_value;
    return \%value;
}


# define accessor for row values.
sub AUTOLOAD {
    my ($self) = @_;
    my $method_name = our $AUTOLOAD;
    $method_name =~ s/.+:://;
    Carp::croak("method $method_name is not defined") if ( !exists $self->{row_value}->{$method_name} );;

    no strict 'refs';
    *{$AUTOLOAD} = sub {
        my ($self) = @_;
        return $self->{row_value}->{$method_name};
    };
    goto &$AUTOLOAD;
}

sub DESTROY {} #for AUTOLOAD


1;
__END__

=head1 NAME

Kappa::Row - default row object for Kappa

=head1 SYNOPSIS

  use Kappa;

=head1 DESCRIPTION

Kappa is a super-light ORM. 

=head1 METHODS


=cut

=head2 new($row, $handle)

create instance. 

=head2 db()

return caller ORM(Kappa or its subclass)

=cut

=head2 row_value()

get row value as hash

=cut

=head2 get_columns()

get row value as hash ref

=cut


=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi {at} cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
