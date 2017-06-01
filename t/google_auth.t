use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET POST);
use FindBin;
use Data::Dumper;

use lib "$FindBin::Bin/lib";
use Apache2::Controller::Test::Funk qw( diag );

plan tests => 8;

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
