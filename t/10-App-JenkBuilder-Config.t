#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::JenkBuilder' ) || print "Bail out!
";
}

diag( "Testing App::JenkBuilder $App::JenkBuilder::VERSION, Perl $], $^X" );
