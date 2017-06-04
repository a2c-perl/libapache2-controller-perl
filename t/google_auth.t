use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET POST);
use FindBin;
use Data::Dumper;

use lib "$FindBin::Bin/lib";
use Apache2::Controller::Test::Funk qw( diag );

if ($ENV{GOOGLE_AUTH_TEST_CLIENT_ID} and
    $ENV{GOOGLE_AUTH_TEST_CLIENT_SECRET} and
    $ENV{GOOGLE_AUTH_TEST_REDIRECT_URL}) {
    plan tests => 9;
} else {
    plan tests => 8;
}

# need to look at redirects, not follow them and we'll need cookies
Apache::TestRequest::user_agent(reset => 1,
                                requests_redirectable => 0,
                                cookie_jar => {});

# should get sent to google to login
my $url = "/protected";
my $resp = GET $url;
ok($resp->code == 302);
ok($resp->content =~ /accounts\.google\.com/);

# in the usual flow this is where the human is redirected to google
# and they login and come back to us, but humans are so hard to
# automate so we'll fake it here
$url = "/auth?code=FAKE";
$resp = GET $url;
ok($resp->code == 302);

# now we should be able to get the protected content
$url = "/protected";
$resp = GET $url;
ok($resp->code == 200);
ok($resp->content =~ /Hello\s+there\s+.*You\s+are\s+logged\s+in/);

# and we should be able to logout
sleep 2;
$url = "/logout";
$resp = POST $url;
ok($resp->code == 302);

# which means we can't get that sweet protected content anymore, alas
sleep 2;
$url = "/protected";
$resp = GET $url;
ok($resp->code == 302);
ok($resp->content =~ /accounts\.google\.com/);

# if we've got test creds, we can get a real code and do a full
# coverage test
if ($ENV{GOOGLE_AUTH_TEST_CLIENT_ID} and
    $ENV{GOOGLE_AUTH_TEST_CLIENT_SECRET} and
    $ENV{GOOGLE_AUTH_TEST_REDIRECT_URL}) {

    use Apache2::Controller::Auth::Google;
    my $url = Apache2::Controller::Auth::Google->_compute_google_auth_url(
        client_id     => $ENV{GOOGLE_AUTH_TEST_CLIENT_ID},
        client_secret => $ENV{GOOGLE_AUTH_TEST_CLIENT_SECRET},
        auth_url      => $ENV{GOOGLE_AUTH_TEST_REDIRECT_URL}
    );

    print <<END;
Open this URL in your browser and login via Google to continue the test:

$url

When you are ready to continue, enter the code here and press Return:
END
    my $code = <STDIN>;
    chomp($code);

    unless (length $code) {
        print <<END;
Sorry, you need to login through Google and get a code to continue.
Please see the Apache2::Controller::Auth::Google POD for details.
END
    } else {
        # try using a real code, should work!
        $url = "/auth?code=$code&test_auth_url=$ENV{GOOGLE_AUTH_TEST_REDIRECT_URL}";
        $resp = GET $url;
        ok($resp->code == 302);
    }
}
