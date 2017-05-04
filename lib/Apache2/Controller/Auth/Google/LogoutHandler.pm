package Apache2::Controller::Auth::Google::LogoutHandler;
use strict;
use warnings;

=head1 NAME

Apache2::Controller::Auth::Google::LogoutHandler - logout handler for Google auth

=head1 DESCRIPTION

Logout handler for Apache2::Controller::Auth::Google.  See
L<Apache2::Controller::Auth::Google> for details.

=head1 COPYRIGHT & LICENSE

Copyright 2017 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use base qw(Apache2::Controller::Auth::Google::Base);

use English '-no_match_vars';
use Carp qw( longmess );
use Digest::SHA qw( sha256_hex );
use JSON::PP qw(decode_json);

use Apache2::Const -compile => qw( OK SERVER_ERROR REDIRECT );

use Apache2::Controller::X;

sub process {
    my $self = shift;
    $self->session->{logged_in} = 0;
    $self->session->{user}      = undef;
    return $self->location_redirect(
             $self->param('redirect')
          or $self->default_destination
    );
}

1;
