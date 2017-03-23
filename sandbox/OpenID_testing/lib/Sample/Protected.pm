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
use OpenID::Login;

my $AUTH_URL = 'http://ec2-35-167-28-203.us-west-2.compute.amazonaws.com/auth';

sub default {
    my $self = shift;

    my $jar       = Apache2::Cookie::Jar->new( $self->{r} );
    my $login     = $jar->cookies('LOGIN');
    my $logged_in = 0;
    my ($username, $hash);
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

        my $claimed_id = 'https://me.yahoo.com';
        my $o          = OpenID::Login->new(
            claimed_id => $claimed_id,
            return_to  => $AUTH_URL,
            extensions => [
                {
                    ns         => 'ax',
                    uri        => 'http://openid.net/srv/ax/1.0',
                    attributes => {
                        mode     => 'fetch_request',
                        required => 'firstname,lastname,email',
                        type     => {
                            email     => 'http://axschema.org/contact/email',
                            firstname => 'http://axschema.org/namePerson/first',
                            lastname  => 'http://axschema.org/namePerson/last',
                        }
                    }
                },
            ]
        );

        my $auth_url = $o->get_auth_url();
        $self->print(
            qq{<p><a href="$auth_url">Click here to login with Yahoo</a></p>});

        return Apache2::Const::HTTP_OK;
    }
}

1;
