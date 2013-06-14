package App::BuildJenkinsProject::Project;

use warnings;
use strict;

=head1 NAME

App::BuildJenkinsProject::Project - Describes how to build a given "project",
or a collection of jobs in C<Jenkins>.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Describes how to build a set of Jenkins jobs.

Perhaps a little code snippet.

    use App::BuildJenkinsProject::Project;

    my $project = App::BuildJenkinsProject::Project->new(config => $config);
    print q(Project: ) . $project->name() . q( has );
    print $project->
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Brian Manning, C<< <xaoc at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests using the GitHub issue tracker at
L<https://github.com/spicyjack/App-BuildJenkinsProject/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::BuildJenkinsProject::Project


You can also look for information at:

=over 4

=item * GitHub project page

L<https://github.com/spicyjack/App-BuildJenkinsProject>

=item * GitHub issues page

L<https://github.com/spicyjack/App-BuildJenkinsProject/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Brian Manning.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of App::BuildJenkinsProject::Project
