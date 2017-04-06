package Apache2::Controller::Auth::Google::TokenHandler;
use strict;
use warnings;

=head1 NAME

Apache2::Controller::Auth::Google::TokenHandler - token handler for Google auth

=head1 DESCRIPTION

Token handler for Apache2::Controller::Auth::Google.  See
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
use OIDC::Lite::Client::WebServer;
use JSON::PP qw(decode_json);

use Apache2::Const -compile => qw( OK SERVER_ERROR REDIRECT );

use Apache2::Controller::X;

sub process {
    my $self = shift;

    my $code = $self->param('code');

    my $access_token = $self->client->get_access_token(
        code         => $code,
        redirect_uri => $self->auth_url,
    );
    if ($access_token) {

        # now fetch the user's email address to use as a username
        my $ua = LWP::UserAgent->new;
        my $req =
          HTTP::Request->new(
            GET => 'https://www.googleapis.com/plus/v1/people/me' );
        $req->header(
            Authorization => "Bearer " . $access_token->access_token );

        my $session = $self->session;

        my $res = $ua->request($req);
        if ( $res->is_success ) {
            my $profile = decode_json( $res->content );
            my $email   = $profile->{emails}[0]{value};
            $session->{user} = $email;
        }
        else {
            # we couldn't get the profile from google!
            warn $res->as_string;
            return Apache2::Const::FORBIDDEN;
        }

        $session->{logged_in} = 1;

        # now send the user on their way
        return $self->location_redirect(
                 $session->{original_destination}
              or $self->default_destination
        );

    }
    else {
        # we couldn't get an access token from google!
        warn $self->client->errstr;
        return Apache2::Const::FORBIDDEN;
    }
}

1;
