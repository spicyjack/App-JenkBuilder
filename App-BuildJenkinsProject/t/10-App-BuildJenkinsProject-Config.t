#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::BuildJenkinsProject' ) || print "Bail out!
";
}

diag( "Testing App::BuildJenkinsProject $App::BuildJenkinsProject::VERSION, Perl $], $^X" );
