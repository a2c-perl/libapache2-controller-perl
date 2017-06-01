package TestApp::Simple::Dispatch;
use strict;
use warnings;

use base 'Apache2::Controller::Dispatch::Simple';

sub dispatch_map {
    return { 'default' => 'TestApp::Simple::C::Top' }
}

1;
