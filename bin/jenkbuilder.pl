#!/usr/bin/perl -w

# Copyright (c) 2013 by Brian Manning <cpan at xaoc dot org>

# For support with this file, please file an issue on the GitHub issue tracker
# for this project:
# https://github.com/spicyjack/App-JenkBuilder/issues

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
 -s|--host          URL of the Jenkins server to interact with
 -p|--project       Project file with a list of Jenkins job(s) to run
 -j|--job           Single Jenkins job to run (without build params)
 -u|--http-user     HTTP Authentication user
 -a|--http-pass     HTTP Authentication password
 --poll-duration    Poll the Jenkins API for job status at this interval

 Example usage:

 # build a Jenkins project based on the contents of 'config.txt'
 build_jenkins_project.pl --project /path/to/project.ini \
   --host http://www.example.com/jenkins

 # same, but handle HTTP authentication
 build_jenkins_project.pl --http-user=foo --http-pass=bar \
    --project /path/to/project.ini --host http://www.example.com/jenkins

 # build a single Jenkins job
 build_jenkins_project.pl --host http://www.example.com/jenkins \
   --job <job name>

You can view the full C<POD> documentation of this file by calling C<perldoc
build_jenkins_project.pl>.

=cut

our @options = (
    # script options
    q(debug),
    q(verbose),
    q(help|h),
    q(colorize),
    # other options
    q(project|p=s),
    q(job|j=s),
    q(host|s=s),
    q(http-user|u=s),
    q(http-pass|a=s),
    q(poll-duration=i),
);

=head1 DESCRIPTION

B<build_jenkins_project.pl> - A Perl script template that uses the
L<Log::Log4perl> logging module.

=head1 OBJECTS

=head2 JenkBuilder::Config

An object used for storing configuration data.

=head3 Object Methods

=cut

#######################
# JenkBuilder::Config #
#######################
package JenkBuilder::Config;
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use POSIX qw(strftime);

=over

=item new( )

Creates the L<JenkBuilder::Config> object, and parses out options using
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
key does not exist in the L<JenkBuilder::Config> object.

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

Sets in the L<JenkBuilder::Config> object the key/value pair passed in
as arguments.  Returns the old value if the key already existed in the
L<JenkBuilder::Config> object, or C<undef> otherwise.

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

# system modules
use Carp;
use File::Basename;
use HTTP::Headers;
use HTTP::Status qw(:constants); # provides HTTP_* constants
use JSON;
use LWP::UserAgent;
use Log::Log4perl qw(get_logger :no_extra_logdie_message);
use Log::Log4perl::Level;
use Net::Jenkins;
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

# local modules
use App::JenkBuilder::Job;
use App::JenkBuilder::Project;

    my $script_start_time = [gettimeofday];
    binmode(STDOUT, ":utf8");
    our $my_name = basename $0;
    my $config = JenkBuilder::Config->new();

    # set a default poll interval of 5 seconds
    if ( ! $config->defined(q(poll-interval)) ) {
        $config->set(q(poll-interval) => 5);
    }

    # set up the logger
    my $log_conf;
    if ( $config->defined(q(debug)) ) {
        $log_conf = qq(log4perl.rootLogger = DEBUG, Screen\n);
    } elsif ( $config->defined(q(verbose)) ) {
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

    if ( $config->defined(q(job)) && $config->defined(q(project)) ) {
        $log->logdie(q(Must use either --job or --project, not both));
    } elsif ( ! $config->defined(q(job)) && ! $config->defined(q(project)) ) {
        $log->logdie(q(Script requires either --job or --project));
    }

    # print a nice banner
    $log->info(qq($my_name: Starting, version $VERSION));
    $log->info(qq($my_name: My PID is $$));

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
    if ( ! defined $summary ) {
        $log->fatal(q(Jenkins summary request failed ));
        $log->fatal(q(Server response was: ) . $jenkins->request_error);
        $log->logdie(q|(Can't connect to Jenkins server)|);
    }
    $log->warn(qq($my_name: Jenkins is online... Jenkins version: )
        . $jenkins->jenkins_version);

    my @build_jobs;
    if ( $config->defined(q(project)) ) {
        my $project = App::JenkBuilder::Project->new();
        $project->load(config_file => $config->get(q(project)));
        @build_jobs = @{$project->jobs};
    } else {
        my $build_job = App::JenkBuilder::Job->new(
            name => $config->get(q(job)));
        push(@build_jobs, $build_job);
    }

    if ( $log->is_debug() ) {
        foreach my $debug_job (@build_jobs) {
            if ( defined $debug_job->version ) {
                $log->debug(q(Job: ) . $debug_job->name
                    . q(, version: ) . $debug_job->version);
            } else {
                $log->debug(q(Job: ) . $debug_job->name . q(, no version));
            }
        }
    }

    foreach my $build_job ( @build_jobs ) {
        my $job_name = $build_job->name;
        my $jenkins_job = Net::Jenkins::Job->new(
            api     => $jenkins,
            name    => $build_job->name(),
            url     => $jenkins->job_url($build_job->name),
        );
        $log->warn(qq($my_name: Retrieving job info from server;));
        $log->warn(qq($my_name: - ) .  $jenkins_job->url() );
        my $next_build_num = $jenkins_job->next_build_number;
        $log->warn(qq($job_name: Next build number: $next_build_num));

        # set up the JSON parameters string
        # if the version for this job is not specified, don't add it to the
        # JSON
        # FIXME also need to figure out how to handle architecture
        if ( defined $build_job->version ) {
            my $post_json = q({"parameter": [);
            $post_json .= q({"name": "PKG_VERSION", "value": ")
                . $build_job->version . q("},);
            $post_json .= q(]});

=begin SAMPLE

# sample JSON parameter list
{"parameter": [
    {"name": "PKG_NAME", "value": "chocolate-doom"},
    {"name": "PKG_VERSION", "value": "1.7.0"},
    {"name": "TARBALL_DIR", "value": "$HOME/source"}
]}

=end SAMPLE

=cut

            my $response = $jenkins->post_url(
                $jenkins->job_url(
                $job_name . q(/buildWithParameters?delay=0sec),
                json => $post_json),
            );
            if ( $response->code == HTTP_FOUND ) { # HTTP 302

                if ( length($response->decoded_content()) > 0 ) {
                    print Dumper $response->decoded_content();
                }
            } else {
                $log->logdie($response->status_line);
            }
        } else {
            if ( ! $jenkins->build_job_with_parameters($job_name) ) {
                $log->logdie(qq(Job submission $job_name failed!));
            }
        }

        $log->warn(qq($job_name: Job submission successful!));
        $log->warn(qq($job_name: Waiting for job to start...));

        # Dump the first JSON response after the job is running
        my $job_started = 0;
        my $job_running_time = 0;
        JOB_STATUS: while (1) {
            # get the JSON message with the running job's details
            my $job_status_json = $jenkins->get_job_details(
                $job_name . qq(/$next_build_num)
            );
            if ( defined $job_status_json ) {
                my %job_status = %{$job_status_json};
                my $job_result = $job_status{result};
                my $job_number = $job_status{number};
                if ( defined $job_result ) {
                    if ( $job_result =~ /SUCCESS/ ) {
                        $log->warn(qq($job_name: Job #$job_number complete; )
                            . qq(result: $job_result));
                    } else {
                        $log->logdie(qq($job_name: Job #$job_number complete; )
                            . qq(result: $job_result));
                    }
                    # in milliseconds apparently
                    my $job_duration = $job_status{estimatedDuration} / 1000;
                    my ($duration_min, $duration_sec, $duration_string);
                    if ( $job_duration > 60 ) {
                        $duration_min = int($job_duration / 60);
                        $duration_sec = int($job_duration
                            - ($duration_min * 60));
                        $duration_string = "minutes";
                    } else {
                        $duration_min = 0;
                        $duration_sec = $job_duration;
                        $duration_string = "seconds";
                    }
                    $log->warn($job_name . q(: Job duration: )
                         . $duration_min . q(m )
                         . $duration_sec . q(s));
                    last JOB_STATUS;
                } else {
                    # display this once, then set $job_started
                    if ( ! $job_started ) {
                        $log->warn($job_name
                            . qq(: Job #$job_number has started!));
                        if ( $log->is_debug ) {
                            $log->debug(Dumper $job_status_json);
                        }
                    }
                    $job_started = 1;
                    $log->info($job_name .
                        qq|: Job #$job_number running (Elapsed: |
                        . sprintf('% 3u', $job_running_time)
                        . q|s)|);
                }
            } else {
                $log->info(qq($job_name: Job has not started yet...));
            }
            sleep $config->get(q(poll-interval));
            $job_running_time += $config->get(q(poll-interval));
        }
    }
    $log->warn(qq($my_name: Successfully built ) . scalar(@build_jobs)
        . q( jobs));
    $log->warn(qq($my_name: in ) . sprintf(q(%0.1f),
            tv_interval($script_start_time, [gettimeofday])) . q( seconds));

=head1 AUTHOR

Brian Manning, C<< <cpan at xaoc dot org> >>

=head1 BUGS

Please report any bugs or feature requests to the GitHub issue tracker for
this project:

C<< <https://github.com/spicyjack/App-JenkBuilder/issues> >>

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
