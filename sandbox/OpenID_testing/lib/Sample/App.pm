package Sample::App;
use strict;
use warnings FATAL => 'all';

use base qw(
  Apache2::Controller
  Apache2::Request
);

use Apache2::Const -compile => qw( :http );
sub allowed_methods {qw( default )}

sub default {
    my $self = shift;
    $self->content_type('text/html');
    $self->print("Hello there.  <a href='protected'>Perhaps you'd like to visit this protected page?</a>");
    return Apache2::Const::HTTP_OK;
}

1;

