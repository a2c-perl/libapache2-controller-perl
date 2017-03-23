package Sample::Auth;
use strict;
use warnings FATAL => 'all';

use base qw(
  Apache2::Controller
  Apache2::Request
);

use Apache2::Const -compile => qw( :http );
sub allowed_methods {qw( default )}

my $SECRET = 'foo';
use Crypt::Digest::SHA256 qw(sha256_hex);
use OpenID::Login;

my $AUTH_URL = 'http://ec2-35-167-28-203.us-west-2.compute.amazonaws.com/auth';

sub default {
    my $self = shift;
    $self->content_type('text/html');
    
    my $o = OpenID::Login->new(cgi => $self->{r}, return_to => $AUTH_URL);
    my $identity_url = $o->verify_auth();
    if ($identity_url) {
        my $email = $self->{r}->param('openid.ax.value.email');
        my $value = $email . ':' . sha256_hex( $SECRET, $email );
        Apache2::Cookie->new($self,
                             -name    =>  'LOGIN',
                             -value   =>  $value,
                             -expires =>  '+3M'
                            )->bake($self);
        
        $self->err_headers_out->add(Location => '/protected');
        return Apache2::Const::REDIRECT;
        
    } else {
        $self->print('Sad trombone.');
    }

    return Apache2::Const::HTTP_OK;
}

1;
