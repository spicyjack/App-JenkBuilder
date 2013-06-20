#!perl -T

use strict;
use warnings;
use 5.010;
use Test::More tests => 12;
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
my $project_job = $project->project_job();

isa_ok($project_job, q(App::JenkBuilder::Job));

ok($project_job->name() eq q(test-project), q(Project name matches; )
    . $project_job->name());

ok($project_job->version() eq q(1.00), q(Project version matches; )
    . $project_job->version());

ok($project->build_arch() eq q(i386), q(Project build architecture matches; )
    . $project->build_arch());

my @build_deps = @{$project->build_deps()};
ok(scalar(@build_deps) == 2, q(Project has )
    . scalar(@build_deps) . q( build dependencies));

my @test_deps = (
    App::JenkBuilder::Job->new( name => q(project-a), version => q(2.00) ),
    App::JenkBuilder::Job->new( name => q(project-b), version => q(3.00) ),
);

foreach my $dep ( @build_deps ) {
    my $test_dep = shift(@test_deps);
    ok($test_dep->name() eq $dep->name(),
        q(Job names match between test and test config file; ) . $dep->name());
    ok($test_dep->version() eq $dep->version(),
        q(Job versions match between test and test config file; )
            . $dep->version());
}

