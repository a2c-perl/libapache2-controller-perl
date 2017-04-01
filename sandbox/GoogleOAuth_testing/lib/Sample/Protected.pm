package Sample::Protected;
use strict;
use warnings FATAL => 'all';

use base qw(
  Apache2::Controller
  Apache2::Request
);

use Apache2::Const -compile => qw( :http );
sub allowed_methods { qw( default ) }

my $SECRET = 'foo';
use Crypt::Digest::SHA256 qw(sha256_hex);
use OIDC::Lite::Client::WebServer;

our $CLIENT_ID =
  '204988223104-b54ttna4r29a1dmmmoteq0m6evr8ekvc.apps.googleusercontent.com';
our $CLIENT_SECRET = '8XHaqYiKTrydhWCyEb_v4wMK';

my $AUTH_URL = 'http://ec2-35-167-28-203.us-west-2.compute.amazonaws.com/auth';

sub default {
    my $self = shift;

    my $jar       = Apache2::Cookie::Jar->new( $self->{r} );
    my $login     = $jar->cookies('LOGIN');
    my $logged_in = 0;
    my ( $username, $hash );
    if ($login) {
        ( $username, $hash ) = split( ':', $login->value );
        if ( sha256_hex( $SECRET, $username ) eq $hash ) {
            $logged_in = 1;
        }
    }

    if ($logged_in) {
        $self->content_type('text/html');
        $self->print("You made it - welcome to the protected page $username!");
        return Apache2::Const::HTTP_OK;
    }
    else {
        $self->content_type('text/html');
        $self->print("<h1>You're not logged in.</h1>");

        my $client = OIDC::Lite::Client::WebServer->new(
            id               => $CLIENT_ID,
            secret           => $CLIENT_SECRET,
            authorize_uri    => 'https://accounts.google.com/o/oauth2/v2/auth',
            access_token_uri => 'https://accounts.google.com/o/oauth2/v4/token'
        );
        my $auth_url = $client->uri_to_redirect(
            redirect_uri => $AUTH_URL,
            scope        => q{openid https://www.googleapis.com/auth/plus.profile.emails.read profile},
            state        => sha256_hex( rand() ),
        );

        $self->print(
            qq{<p><a href="$auth_url">Click here to login with Google</a></p>}
        );

        return Apache2::Const::HTTP_OK;
    }
}

1;
