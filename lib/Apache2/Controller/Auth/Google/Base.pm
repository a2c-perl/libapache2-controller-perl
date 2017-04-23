package Apache2::Controller::Auth::Google::Base;
use strict;
use warnings;

=head1 NAME

Apache2::Controller::Auth::Google::Base - internal base module for Google auth

=head1 DESCRIPTION

Internal base module for Apache2::Controller::Auth::Google classes.
See L<Apache2::Controller::Auth::Google> for details.

=head1 COPYRIGHT & LICENSE

Copyright 2017 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use base qw(Apache2::Controller::NonResponseRequest);

use English '-no_match_vars';
use Carp qw( longmess );
use Digest::SHA qw( sha256_hex );
use OIDC::Lite::Client::WebServer;
use JSON::PP qw(decode_json);

use Apache2::Const -compile => qw( OK SERVER_ERROR REDIRECT );

use Apache2::Controller::X;

sub client {
    my $self = shift;

    return $self->{client} ||= OIDC::Lite::Client::WebServer->new(
        id               => $self->client_id,
        secret           => $self->client_secret,
        authorize_uri    => 'https://accounts.google.com/o/oauth2/v2/auth',
        access_token_uri => 'https://www.googleapis.com/oauth2/v4/token',
    );
}

sub client_id {
    my $self = shift;
    return $self->{r}->dir_config('A2C_Auth_Google_Client_ID');
}

sub client_secret {
    my $self = shift;
    return $self->{r}->dir_config('A2C_Auth_Google_Client_Secret');
}

sub auth_url {
    my $self = shift;
    return $self->{r}->dir_config('A2C_Auth_Google_Token_URL');    
}

sub default_destination {
    my $self = shift;
    return $self->{r}->dir_config('A2C_Auth_Google_Default_Redirect');   
}

sub session {
    my $self = shift;
    my $session = $self->pnotes->{a2c}{session}{google_auth} ||= {};

    # make sure we're always preserving the session
    $self->pnotes->{a2c}{session_force_save} = 1;

    return $session;
}

sub is_logged_in {
    my $self = shift;
    return $self->session->{logged_in} || 0;
}

sub get_user {
    my $self = shift;
    return $self->session->{user};
}

sub location_redirect {
    my ( $self, $uri ) = @_;
    $self->err_headers_out->add( Location => $uri );
    return Apache2::Const::REDIRECT;
}

# special testing mode that doesn't talk to Google but otherwise is testable
sub test_mode {
    my $self = shift;
    return $self->{r}->dir_config('A2C_Auth_Google_Test_mode');
}

1;


