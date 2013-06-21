package App::JenkBuilder::Project;
use Moose;
use Config::Std;
use App::JenkBuilder::Job;

=head1 NAME

App::JenkBuilder::Project - Describes how to build a given "project",
or a collection of jobs in C<Jenkins> that are combined to build a final
product.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Describes how to build a set of Jenkins jobs.

    use App::JenkBuilder::Project;

    my $project = App::JenkBuilder::Project->new(config => $config);
    print q(Project: ) . $project->name() . q( has );
    say scalar($project->deps()) . q( dependencies.);
    ...

=head1 OBJECT ATTRIBUTES

=head2 jobs

An array of C<App::JenkBuilder::Job> objects that are required to be built.

=cut

has jobs => (
    is  => q(rw),
    isa => q(ArrayRef[App::JenkBuilder::Job]),
);

=head2 build_arch

Build architecture for building this project.  This value would be used to
determine what cross-compilers (if any) to use when building individual jobs.

=cut

has build_arch => (
    is  => q(rw),
    isa => q(Str),
);

has _project_config => (
    is  => q(rw),
    isa => q(HashRef),
);

=head1 OBJECT METHODS

=head2 load(config_file => $filename)

Loads the file passed in as C<config_file> and tries to parse it.  The format
of the configuration file is described in the
L<Config::Std|https://metacpan.org/module/Config::Std> module.

=cut

sub load {
    my $self = shift;
    my %args = @_;

    my $config_file = $args{config_file};
    die(q|Missing filename of config file to load (config_file => $file)|)
        unless ( defined $config_file );
    die(qq|Can't read project file $config_file|)
        unless ( -r $config_file );

    # load the config file from disk
    my %config;
    read_config($config_file => %config);
    my %project = %{$config{PROJECT}};
    #use Data::Dumper;
    #print Dumper %project;
    $self->_project_config(\%project);
    $self->build_arch($project{build_arch});
    my @project_deps = @{$project{job}};
    my @jobs;
    foreach my $dep ( @project_deps ) {
        my ($name, $version) = split(/,\s*/, $dep);
        push(@jobs, App::JenkBuilder::Job->new(
                        name    => $name,
                        version => $version,
                    )
        );
    }
    $self->jobs(\@jobs);
    # FIXME what should be returned here?
    # - number of jobs to build?
    # - project job?
    return 1;
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Brian Manning, C<< <xaoc at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests using the GitHub issue tracker at
L<https://github.com/spicyjack/App-JenkBuilder/issues>.  I will be notified,
and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::JenkBuilder::Project


You can also look for information at:

=over 4

=item * GitHub project page

L<https://github.com/spicyjack/App-JenkBuilder>

=item * GitHub issues page

L<https://github.com/spicyjack/App-JenkBuilder/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Brian Manning.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of App::JenkBuilder::Project
