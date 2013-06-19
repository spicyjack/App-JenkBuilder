package App::JenkBuilder::Project;
use Moose;
use Config::Std;

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

=head2 project

C<App::JenkBuilder::Job> object that is the focus of the "project".

=cut

has project => (
    is  => q(rw),
    isa => q(App::JenkBuilder::Job),
);

has dependent_jobs => (
    is  => q(rw),
    isa => q(ArrayRef[App::JenkBuilder::Job]),
);

has _config => (
    is  => q(rw),
    isa => q(Object),
);

=head1 OBJECT METHODS

=head2 load_project(config_file => $filename)

Loads the file passed in as C<config_file> and tries to parse it.  The format
of the configuration file is described in the
L<Config::Std|https://metacpan.org/module/Config::Std> module.

=cut

sub load {
    my $self = shift;
    my %args = @_;

    my $config_file = $args{config_file};
    die(q|Missing filename of project to load (filename => $filename)|)
        unless ( defined $config_file );
    die(qq|Can't read project file $config_file|)
        unless ( -r $config_file );

    # load the config file from disk
    my %config;
    read_config($config_file => %config);
    $self->_config(\%config);
    $self->name = $config{name};
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
