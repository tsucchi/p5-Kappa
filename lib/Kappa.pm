package Kappa;
use parent qw(SQL::Executor);
use strict;
use warnings;

our $VERSION = '0.19';

use Class::Accessor::Lite (
    ro => ['row_namespace', 'iterator_namespace', 'table_namespace', 'options', 'table_name'],
    rw => ['id_generator'],
);
use Kappa::Row;
use Kappa::Iterator;
use Class::Load qw();
use Scope::Guard;
use Carp qw();
use Data::UUID;
use Data::Section::Simple qw();
use Try::Tiny;

sub new {
    my ($class, $dbh_or_handler, $option_href) = @_;
    my $dbh     = ref $dbh_or_handler eq 'DBIx::Handler' ? $dbh_or_handler->dbh : $dbh_or_handler;
    my $handler = ref $dbh_or_handler eq 'DBIx::Handler' ? $dbh_or_handler      : undef;
    my $self = $class->SUPER::new($dbh, {
        %{ $option_href || {} },
        callback => \&_callback,
    });
    $self->{handler} = $handler;
    $self->_set_options($option_href);
    bless $self, $class;
}

sub connect {
    my ($class, $dsn, $user, $pass, $option_for_dbi, $option_href) = @_;
    my $self = $class->SUPER::connect($dsn, $user, $pass, $option_for_dbi, {
        %{ $option_href || {} },
        callback => \&_callback,
    });
    $self->_set_options($option_href);
    bless $self, $class;
}


sub _callback {
    my ($self, $row, $table_name, $select_id) = @_;
    if( defined $table_name && defined $self->row_namespace ) {
        my $row_class = $self->row_namespace . "::$table_name";
        if( Class::Load::load_optional_class($row_class) ) {
            return $row_class->new($row, $self, $table_name);
        }
        if ( Class::Load::load_optional_class($self->row_namespace) ) {
            return $self->row_namespace->new($row, $self, $table_name, { use_anonymous_class => 1, select_id => $select_id });
        }
    }
    return Kappa::Row->new($row, $self, $table_name, { use_anonymous_class => 1, select_id => $select_id });
}

sub _set_options {
    my ($self, $option_href) = @_;
    $self->{row_namespace}      = $option_href->{row_namespace};
    $self->{iterator_namespace} = $option_href->{iterator_namespace};
    $self->{table_namespace}    = $option_href->{table_namespace};
    $self->{table_name}         = $option_href->{table_name};
    $self->{row_object_enable}  = defined $option_href->{row_object_enable} ? $option_href->{row_object_enable} : 1;

    $self->{options} = $option_href;
}


sub model {
    my ($self, $table_name) = @_;
    my $model = $self->_create_model($table_name);
    $model->{parent} = defined $self->{parent} ? $self->{parent} : $self;
    return $model;
}

sub _create_model {
    my ($self, $table_name) = @_;

    my %options = %{ $self->options || {} };
    $options{table_name} = $table_name;

    my $dbh_or_handler = defined $self->handler ? $self->handler : $self->dbh;
    if( defined $self->table_namespace ) {
        my $table_class = $self->table_namespace . "::$table_name";

        if( Class::Load::load_optional_class($table_class) ) {
            return $table_class->new($dbh_or_handler, \%options);
        }
        elsif( Class::Load::load_optional_class($self->table_namespace) ) {
            return $self->table_namespace->new($dbh_or_handler, \%options);
        }
    }
    my $class_name = ref $self;
    return $class_name->new($dbh_or_handler, \%options); # Kappa or subclass
}


sub row_object_enable {
    my ($self, $new_status) = @_;

    my $current_status = $self->_row_object_enable(); #preserve current(for guard object)
    $self->_row_object_enable($new_status);

    $self->_switch_callback($new_status);

    if ( defined wantarray() ) {# guard object is required.
        return Scope::Guard->new( sub { 
            $self->row_object_enable($current_status);
        });
    }
}

# callback switch on/of
sub _switch_callback {
    my ($self, $status) = @_;
    if ( !!$status ) {
        $self->restore_callback;
    }
    else {
        $self->disable_callback;
    }
}

sub _auto_set_row_object_enable {
    my ($self) = @_;
    my $current_status = $self->_row_object_enable();
    $self->_switch_callback($current_status);
}

# get/set current row_object_enable status in parent object
sub _row_object_enable {
    my $self = shift;
    if( @_ ) {#setter
        if( defined $self->{parent} ) {
            $self->{parent}->{row_object_enable} = $_[0];
        }
        else {
            $self->{row_object_enable} = $_[0];
        }
    }
    else {# getter
        return defined $self->{parent} ? $self->{parent}->{row_object_enable} : $self->{row_object_enable};
    }
}

sub select_row { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($where, $option) = @_;
        return $self->SUPER::select_row($self->table_name, $where, $option);
    }
    my ($table_name, $where, $option) = @_;
    return $self->SUPER::select_row($table_name, $where, $option);
}

sub select_all { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($where, $option) = @_;
        return $self->SUPER::select_all($self->table_name, $where, $option);
    }
    my ($table_name, $where, $option) = @_;
    return $self->SUPER::select_all($table_name, $where, $option);
}

sub select_itr { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($where, $option) = @_;
        return $self->SUPER::select_itr($self->table_name, $where, $option);
    }
    my ($table_name, $where, $option) = @_;
    return $self->SUPER::select_itr($table_name, $where, $option);
}

sub select_named { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($where, $option) = @_;
        return $self->SUPER::select_named($self->sql, $where, $option);
    }
    my ($sql, $where, $option, $table_name) = @_;
    $table_name = $self->table_name if ( !defined $table_name );
    return $self->SUPER::select_named($sql, $where, $option, $table_name);
}

sub select_row_named { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($where, $option) = @_;
        return $self->SUPER::select_row_named($self->sql, $where, $option);
    }
    my ($sql, $where, $option, $table_name) = @_;
    $table_name = $self->table_name if ( !defined $table_name );
    return $self->SUPER::select_row_named($sql, $where, $option, $table_name);
}

sub select_all_named { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($where, $option) = @_;
        return $self->SUPER::select_all_named($self->sql, $where, $option);
    }
    my ($sql, $where, $option, $table_name) = @_;
    $table_name = $self->table_name if ( !defined $table_name );
    return $self->SUPER::select_all_named($sql, $where, $option, $table_name);
}

sub select_itr_named { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($where, $option) = @_;
        return $self->SUPER::select_itr_named($self->sql, $where, $option);
    }
    my ($sql, $where, $option, $table_name) = @_;
    $table_name = $self->table_name if ( !defined $table_name );
    return $self->SUPER::select_itr_named($sql, $where, $option, $table_name);
}


sub select_by_sql { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($params_aref) = @_;
        return $self->SUPER::select_by_sql($self->sql, $params_aref, $self->table_name);
    }
    my ($sql, $params_aref, $table_name) = @_;
    return $self->SUPER::select_by_sql($sql, $params_aref, $table_name) if ( defined $table_name && $table_name ne '' );
    return $self->SUPER::select_by_sql($sql, $params_aref, $self->table_name);
}

sub select_row_by_sql { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($params_aref) = @_;
        return $self->SUPER::select_row_by_sql($self->sql, $params_aref, $self->table_name);
    }
    my ($sql, $params_aref, $table_name) = @_;
    return $self->SUPER::select_row_by_sql($sql, $params_aref, $table_name) if ( defined $table_name && $table_name ne '' );
    return $self->SUPER::select_row_by_sql($sql, $params_aref, $self->table_name);
}


sub select_all_by_sql { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($params_aref) = @_;
        return $self->SUPER::select_all_by_sql($self->sql, $params_aref, $self->table_name);
    }
    my ($sql, $params_aref, $table_name) = @_;
    return $self->SUPER::select_all_by_sql($sql, $params_aref, $table_name) if ( defined $table_name && $table_name ne '' );
    return $self->SUPER::select_all_by_sql($sql, $params_aref, $self->table_name);
}

sub select_itr_by_sql { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($params_aref) = @_;
        return $self->_select_itr_by_sql($self->sql, $params_aref, $self->table_name);
    }
    my ($sql, $params_aref, $table_name) = @_;
    return $self->_select_itr_by_sql($sql, $params_aref, $table_name) if ( defined $table_name && $table_name ne '' );
    return $self->_select_itr_by_sql($sql, $params_aref, $self->table_name);
}

sub _select_itr_by_sql {
    my ($self, $sql, $binds_aref, $table_name) = @_;
    my $sth = $self->execute_query($sql, $binds_aref || []);
    my $select_id = defined $self->callback ? $self->select_id : undef; #select_id does not need if callback is disabled.

    if( defined $table_name && defined $self->iterator_namespace ) {
        my $iterator_class = $self->iterator_namespace . "::$table_name";
        if( Class::Load::load_optional_class($iterator_class) ) {
            return $iterator_class->new($sth, $table_name, $self, $select_id);
        }
        if ( Class::Load::load_optional_class($self->iterator_namespace) ) {
            return $self->iterator_namespace->new($sth, $table_name, $self, $select_id);
        }
    }
    return Kappa::Iterator->new($sth, $table_name, $self, $select_id);
}


sub select_row_with_fields { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($fields_aref, $where, $option) = @_;
        return $self->SUPER::select_row_with_fields($self->table_name, $fields_aref, $where, $option);
    }
    my ($table_name, $fields_aref, $where, $option) = @_;
    return $self->SUPER::select_row_with_fields($table_name, $fields_aref, $where, $option);
}

sub select_all_with_fields { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($fields, $where, $option) = @_;
        return $self->SUPER::select_all_with_fields($self->table_name, $fields, $where, $option);
    }
    my ($table_name, $fields, $where, $option) = @_;
    return $self->SUPER::select_all_with_fields($table_name, $fields, $where, $option);
}

sub select_itr_with_fields { #override
    my $self = shift;
    $self->_auto_set_row_object_enable;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($fields_aref, $where, $option) = @_;
        return $self->SUPER::select_itr_with_fields($self->table_name, $fields_aref, $where, $option);
    }
    my ($table_name, $fields_aref, $where, $option) = @_;
    return $self->SUPER::select_itr_with_fields($table_name, $fields_aref, $where, $option);
}

sub insert { #override
    my $self = shift;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($values) = @_;
        $self->SUPER::insert($self->table_name, $values);
        return;
    }
    my ($table_name, $values) = @_;
    $self->SUPER::insert($table_name, $values);
    return;
}

sub insert_multi { #override
    my $self = shift;
    if( $self->_is_table_name_omit($_[0]) ) {
        my (@args) = @_;
        $self->SUPER::insert_multi($self->table_name, @args);
        return;
    }
    my ($table_name, @args) = @_;
    $self->SUPER::insert_multi($table_name, @args);
    return;
}

sub insert_on_duplicate { #override
    my $self = shift;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($insert_href, $update_href) = @_;
        $self->SUPER::insert_on_duplicate($self->table_name, $insert_href, $update_href);
        return;
    }
    my ($table_name, $insert_href, $update_href) = @_;
    $self->SUPER::insert_on_duplicate($table_name, $insert_href, $update_href);
    return;
}


sub update { #override
    my $self = shift;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($set, $where) = @_;
        $self->SUPER::update($self->table_name, $set, $where);
        return;
    }
    my ($table_name, $set, $where) = @_;
    $self->SUPER::update($table_name, $set, $where);
    return;
}

sub delete { #override
    my $self = shift;
    if( $self->_is_table_name_omit($_[0]) ) {
        my ($where) = @_;
        $self->SUPER::delete($self->table_name, $where);
        return;
    }
    my ($table_name, $where) = @_;
    $self->SUPER::delete($table_name, $where);
    return;
}


sub execute_query { #override
    my $self = shift;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($binds_aref) = @_;
        return $self->SUPER::execute_query($self->sql, $binds_aref);
    }
    my ($sql, $binds_aref, $table_name) = @_;
    $table_name = $self->table_name if ( !defined $table_name );
    return $self->SUPER::execute_query($sql, $binds_aref, $table_name);
}

sub execute_query_named { #override
    my $self = shift;
    if( $self->_is_sql_omit($_[0]) ) {
        my ($params_href) = @_;
        return $self->SUPER::execute_query_named($self->sql, $params_href);
    }
    my ($sql, $params_href, $table_name) = @_;
    $table_name = $self->table_name if ( !defined $table_name );
    return $self->SUPER::execute_query_named($sql, $params_href, $table_name);
}

sub sql_from_data_section {
    my ($self, $section_sql_name) = @_;
    my $pkg = ref $self;
    my $ds = Data::Section::Simple->new($pkg);
    if ( !defined $section_sql_name ) {
        my $level = $self->_is_my_method( (caller(1))[3] ) ? 2 : 1;
        $section_sql_name = (caller($level))[3];# method name
        $section_sql_name =~ s/.+::// ;
    }
    my $result = '';
    my $error_message = '';
    try {
        $result = $ds->get_data_section($section_sql_name);
    } catch {
        $result = undef;
        $error_message = $_;
    };
    if( !defined $result ) {
        Carp::croak "can't find SQL from __DATA__ section : $error_message\n";
    }
    return $result;
}

*sql = \&sql_from_data_section;

# whether Kappa's method or not (only for sql specified method)
sub _is_my_method {
    my ($self, $method_name) = @_;
    $method_name =~ s/.+::// ;
    my %my_method = (
        'select_named'        => 1,
        'select_row_named'    => 1,
        'select_all_named'    => 1,
        'select_itr_named'    => 1,
        'select_by_sql'       => 1,
        'select_row_by_sql'   => 1,
        'select_all_by_sql'   => 1,
        'select_itr_by_sql'   => 1,
        'execute_query_named' => 1,
        'execute_query'       => 1,
    );
    return exists $my_method{$method_name};
}

sub select_id { #override
    my ($self) = @_;
    if( !defined $self->id_generator ) {
        $self->id_generator( Data::UUID->new() );
    }
    return $self->id_generator->create_str;
}

sub _is_table_name_omit {
    my ($self, $arg0) = @_;
    return defined $self->table_name && $self->table_name ne '' && ref $arg0 ne '';
}

sub _is_sql_omit {
    my ($self, $arg0) = @_;
    return ref $arg0 eq 'HASH' || ref $arg0 eq 'ARRAY';
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

=item * iterator_namespace (string, default 'Kappa::Iterator') :  namespace for iterator.

=item * row_object_enable (BOOL, default 1(TRUE))      :  Row object is generated or not

=back

  my $dbh = DBI->connect($dsn, $user, $pass);
  my $db = Kappa->new($dbh, {
      row_namespace      => 'MyProj::Row',
      table_namespace    => 'MyProj::Table',
      iterator_namespace => 'MyProj::Iterator',
  });

=head2 model($table_name)

create instance for defined table class. if table class for $table_name is not found, 
return default class.

  my $db = Kappa->new($dbh, {
      table_namespace => 'MyProj::Table',
  });
  my $db_for_order = $db->model('Order'); #return table MyProj::Table::Order table class(if defined)

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

folowing methods are delived from L<SQL::Executor>. Methods named select*_itr return Iterator using Kappa::Iterator(by default
it is the same as SQL::Executor::Iterator), and other select* methods return Row object(Kappa::Row or child of the one).

=head2 select($table_name, $where, $option)

return one Row object if scalar context is expected, or in array context, return arrays of Row objects. like this,

  my $db = Kappa->new($dbh);
  my @rows = $db->select('SOME_TABLE', { value => 'aaa' }); # return Row objects
  my $row = $db->select('SOME_TABLE', { value => 'aaa' });  # return a Row object

if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  my @rows1 = $db_for_sometable->select({ value => 'aaa' }); #omit $table_name
  my @rows2 = $db_for_sometable->select('SOME_TABLE', { value => 'aaa' }); #you can also specify table name 

input parameter $where accepts hash_ref, array_ref, or L<SQL::Maker::Condition> instance. see L<SQL::Maker> select for details.
input parameter $options is the same as L<SQL::Maker>'s one.

=head2 select_row($table_name, $where, $option)

return one Row object. if found more than one row, return the first one.

if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  my $row1 = $db_for_sometable->select_row({ value => 'aaa' }); #omit $table_name
  my $row2 = $db_for_sometable->select_row('SOME_TABLE', { value => 'aaa' }); #you can also specify table name 


=head2 select_all($table_name, $where, $option)

return array of Row objects. 

if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  my @rows1 = $db_for_sometable->select_all({ value => 'aaa' }); #omit $table_name
  my @rows2 = $db_for_sometable->select_all('SOME_TABLE', { value => 'aaa' }); #you can also specify table name 

=head2 select_itr($table_name, $where, $option)

return iterator that contains Row object. Iterator is instance of L<Kappa::Iterator>

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $itr = $db->select_itr({ value => 'aaa' });
  while ( my $row = $itr->next ) { # $row is Row object
      ...# using Row object
  }


if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  my $itr1 = $db_for_sometable->select_itr({ value => 'aaa' }); #omit $table_name
  my $itr2 = $db_for_sometable->select_itr('SOME_TABLE', { value => 'aaa' }); #you can also specify table name 


=head2 select_named($sql, $params_href, $table_name)

run select by sql using named placeholder. 
In scalar context, return one row object. In array context, return array of row objects.

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $row = $db->select_named('SELECT id, value FROM SOME_TABLE WHERE value = :value', { value => 'aaa' });

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

  package My::Table::Class;
  sub using_select_named {
      my ($self, $id) = @_;
      return $self->select_named({ id => $id });# '@@ using_select_name' is used
  }
  1;
  __DATA__
  @@ using_select_named
  SELECT * FROM MyTable WHERE id = :id;

=head2 select_row_named($sql, $params_href, $table_name)

run select by sql using named placeholder. and return one row object.

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $row = $db->select_row_named('SELECT id, value FROM SOME_TABLE WHERE value = :value', { value => 'aaa' });

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 select_all_named($sql, $params_href, $table_name)

run select by sql using named placeholder. and return array of row objects.

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my @rows = $db->select_all_named('SELECT id, value FROM SOME_TABLE WHERE value = :value', { value => 'aaa' });

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 select_itr_named($sql, $params_href, $table_name)

run select by sql using named placeholder. and return iterator that contains row objects.
Iterator is instance of L<Kappa::Iterator>

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $itr = $db->select_itr_named('SELECT id, value FROM SOME_TABLE WHERE value = :value', { value => 'aaa' });
  while ( my $row = $itr->next ) { # $row is row object
      ... #using row object
  }

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 select_by_sql($sql, \@binds, $table_name)

run select by sql using normal placeholder('?').

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 select_row_by_sql($sql, \@binds, $table_name)

run select by sql using normal placeholder('?').

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 select_all_by_sql($sql, \@binds, $table_name)

run select by sql using normal placeholder('?').

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 select_itr_by_sql($sql, \@binds, $table_name)

run select by sql using normal placeholder('?').

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 select_with_fields($table_name, $fields_aref, $where, $option)

same as select but you can specify field name by using $fields_aref.
Note that unspecified field value is not returned in row object.


=head2 select_row_with_fields($table_name, $fields_aref, $where, $option)

same as select_row but you can specify field name by using $fields_aref.

=head2 select_all_with_fields($table_name, $fields_aref, $where, $option)

same as select_all but you can specify field name by using $fields_aref.

=head2 select_itr_with_fields($table_name, $fields_aref, $where, $option)

same as select_itr but you can specify field name by using $fields_aref.

=head2 insert($table_name, $values)

execute INSERT statment. return value is nothing.

if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  $db_for_sometable->insert({ id => 123, value => 'aaa' }); #omit $table_name


=head2 insert_multi($table_name, @args)

execute bulk insert using L<SQL::Maker>'s insert_multi. return value is nothing.

if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  $db_for_sometable->insert_multi({ id => 123, value => 'aaa' }, { id => 124, value => 'bbb' }); #omit $table_name

=head2 insert_on_duplicate($table_name, $insert_href, $update_href)

execute INSERT ... ON DUPLICATE KEY UPDATE using L<SQL::Maker>'s insert_on_duplicate. return value is nothing.

if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  $db_for_sometable->insert_on_duplicate({ id => 123, value => 'aaa' }, { value => 'bbb' }); #omit $table_name



=head2 delete($table_name, $where)

execute DELETE statment. return value is nothing.

if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  $db_for_sometable->delete({ id => 123 }); #omit $table_name


=head2 update($table_name, $set, $where)

execute UPDATE statment. return value is nothing.

if table class is defined and select is called from table class, parameter $table_name is optional. like this, 

  my $db = Kappa->new($dbh, { table_namespace => 'MyProj::Table'});
  my $db_for_sometable = $db->model('SOME_TABLE');
  $db_for_sometable->update({ value => 'aaa' }, { id => 123 }); #omit $table_name

=head2 execute_query($sql, \@binds)

run sql statement and returns statement handler($sth)

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 execute_query_named($sql, $params_href)

run sql statement with named placeholder and returns statement handler($sth)

if table class is defined and SQL is written in __DATA__ section. $sql is omittable and used method name as SQL name.

=head2 sql()

=head2 sql_from_data_section($sql_name)

fetch SQL from __DATA__ section in Table class. For example, write SQL in Table class like this

  package MyProj::Table::Order;
  use parent qw(Kappa);
  use strict;
  use warnings;

  sub select_from_order_no {
      my ($self, $order_no) = @_;
      my $sql = $self->sql_from_data_section('select_from_order_no');
      return $self->select_all_named($sql, { order_no => $order_no });
  }
  1;
  __DATA__
  
  @@ select_from_order_no
  SELECT *
    FROM Order
    WHERE order_no = :order_no
  ;

if $sql_name is omitted, method name is used by default. in this case(in select_from_order_no() method),


  my $sql = $self->sql_from_data_section('select_from_order_no');

is same as

  my $sql = $self->sql_from_data_section;

sql() is method alias to sql_from_data_section()

=head2 handle_exception($sql, $binds_aref, $err_message)

When SQL error occured, this method is call-backed. you can override this method to customize error message and error handling.


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
  my $db_for_order = $db->model('Order');
  my @rows = $db_for_order->select_using_very_complex_sql($condition_href);

=head1 DEFINE CUSTOMIZED ITERATOR

You can also define iterator class specified in iterator_namespace at new(). for example, define MyProj::Iterator::Order like this,

  package MyProj::Iterator::Order;
  use parent qw(Kappa::Iterator);
  use strict;
  use warnings;

  sub sum_price {
      my($self) = @_;
      my $result = 0;
      while ( my $row = $self->next ) {
          $result += $row->price;
      }
      return $result;
  }

using this iterator like this,

  my $db = Kappa->new($dbh, { iterator_namespace => 'MyProj::Iterator' });
  my $db_for_order = $db->model('Order');
  my $itr = $db_for_select->some_order(...);
  my $sum_price = $itr->sum_price();

If MyProj::Iterator::Order is not defined, instance of MyProj::Iterator will be returned. And if MyProj::Iterator is not
defined, Kappa::Iterator will be returned.


=head1 How to use Transaction.


When create instance using connect() method, you can use L<DBIx::Handler>'s
transaction management,

  use Kappa;
  my $db = Kappa->connect($dsn, $id, $pass);
  my $txn = $db->handler->txn_scope();
  $db->insert('SOME_TABLE', { id => 124, value => 'xxxx'} );
  $db->insert('SOME_TABLE', { id => 125, value => 'yyy'} );
  $txn->commit();

Or You can use L<DBI>'s transaction (begin_work and commit).

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
