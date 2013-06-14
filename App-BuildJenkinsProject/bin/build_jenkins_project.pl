#!/usr/bin/perl -w

# Copyright (c) 2013 by Brian Manning <cpan at xaoc dot org>

# For support with this file, please file an issue on the GitHub issue tracker
# for this project:
# https://github.com/spicyjack/App-BuildJenkinsProject/issues

=head1 NAME

B<build_jenkins_project.pl> - A Perl script template that uses the
L<Log::Log4perl> logging module.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

 perl build_jenkins_project.pl [OPTIONS]

 Script options:
 -v|--verbose       Verbose script execution
 -h|--help          Shows this help text

 Other script options:
 -c|--job-config    Path to config file that describes Jenkins job to run
 -s|--host|--server Hostname of the Jenkins server
 -j|--job           Jenkins job to interact with
 -u|--http-user     HTTP Authentication user
 -p|--http-pass     HTTP Authentication password
 --poll-duration    Poll the Jenkins API for job status at this interval

 Example usage:

 # build a Jenkins project based on the contents of 'config.txt'
 build_jenkins_project.pl --job-config /path/to/config.ini

 # same, but handle HTTP authentication
 build_jenkins_project.pl --http-user=foo --http-pass=bar \
    --job-config /path/to/config.ini

You can view the full C<POD> documentation of this file by calling C<perldoc
build_jenkins_project.pl>.

=cut

our @options = (
    # script options
    q(verbose|v+),
    q(help|h),
    q(colorize),
    # other options
    q(job-config|c=s),
    q(job|j=s),
    q(host|server|s=s),
    q(http-user|u=s),
    q(http-pass|p=s),
    q(poll-duration=i),
);

=head1 DESCRIPTION

B<build_jenkins_project.pl> - A Perl script template that uses the
L<Log::Log4perl> logging module.

=head1 OBJECTS

=head2 BuildJenkinsProject::Project

An object used for storing Jenkins job data.  Inherits common functions from
L<BuildJenkinsProject::Project>.

=head3 Object Methods

=cut

##################################
# BuildJenkinsProject::Project #
##################################
package BuildJenkinsProject::Project;
use strict;
use warnings;
use Config::Std;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
@ISA=qw(BuildJenkinsProject::Config);

=over

=item new( )

Creates the L<BuildJenkinsProject::Project> object, and parses the job
configuration file.

=cut

sub new {
    my $class = shift;
    my $self = bless ({}, $class);
    my $log = get_logger();


}

=head2 BuildJenkinsProject::Config

An object used for storing configuration data.

=head3 Object Methods

=cut

###############################
# BuildJenkinsProject::Config #
###############################
package BuildJenkinsProject::Config;
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use POSIX qw(strftime);

=over

=item new( )

Creates the L<BuildJenkinsProject::Config> object, and parses out options using
L<Getopt::Long>.

=cut

sub new {
    my $class = shift;

    my $self = bless ({}, $class);

    # script arguments
    my %args;

    # parse the command line arguments (if any)
    my $parser = Getopt::Long::Parser->new();

    # pass in a reference to the args hash as the first argument
    $parser->getoptions( \%args, @options );

    # assign the args hash to this object so it can be reused later on
    $self->{_args} = \%args;

    # dump and bail if we get called with --help
    if ( $self->get(q(help)) ) { pod2usage(-exitstatus => 1); }

    # return this object to the caller
    return $self;
}

=item get($key)

Returns the scalar value of the key passed in as C<key>, or C<undef> if the
key does not exist in the L<BuildJenkinsProject::Config> object.

=cut

sub get {
    my $self = shift;
    my $key = shift;
    # turn the args reference back into a hash with a copy
    my %args = %{$self->{_args}};

    if ( exists $args{$key} ) { return $args{$key}; }
    return undef;
}

=item set( key => $value )

Sets in the L<BuildJenkinsProject::Config> object the key/value pair passed in
as arguments.  Returns the old value if the key already existed in the
L<BuildJenkinsProject::Config> object, or C<undef> otherwise.

=cut

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    # turn the args reference back into a hash with a copy
    my %args = %{$self->{_args}};

    if ( exists $args{$key} ) {
        my $oldvalue   = $args{$key};
        $args{$key}    = $value;
        $self->{_args} = \%args;
        return $oldvalue;
    } else {
        $args{$key}    = $value;
        $self->{_args} = \%args;
    } # if ( exists $args{$key} )
    return undef;
}

=item get_args( )

Returns a hash containing the parsed script arguments.

=cut

sub get_args {
    my $self = shift;
    # hash-ify the return arguments
    return %{$self->{_args}};
}

=item defined($key)

Returns "true" (C<1>) if the value for the key passed in as C<key> is
C<defined>, and "false" (C<0>) if the value is undefined, or the key doesn't
exist.

=cut

sub defined {
    my $self = shift;
    my $key = shift;
    # turn the args reference back into a hash with a copy
    my %args = %{$self->{_args}};

    if ( exists $args{$key} ) {
        if ( defined $args{$key} ) {
            return 1;
        }
    }
    return 0;
}

=back

=cut

################
# package main #
################
package main;
use 5.010;
use strict;
use warnings;
use utf8;
use Carp;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;
use HTTP::Headers;
use HTTP::Status qw(:constants); # provides HTTP_* constants
use JSON;
use LWP::UserAgent;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Log::Log4perl::Level;
use Net::Jenkins;

    binmode(STDOUT, ":utf8");
    my $config = BuildJenkinsProject::Config->new();

    # set a default poll interval of 5 seconds
    if ( ! $config->defined(q(poll-interval)) ) {
        $config->set(q(poll-interval) => 5);
    }

    my $job_config;
    if ( $config->defined(q(job-config)) ) {
        $job_config = BuildJenkinsProject::Project->new();
    }
    # set up the logger
    my $log_conf;
    if ( defined $config->get(q(verbose)) && $config->get(q(verbose)) > 1 ) {
        $log_conf = qq(log4perl.rootLogger = DEBUG, Screen\n);
    } elsif ( $config->get(q(verbose)) && $config->get(q(verbose)) == 1) {
        $log_conf = qq(log4perl.rootLogger = INFO, Screen\n);
    } else {
        $log_conf = qq(log4perl.rootLogger = WARN, Screen\n);
    }
    if ( -t STDOUT || $config->get(q(colorize)) ) {
        $log_conf .= qq(log4perl.appender.Screen = )
            . qq(Log::Log4perl::Appender::ScreenColoredLevels\n);
    } else {
        $log_conf .= qq(log4perl.appender.Screen = )
            . qq(Log::Log4perl::Appender::Screen\n);
    } # if ( $Config->get(q(o_colorlog)) )

    $log_conf .= qq(log4perl.appender.Screen.stderr = 1\n)
        . qq(log4perl.appender.Screen.utf8 = 1\n)
        . qq(log4perl.appender.Screen.layout = PatternLayout\n)
        . q(log4perl.appender.Screen.layout.ConversionPattern )
        . qq|= %d{HH.mm.ss} %p %L (%M{1}) %m%n\n|;
        #. qq|= %d{HH.mm.ss} %p %F{1}:%L (%M{1}) %m%n\n|;
    # create a logger object, and prime the logfile for this session
    Log::Log4perl::init( \$log_conf );
    my $log = get_logger("");

    # print a nice banner
    $log->info(qq(Starting build_jenkins_project.pl, version $VERSION));
    $log->info(qq(My PID is $$));

    my $jenkins_url_scheme = q(http);
    my $jenkins_host       = q(www.exmaple.com);
    my $jenkins_port       = 8080;
    my $jenkins_path       = q(/jenkins);


    if ( $config->defined(q(host)) ) {
        my $munge_url = $config->get(q(host));
        $log->debug(qq(original URL: $munge_url));
        my $web_url_regex = qr|^(https?)://([\w.-]+):?([0-9]+){0,5}/?(.*)$|;
        $munge_url =~ /$web_url_regex/;
        $jenkins_url_scheme = $1;
        $jenkins_host = $2;
        # set port if defined...
        if ( defined $3 ) {
            $jenkins_port = $3;
        # use 443 if port is not already defined
        } elsif ( $jenkins_url_scheme eq q(https) ) {
            $jenkins_port = 443;
        }
        $jenkins_path = $4;
        if ( $log->is_debug ) {
            $log->debug(qq(scheme: $jenkins_url_scheme));
            $log->debug(qq(host: $jenkins_host));
            $log->debug(qq(port: $jenkins_port));
            $log->debug(qq(path: $jenkins_path));
        }
    } else {
        $log->warn(qq(Script will use the default Jenkins URL!));
        $log->warn(qq(If this isn't what you want, use the --host switch));
        $log->warn(qq(to pass a different URL in to this script));
    }
    my $jenkins_url = $jenkins_url_scheme . q(://) . $jenkins_host
        . q(:) . $jenkins_port . q(/) . $jenkins_path;
    $log->debug(qq(Recombined Jenkins URL: $jenkins_url));

    my $json = JSON->new();
    my $jenkins = Net::Jenkins->new(
        scheme          => $jenkins_url_scheme,
        host            => $jenkins_host,
        port            => $jenkins_port,
        jenkins_path    => $jenkins_path,
    );

    $log->debug(q(Created Jenkins object with base_url: )
        . $jenkins->get_base_url);
    # do we need to set credentials?
    my $http_headers;
    if ( $config->defined(q(http-user)) && $config->defined(q(http-pass)) ) {
        $log->debug(q(Creating HTTP::Headers object));
        $log->debug(q(HTTP user: ) . $config->get(q(http-user)));
        $log->debug(q(HTTP pass: ) . $config->get(q(http-pass)));
        $http_headers = HTTP::Headers->new;
        $http_headers->authorization_basic(
            $config->get(q(http-user)),
            $config->get(q(http-pass)),
        );
    }

    # if we have custom headers, add them to the LWP::UA object attribute in
    # the $jenkins object
    if ( defined $http_headers ) {
        my $ua = $jenkins->user_agent;
        $ua->default_headers($http_headers);
        $jenkins->user_agent($ua);
    }

    # run a summary, to test connectivity, and to get the current version of
    # Jenkins
    my $summary = $jenkins->summary();
    # FIXME $summary will be undef if the request failed; check for it
    $log->warn(qq(Jenkins is online... Jenkins version: )
        . $jenkins->jenkins_version);
    my $jenkins_job = Net::Jenkins::Job->new(
        api     => $jenkins,
        name    => $config->get(q(job)),
        url     => $jenkins->job_url($config->get(q(job))),
    );
    $log->warn(qq(Retrieving job info from server;));
    $log->warn(q( - ) .  $jenkins_job->url() );
    my $next_build_num = $jenkins_job->next_build_number();
    $log->warn($config->get(q(job)) . qq(: Next build number: $next_build_num));

    my $post_json = <<'EOJ';
    {"parameter": [
        {"name": "PKG_NAME", "value": "chocolate-doom"},
        {"name": "PKG_VERSION", "value": "1.7.0"},
        {"name": "TARBALL_DIR", "value": "$HOME/source"}
    ]}
EOJ

    my $response = $jenkins->post_url(
        $jenkins->job_url($config->get(q(job))
            . q(/buildWithParameters?delay=0sec),
        json => $post_json),
    );
    if ( $response->code == HTTP_FOUND ) { # HTTP 302
        $log->warn($config->get(q(job)) . q(: Job submission successful!));
        $log->warn($config->get(q(job)) . q(: Waiting for job to start...));
        if ( length($response->decoded_content()) > 0 ) {
            print Dumper $response->decoded_content();
        }
    } else {
        $log->logdie($response->status_line);
    }

    # Dump the first JSON response after the job is running
    my $job_started = 0;
    my $job_running_time = 0;
    JOB_STATUS: while (1) {
        # get the JSON message with the running job's details
        my $job_status_json = $jenkins->get_job_details(
            $config->get(q(job)) . qq(/$next_build_num)
        );
        if ( defined $job_status_json ) {
            my %job_status = %{$job_status_json};
            my $job_result = $job_status{result};
            my $job_number = $job_status{number};
            if ( defined $job_result ) {
                $log->warn($config->get(q(job))
                    . qq(: Job #$job_number complete; )
                    . qq(result: $job_result));
                # in milliseconds apparently
                my $job_duration = $job_status{estimatedDuration} / 1000;
                my ($duration_min, $duration_sec, $duration_string);
                if ( $job_duration > 60 ) {
                    $duration_min = int($job_duration / 60);
                    $duration_sec = int($job_duration - ($duration_min * 60));
                    $duration_string = "minutes";
                } else {
                    $duration_min = 0;
                    $duration_sec = $job_duration;
                    $duration_string = "seconds";
                }
                $log->warn($config->get(q(job)) . q(: Job duration: )
                     . $duration_min . q(m )
                     . $duration_sec . q(s));
                last JOB_STATUS;
            } else {
                if ( ! $job_started ) {
                    $log->warn($config->get(q(job))
                        . qq(: Job #$job_number has started!));
                    if ( $log->is_debug ) {
                        $log->debug(Dumper $job_status_json);
                    }
                }
                $job_started = 1;
                $log->info($config->get(q(job)) .
                    qq|: Job #$job_number running (Elapsed: |
                    . sprintf('% 3u', $job_running_time)
                    . q|s)|);
            }
        } else {
            $log->info($config->get(q(job)) . q(: Job has not started yet...));
        }
        sleep $config->get(q(poll-interval));
        $job_running_time += $config->get(q(poll-interval));
        # do API requests here at intervals, and check 'result'
        # https://jenkurl/jenkins/view/Doom/job/prboom/4/api/json?pretty=true
        #last JOB_STATUS;
    }

=head1 AUTHOR

Brian Manning, C<< <cpan at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker for
this project:

C<< <https://github.com/spicyjack/App-BuildJenkinsProject/issues> >>

=head1 SUPPORT

You can find documentation for this script with the perldoc command.

    perldoc build_jenkins_project.pl

=head1 COPYRIGHT & LICENSE

Copyright (c) 2013 Brian Manning, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# fin!
# vim: set shiftwidth=4 tabstop=4
