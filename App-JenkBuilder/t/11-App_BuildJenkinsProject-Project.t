#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::JenkBuilder::Project' ) || print "Bail out!
";
}

diag( "Testing App::JenkBuilder::Project"
    "$App::JenkBuilder::Project::VERSION, Perl $], $^X" );
