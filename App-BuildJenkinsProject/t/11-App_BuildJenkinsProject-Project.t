#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::BuildJenkinsProject::Project' ) || print "Bail out!
";
}

diag( "Testing App::BuildJenkinsProject::Project"
    "$App::BuildJenkinsProject::Project::VERSION, Perl $], $^X" );
