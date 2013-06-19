#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

BEGIN {
    use_ok(q(App::JenkBuilder::Job) ) || print "Bail out!\n";
    use_ok(q(File::Basename));
}

diag( "Testing App::JenkBuilder::Job "
    . "$App::JenkBuilder::Job::VERSION, Perl $], $^X" );

my $job = App::JenkBuilder::Job->new();
isa_ok($job, q(App::JenkBuilder::Job));

$job = App::JenkBuilder::Job->new(
    name    => q(foo),
    version => q(bar),
);

ok($job->name eq q(foo), q(Job name is 'foo'));
ok($job->version eq q(bar), q(Job version is 'bar'));
