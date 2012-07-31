package Kappa::Iterator;
use parent qw(SQL::Executor::Iterator);
use strict;
use warnings;

1;
__END__

=head1 NAME

Kappa::Iterator - default iterator for Kappa

=head1 SYNOPSIS

  use Kappa;

=head1 DESCRIPTION

by default, Kappa::Iterator is the same as L<SQL::Executor::Iterator>. You can extends Kappa::Iterator and specify iterator_namespace in Kappa's constructor


=cut
