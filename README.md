App-JenkBuilder

Runs Jenkins jobs specified in a configuration file in order to build an
entire "project".

INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

USAGE

    perl build_jenkins_project.pl --http-user=foo --http-pass=bar \
      --url https://example.com/jenkins/job/chocolate-doom --verbose

    perl build_jenkins_project.pl --http-user=foo --http-pass=bar \
      --url https://example.com/jenkins/job/prboom --verbose

    for JOB in $(echo libsdl libsdl-SDL_image libsdl-SDL_mixer
      libsdl-SDL_net libsdl-SDL_ttf prboom); do
      perl build_jenkins_project.pl \
        --http-user=foo --http-pass=bar \
        --host https://example.com/jenkins --job="${JOB}" --verbose;
    done

SAMPLE PROJECT MANIFEST FORMAT

The "project manifest" uses
[Config::Std](https://metacpan.org/module/Config::Std) syntax.  When the
[App::JenkBuilder::Project](http://tinyurl.com/mprksdp) object loads the
project manifest config file, it creates a
[App::JenkBuilder::Job](http://tinyurl.com/mhglerb) object that represents the
job that this project is trying to build.  Any dependencies of this job job
are also stored in the `Project` object as `App::JenkBuilder::Job` objects.
See the documentation for the `Project` and `Job` objects for more information
on object methods and attributes.


    [PROJECT]
    name : <project name, same name as the corresponding Jenkins job>
    version : <job version>
    build_arch : <build architecture>
    deps : (build dependencies; repeat "deps" lines as many times as needed)
    deps : (order matters, deps list gets built from top to bottom)
    deps : (format of deps line: "deps: dep_name, dep_version")
    deps : <dep_job_name>, <dep_job_version>
    deps : project-x, 1.00


SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the perldoc
command.

    perldoc App::JenkBuilder

You can also look for information at:

    Project homepage:
      https://github.com/spicyjack/App-JenkBuilder

    Project issues:
      https://github.com/spicyjack/App-JenkBuilder/issues


LICENSE AND COPYRIGHT

Copyright (C) 2013 Brian Manning

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
