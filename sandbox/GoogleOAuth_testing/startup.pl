#!/usr/bin/env perl
use lib '/home/sam/sample-site/lib';
use lib '/home/sam/libapache2-controller-perl/lib';

use Apache2::Request;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Cookie;
use Apache2::RequestIO;
use Apache2::Module;

use Apache2::Controller;
use Apache2::Controller::Directives;
use Apache2::Controller::Dispatch::Simple;

use Sample::App;

print "INC: " . join(", ", @INC) . "\n";

