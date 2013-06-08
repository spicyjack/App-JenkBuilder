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
 -c|--config        Path to config file that describes Jenkins job to run
 -s|--host|--server Hostname of the Jenkins server
 -j|--job           Jenkins job to query/build
 -u|--http-user     HTTP Authentication user
 -p|--http-pass     HTTP Authentication password

 Example usage:

 # build a Jenkins project based on the contents of 'config.txt'
 build_jenkins_project.pl --config /path/to/config.txt

 # same, but handle HTTP authentication
 build_jenkins_project.pl --http-user=foo --http-pass=bar \
    --config /path/to/config.txt

You can view the full C<POD> documentation of this file by calling C<perldoc
build_jenkins_project.pl>.

=cut

our @options = (
    # script options
    q(verbose|v+),
    q(help|h),
    q(colorize),
    # other options
    q(config|c=s),
    q(job|j=s),
    q(host|server|s=s),
    q(http-user|u=s),
    q(http-pass|p=s),
);

=head1 DESCRIPTION

B<build_jenkins_project.pl> - A Perl script template that uses the
L<Log::Log4perl> logging module.

=head1 OBJECTS

=head2 BuildJenkinsProject::Config

An object used for storing configuration data.

=head3 Object Methods

=cut

#############################
# BuildJenkinsProject::Config #
#############################
package BuildJenkinsProject::Config;
use strict;
use warnings;
use Getopt::Long;
use Log::Log4perl;
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
} # sub new

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
} # sub get

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
        my $oldvalue = $args{$key};
        $args{$key} = $value;
        $self->{_args} = \%args;
        return $oldvalue;
    } else {
        $args{$key} = $value;
        $self->{_args} = \%args;
    } # if ( exists $args{$key} )
    return undef;
} # sub get

=item get_args( )

Returns a hash containing the parsed script arguments.

=back

=cut

sub get_args {
    my $self = shift;
    # hash-ify the return arguments
    return %{$self->{_args}};
} # get_args

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
} # sub get

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
    my $jenkins_host = q(www.exmaple.com);
    my $jenkins_path = q(/jenkins);
    my $jenkins_url;

    if ( $config->defined(q(host)) ) {
        # FIXME munge things here
        my $munge_url = $config->get(q(host));
        $log->warn(qq(original URL: $munge_url));
        my $web_url_regex = qr|^(https?)://([\w.-]+):?([0-9]+){0,5}/?(.*)$|;
        $munge_url =~ /$web_url_regex/;
        $log->warn(qq(scheme: $1));
        $log->warn(qq(host: $2));
        $log->warn(qq(port: $3)) if ( defined $3 );
        $log->warn(qq(path: $4));
    } else {
        $log->warn(qq(Using $jenkins_url for the Jenkins URL;));
        $log->warn(qq(If this isn't what you want, use the --url switch));
        $log->warn(qq(to pass a URL in to this script));

    }

exit 0;
=begin comment

    use Net::Jenkins;
    my $jenk = Net::Jenkins->new( host => $jenkins_url);
    if ( defined $config->get(q(http-realm)) ) {
        my $ua = $jenk->user_agent();
        $ua->credentials(
            $jenkins_url,
            $config->get(q(http-realm)),
            $config->get(q(http-user)),
            $config->get(q(http-pass)),
        );
        $jenk->user_agent($ua);
    }

    print $jenk->summary();
    use Data::Dumper;
    print Dumper $jenk;

=end comment

=cut

    my $json = JSON->new();

    my $jenkins = Net::Jenkins->new(
        scheme          => q(https),
        host            => q(shell.xaoc.org),
        port            => 443,
        jenkins_path    => q(jenkins),
    );

    # do we need to set credentials?
    my $http_headers;
    if ( defined $config->get(q(http-user))
        && defined $config->get(q(http-pass)) ) {
        $http_headers = HTTP::Headers
            ->new()
            ->authorization_basic(
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
    my $summary = $jenkins->summary();
    if ( $jenkins->jenkins_version() ) {
        $log->warn(qq(Jenkins is online... Jenkins version: )
            . $jenkins->jenkins_version);
    }
    $log->warn(qq(Retrieving job info from )
        . $jenkins->job_url($config->get(q(job))) );
    my %jenkins_job = $jenkins->get_job_details( $config->get(q(job)) );
    print Dumper {%jenkins_job};
    #my $next_build_number = $jenkins_job{q(nextBuildNumber)};
    #$log->warn(qq(Next build number: $next_build_number));

exit 0;
    my $post_json = <<'EOJ';
    {"parameter": [
        {"name": "PKG_NAME", "value": "chocolate-doom"},
        {"name": "PKG_VERSION", "value": "1.7.0"},
        {"name": "TARBALL_DIR", "value": "$HOME/source"}
    ]}
EOJ

=begin comment

    $submit_job->content($post_json);
    $response = $ua->request($submit_job);
    if ( $response->code == HTTP_FOUND ) { # HTTP 302
        $log->warn(qq(Job submission successful!));
        if ( length($response->decoded_content()) > 0 ) {
            print Dumper $response->decoded_content();
        }
    } else {
        $log->logdie($response->status_line);
    }

    my $job_status = HTTP::Request->new(
        GET => $jenkins_url . qq(/$next_job_num/api/json?pretty=true));

    JOB_STATUS: while (1) {
        # do API requests here at intervals, and check 'result'
        # https://jenkurl/jenkins/view/Doom/job/prboom/4/api/json?pretty=true
        last JOB_STATUS;
    }
    exit 0;
    #print $jenk->summary();
    #use Data::Dumper;
    #print Dumper $jenk;

    #my $status = $jenk->current_status;

    #if ( defined $status ) {
    #    use Data::Dumper;
    #    print Dumper {$status};
    #} else {
    #    $log->logwarn(q(Error getting current Jenkins status; ));
    #    $log->logdie($jenk->response_code . q(:) . $jenk->response_content);
    #}

=end comment

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
