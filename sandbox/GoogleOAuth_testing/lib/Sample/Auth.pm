package Sample::Auth;
use strict;
use warnings FATAL => 'all';

use base qw(
  Apache2::Controller
  Apache2::Request
);

use Apache2::Const -compile => qw( :http );
sub allowed_methods { qw( default ) }

use OIDC::Lite::Client::WebServer;

our $CLIENT_ID =
  '204988223104-b54ttna4r29a1dmmmoteq0m6evr8ekvc.apps.googleusercontent.com';
our $CLIENT_SECRET = '8XHaqYiKTrydhWCyEb_v4wMK';

my $AUTH_URL = 'http://ec2-35-167-28-203.us-west-2.compute.amazonaws.com/auth';

use Crypt::Digest::SHA256 qw(sha256_hex);

sub default {
    my $self = shift;
    $self->content_type('text/html');

    my $client = OIDC::Lite::Client::WebServer->new(
        id               => $CLIENT_ID,
        secret           => $CLIENT_SECRET,
        authorize_uri    => 'https://accounts.google.com/o/oauth2/v2/auth',
        access_token_uri => 'https://www.googleapis.com/oauth2/v4/token',
    );

    my $code         = $self->param('code');

    my $access_token = $client->get_access_token(
        code         => $code,
        redirect_uri => $AUTH_URL,
    ) or print STDERR $client->errstr;

    if ($access_token) {
        die("GET EMAIL HERE");

        #        my $email = 'foo';
        #        my $value = $email . ':' . sha256_hex( $SECRET, $email );
        #        Apache2::Cookie->new(
        #            $self,
        #            -name    => 'LOGIN',
        #            -value   => $value,
        #            -expires => '+3M'
        #        )->bake($self);

        $self->err_headers_out->add( Location => '/protected' );
        return Apache2::Const::REDIRECT;
    }
    else {
        $self->print('Sad trombone.');
    }

    return Apache2::Const::HTTP_OK;
}

1;
