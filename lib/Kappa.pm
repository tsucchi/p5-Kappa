package Kappa;
use parent qw(SQL::Executor);
use strict;
use warnings;
our $VERSION = '0.01';
use Class::Accessor::Lite (
    ro => ['dbh', 'row_namespace', 'table_namespace', 'options', 'table_name'],
);
use Kappa::Row;
use Class::Load qw();
use Scope::Guard;

sub new {
    my ($class, $dbh, $option_href) = @_;
    my $self = $class->SUPER::new($dbh, {
        callback => sub {
            my ($self, $row, $table_name) = @_;
            if( defined $self->row_namespace ) {
                my $row_class = $self->row_namespace . "::$table_name";
                if( Class::Load::try_load_class($row_class) ) {
                    return $row_class->new($row, $self, $table_name);
                }
                if ( Class::Load::try_load_class($self->row_namespace) ) {
                    return $self->row_namespace->new($row, $self, $table_name);
                }
            }
            return Kappa::Row->new($row, $self, $table_name);
        },
    });

    $self->{row_namespace}   = $option_href->{row_namespace};
    $self->{table_namespace} = $option_href->{table_namespace};
    $self->{table_name}      = $option_href->{table_name};

    $self->{options} = $option_href;
    bless $self, $class;
}

sub create {
    my ($self, $table_name) = @_;
    if( defined $self->table_namespace ) {
        my $table_class = $self->table_namespace . "::$table_name";
        if( Class::Load::try_load_class($table_class) ) {
            my $options = $self->options;
            $options->{table_name} = $table_name;
            return $table_class->new($self->dbh, $options);
        }
        if( Class::Load::try_load_class($self->table_namespace) ) {
            return $self->table_namespace->new($self->dbh, $self->options);
        }
    }
    return Kappa->new($self->dbh, $self->options, $table_name);
}

sub row_object_enable {
    my ($self, $row_object_enable) = @_;
    if ( !!$row_object_enable ) {
        $self->restore_callback;
        return Scope::Guard->new( sub { $self->disable_callback } ) if ( defined wantarray() );# guard object is required.
    }
    else {
        $self->disable_callback;
        return Scope::Guard->new( sub { $self->restore_callback } ) if ( defined wantarray() );# guard object is required.
    }
}

1;
__END__

=head1 NAME

Kappa - super-light ORM

=head1 SYNOPSIS

  use Kappa;
  use DBI;
  my $dbh = DBI->connect($dsn, $id, $pw);
  my $db = Kappa->new($dbh);
  my $row_obj = $db->select('SOME_TABLE', { id => 123 });
  print $row_obj->id, $row_obj->value;

=head1 DESCRIPTION

Kappa is a super-light ORM. You can use this module without defining schema-class and if you want to define table-related logic,
you can define table-class for each table.

=head1 METHODS

=head2 new($dbh, $options_href)

create instance. 

available options are as follows.

row_namespace   (string, default 'Kappa::Row') :  namespace for row object.
table_namespace (string, default 'Kappa')      :  namespace for table class.

=head2 create($table_name)

create instance for defined table class. if table class for $table_name is not found, 
return default class.

=head2 row_object_enable($status)

$status: BOOL
enable or disable making row object. if return value is required, this value is guard object.

  my $db = Kappa->new($dbh);
  {
      my $guard = $db->row_object_enable(1); #set false to row_object_enable
      my $row = $db->select('SOME_TABLE', { id => 123 }); # $row is not row_object (returns hashref in this case)
  }
  my $row = $db->select('SOME_TABLE', { id => 123 }) # row object is returned.(row_object_enable is currently TRUE)


=head1 DEFINE ROW CLASS

=head1 DEFINE TABLE CLASS

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi {at} cpan.orgE<gt>

=head1 SEE ALSO

L<SQL::Executor>

=head1 LICENSE

Copyright (C) Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
