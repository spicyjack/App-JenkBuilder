#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

BEGIN {
    use_ok(q(App::JenkBuilder::Project) ) || print "Bail out!\n";
    use_ok(q(File::Basename));
}

diag( "Testing App::JenkBuilder::Project "
    . "$App::JenkBuilder::Project::VERSION, Perl $], $^X" );

my $project = App::JenkBuilder::Project->new();
isa_ok($project, q(App::JenkBuilder::Project));
my $config_dir = dirname($0);
# load test file
my $config_ref = $project->load(config_file => qq($config_dir/config-11.ini));
my %config = %{$config_ref};
my @keys = keys(%config);
ok(exists $config{PROJECT}, q('PROJECT' section exists in config file));
if ( exists $config{PROJECT} ) {
    my $project = $config{PROJECT};
    print Dumper $project;
}

