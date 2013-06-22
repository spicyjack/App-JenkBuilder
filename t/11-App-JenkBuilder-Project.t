#!perl -T

use strict;
use warnings;
use 5.010;
use Test::More tests => 11;
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
$project->load(config_file => qq($config_dir/config-11.ini));
my %project = %{$project->_project_config()};

ok($project->build_arch() eq q(i386), q(Project build architecture matches; )
    . $project->build_arch());

my @jobs = @{$project->jobs()};
ok(scalar(@jobs) == 3, q(Test project has ) . scalar(@jobs) . q( jobs));

# these are the deps that are in the test file (config-11.ini)
my @test_jobs = (
    App::JenkBuilder::Job->new( name => q(project-a), version => q(2.00) ),
    App::JenkBuilder::Job->new( name => q(project-b), version => q(3.00) ),
    App::JenkBuilder::Job->new( name => q(test-project), version => q(1.00) ),
);

foreach my $job ( @jobs ) {
    my $test_job = shift(@test_jobs);
    ok($test_job->name() eq $job->name(),
        q(Job names match between test and test config file; ) . $job->name());
    ok($test_job->version() eq $job->version(),
        q(Job versions match between test and test config file; )
            . $job->version());
}

