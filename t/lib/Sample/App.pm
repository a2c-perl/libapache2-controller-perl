package Sample::App;
use strict;
use warnings FATAL => 'all';

use base qw(
  Apache2::Controller
  Apache2::Request
);

use Apache2::Const -compile => qw( :http );
sub allowed_methods { qw( default ) }

use Data::Dumper;

sub default {
    my $self = shift;
    $self->content_type('text/html');
    $self->print(
        "<p>Hello there " . $self->{r}->user . ".  You are logged in!</p>" );
    $self->print("<p><a href='/logout'>Logout</a></p>");

    return Apache2::Const::HTTP_OK;
}

1;

