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
                    return $self->row_namespace->new($row, $self, $table_name, { use_anonymous_class => 1 });
                }
            }
            return Kappa::Row->new($row, $self, $table_name, { use_anonymous_class => 1 });
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
            my %options = %{ $self->options || {} };
            $options{table_name} = $table_name;
            return $table_class->new($self->dbh, \%options);
        }
        if( Class::Load::try_load_class($self->table_namespace) ) {
            return $self->table_namespace->new($self->dbh, $self->options);
        }
    }
    return Kappa->new($self->dbh, $self->options);
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

=head2 new($dbh, [$options_href])

create instance. 

available options are as follows.

=over 4

=item * row_namespace   (string, default 'Kappa::Row') :  namespace for row object.

=item * table_namespace (string, default 'Kappa')      :  namespace for table class.

=back

  my $dbh = DBI->connect($dsn, $user, $pass);
  my $db = Kappa->new($dbh, {
      row_namespace   => 'MyProj::Row',
      table_namespace => 'MyProj::Table',
  });

=head2 create($table_name)

create instance for defined table class. if table class for $table_name is not found, 
return default class.

  my $db = Kappa->new($dbh, {
      table_namespace => 'MyProj::Table',
  });
  my $db_for_order = $db->create('Order'); #return table MyProj::Table::Order table class(if defined)

In this case, Instance of MyProj::Table::Order will be returned. If MyProj::Table::Order is not defined, 
return MyProj::Table instance if defiend MyProj::Table and if not defined both of them, return Kappa instance.

=head2 row_object_enable($status)

$status: BOOL
enable or disable making row object. if return value is required, this value is guard object.

  my $db = Kappa->new($dbh);
  {
      my $guard = $db->row_object_enable(0); #set false to row_object_enable
      my $row = $db->select('SOME_TABLE', { id => 123 }); # $row is not row_object (returns hashref in this case)
  }
  my $row = $db->select('SOME_TABLE', { id => 123 }) # row object is returned.(row_object_enable is currently TRUE)

=head1 METHODS FROM PARENT CLASS(SQL::Executor)

folowing methods are delived from L<SQL::Executor>. Methods named select*_itr return Iterator using SQL::Executor::Iterator, 
and other select* methods return Row object(Kappa::Row or child of the one).

=head2 select($table_name, $where, $option)

=head2 select_row($table_name, $where, $option)

=head2 select_all($table_name, $where, $option)

=head2 select_itr($table_name, $where, $option)

=head2 select_named($sql, $params_href, $table_name)

=head2 select_row_named($sql, $params_href, $table_name)

=head2 select_all_named($sql, $params_href, $table_name)

=head2 select_itr_named($sql, $params_href, $table_name)

=head2 select_by_sql($sql, \@binds, $table_name)

=head2 select_row_by_sql($sql, \@binds, $table_name)

=head2 select_all_by_sql($sql, \@binds, $table_name)

=head2 select_itr_by_sql($sql, \@binds, $table_name)

=head2 select_with_fields($table_name, $fields_aref, $where, $option)

=head2 select_row_with_fields($table_name, $fields_aref, $where, $option)

=head2 select_all_with_fields($table_name, $fields_aref, $where, $option)

=head2 select_itr_with_fields($table_name, $fields_aref, $where, $option)

=head2 insert($table_name, $values)

=head2 insert_multi($table_name, @args)

=head2 delete($table_name, $where)

=head2 update($table_name, $set, $where)


=head1 DEFINE CUSTOMIZED ROW CLASS

You can define Row class specified in specified in row_namespace at new(). for example, define MyProj::Row::Order like this,

  package MyProj::Row::Order;
  use parent qw(Kappa::Row);
  use strict;
  use warnings;

  sub price_with_tax {
      my ($self) = @_
      return $self->price * $self->tax;
  }

  1;

using this row object like this, 

  my $db = Kappa->new($dbh, { row_namespace => 'MyProj::Row' });
  my @rows = $db->select('Order', { customer_name => 'some_customer' });
  for my $row ( @rows ) {
      print "$row->product_name : $row->price_with_tax \n"; # enable to use customized method(price_with_tax)
  }

What row object can do is only call calling customized method (in this case calling price_with_tax()).

=head1 DEFINE CUSTOMIZED TABLE CLASS

You can also define Table class specified in table_namespace at new(). for example, define MyProj::Table::Order like this,

  package MyProj::Table::Order;
  use parent qw(Kappa);
  use strict;
  use warnings;

  sub select_using_very_complex_sql {
      my($self, $condition_href) = @_;
      my ($sql, @binds)  = $self->_very_complex_sql($condition_href);
      return $self->select_by_sql($sql, \@binds, $self->table_name); #recommend to pass $self->table_name to make row object for this table
  }
  sub _very_complex_sql { ... }

using this table class like this,

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table' });
  my $db_for_order = $db->create('Order');
  my @rows = $db_for_order->select_using_very_complex_sql($condition_href);


=head1 How to use Transaction.

You can use L<DBI>'s transaction (begin_work and commit).

  use DBI;
  use Kappa
  my $dbh = DBI->connect($dsn, $id, $pass);
  my $db = Kappa->new($dbh);
  $dbh->begin_work();
  $db->insert('SOME_TABLE', { id => 124, value => 'xxxx'} );
  $db->insert('SOME_TABLE', { id => 125, value => 'yyy' } );
  $dbh->commit();


Or you can also use transaction management modules like L<DBIx::TransactionManager>.

  use DBI;
  use Kappa;
  use DBIx::TransactionManager;
  my $dbh = DBI->connect($dsn, $id, $pass);
  my $db = Kappa->new($dbh);
  my $tm = DBIx::TransactionManager->new($dbh);
  my $txn = $tm->txn_scope;
  $db->insert('SOME_TABLE', { id => 124, value => 'xxxx'} );
  $db->insert('SOME_TABLE', { id => 125, value => 'yyy' } );
  $txn->commit;


=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi {at} cpan.orgE<gt>

=head1 SEE ALSO

L<SQL::Executor>

=head1 LICENSE

Copyright (C) Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
