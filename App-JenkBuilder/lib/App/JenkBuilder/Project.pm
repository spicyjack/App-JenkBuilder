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

=head1 OBJECT METHODS

=head2 load_project

=cut

sub load {
    my $self = shift;
    my %args = @_;

    die(q|Missing filename of project to load (filename => $filename)|)
        unless ( defined $args{filename} );
    die(q|Can't read project file|)
        unless ( -r $args{filename} );

}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Brian Manning, C<< <xaoc at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests using the GitHub issue tracker at
L<https://github.com/spicyjack/App-JenkBuilder/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

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
