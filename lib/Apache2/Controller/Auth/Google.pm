package Apache2::Controller::Auth::Google;
use strict;
use warnings;

=head1 NAME

Apache2::Controller::Auth::Google - Google Auth for Apache2::Controller

=head1 VERSION

Version 1.001.010

=cut

use version;
our $VERSION = version->new('1.001.010');

=head1 SYNOPSIS

In your Apache server configuration:

  PerlLoadModule Apache2::Controller::Directives

  # fill in your Google OAuth client credentials 
  PerlSetVar A2C_Auth_Google_Client_ID     XXXX
  PerlSetVar A2C_Auth_Google_Client_Secret XXXX

  # set a full URL to your Apache2::Controller::Auth::Google::TokenHandler
  PerlSetVar A2C_Auth_Google_Token_URL     http://example.com/google-token

  # this is the URL the Google will rediect to with a token after
  # login, it must be configured above as A2C_Auth_Google_Token_URL
  <Location /google-token>
      SetHandler modperl
      PerlHeaderParserHandler MyApp::Session
      A2C_Session_Cookie_Opts name  myapp_sessid
      PerlResponseHandler Apache2::Controller::Auth::Google::TokenHandler
  </Location>

  # example logout functionality - you can write your own easily by
  # deleting the session
  <Location /logout>
      SetHandler modperl
      PerlHeaderParserHandler Sample::Session
      A2C_Session_Cookie_Opts name  myapp_sessid
      PerlResponseHandler Apache2::Controller::Auth::Google::LogoutHandler
  </Location>

  # example protected resource - anyone who accesses this without a
  # logged-in session will be redirected to Google to login
  <Location /protected>
      SetHandler modperl
      A2C_Session_Cookie_Opts name  myapp_sessid		
      PerlHeaderParserHandler Sample::Session
      PerlAuthenHandler Apache2::Controller::Auth::Google
      Require valid-user
  </Location>

=head1 DESCRIPTION

This module implements an authentication mechanism for
L<Apache2::Controller> that allows users to login with their Google
accounts, using Google OAuth 2.0 sypport.

To use this module you must register your application with Google and
obtain a client ID and client secret.  Please follow the steps
described here:

  https://developers.google.com/identity/protocols/OAuth2

Be sure to enable the Google+ API since this is required to retrieve
the profile of users when they login.

B<NOTE>: This module requires use of
Apache2::Controller::Session::Cookie, which is used to mark visitors
as logged in.  Please see L<Apache2::Controller::Session::Cookie> for
details.  You will need to create a sub-class of that module and
configure a database connection for it to use to store sessions.

=head1 CONFIGURATION VARIABLES

Set these using PerlSetVar in your Apache configuration.

=head2 A2C_Auth_Google_Client_ID 

Set this to your Google OAuth client ID.  When you set this up be sure
to enable the Google+ API since this is required to retrieve the
profile of users when they login.

=head2 A2C_Auth_Google_Client_Secret

Set this to your Google OAuth client secret.

=head2 A2C_Auth_Google_Default_Redirect

You can set this optional parameter to a URL which will be used if for
any reason the session does not contain a redirect URL to send the
user to after login.  Defaults to /.

=head2 A2C_Auth_Google_Token_URL

Set this to the URL of a location that is setup using
Apache2::Controller::Auth::Google::TokenHandler.  This is the URL that
Google will redirect to with a token after the user logs in.

=cut

use base qw(Apache2::Controller::Auth::Google::Base);

use English '-no_match_vars';
use Carp qw( longmess );
use Digest::SHA qw( sha256_hex );
use Net::OAuth2::Profile::WebServer;
use JSON::PP qw(decode_json);

use Apache2::Const -compile => qw( OK SERVER_ERROR REDIRECT );

use Apache2::Controller::X;

sub process {
    my $self       = shift;
    my $session    = $self->session;
    my $directives = $self->get_directives();

    # already logged in?  proceed!
    if ( $self->is_logged_in ) {
        $self->{r}->user( $self->get_user );
        return Apache2::Const::OK;
    }

    my $google_url = $self->_compute_google_auth_url(
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        auth_url      => $self->auth_url
    );

    # store the original destination in the session so we can redirect
    # there at the end
    $session->{original_destination} = $self->{r}->construct_url();
    
    return $self->location_redirect($google_url);
}

sub _compute_google_auth_url {
    my ($self, %args) = @_;
    my $client_id = $args{client_id};
    my $client_secret = $args{client_secret};
    my $auth_url = $args{auth_url};
    
    # get a URL to send the user to login, requesting profile access
    # so we can get an email
    my $google_url = Net::OAuth2::Profile::WebServer->new(
        client_id     => $client_id,
        client_secret => $client_secret,
        site          => 'https://accounts.google.com',
        scope         => q{openid }
          . q{https://www.googleapis.com/auth/plus.profile.emails.read }
          . q{profile},
        redirect_uri   => $auth_url,
        state          => sha256_hex( rand() ),
        authorize_path => '/o/oauth2/v2/auth',
    )->authorize();

    return $google_url;
}

=head1 MANUAL TESTING

To run a test of this module that hits the live Google servers (as
opposed to the default tests which use mock routines) you must do some
setup and set several evironment variables.

=over

=item 1

Go to https://console.developers.google.com/ and setup an API account
with the Google+ turned on.

=item 2

Under "Credentials" create an OAuth 2 client ID and secret.  Set the
"authorized redirect URI" to the URI of a page you can edit.  It can
be on a domain of your own on or on S3.  For example, if you run
C<sam.tregar.com> you could set it to
C<http://sam.tregar.com/google_auth_test.html>.

=item 3

Edit the file pointed at by your redirect URI and copy this code into place:

    <script language="javascript">
    var parts = location.search.substring(1).split('&');
    for (var i = 0; i < parts.length; i++) {
        var nv = parts[i].split('=');
        if (nv[0] == 'code') {
            document.write("Copy and paste this code into your test window:<br><br><b> " + nv[1] + "</b><br><br>(Note this code is only good for one run.)");
        }
    }
    </script>

=item 4

Run the test suite with three environment variables defined and using
--verbose so you can see the prompt:

  GOOGLE_AUTH_TEST_CLIENT_ID=XXXXX GOOGLE_AUTH_TEST_CLIENT_SECRET=XXXXX GOOGLE_AUTH_TEST_CLIENT_REDIRECT_URL=http://XXXX/XXXX.html ./Build test --verbose

When the test pauses and gives you instructions, follow them.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2017 Mark Hedges, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Apache2::Controller::Auth::Google

