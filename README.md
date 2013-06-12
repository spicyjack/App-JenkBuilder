# App::BuildJenkinsProject #

Runs Jenkins jobs specified in a configuration file in order to build an
entire project.

## Todo ##
- Generate this README or the regular docs from POD
- Convert the `bin` file to use `Moose`, because both Jenkins modules use
  `Moose` already, so it's already available to be used
- Get Jenkins version via one of the Jenkins Perl frameworks (`Net::Jenkins`
  or `Jenkins::API`)
- Come up with some kind of job manifest that tells this app what to build, and
  in what order to build it
  - Sourced/read by the Jenkins scripts prior to the script performing any
    actions, or sourced in the job step before running any actions in that step
  - Project-specific settings
    - Project name
    - Project version
    - Tarball filename
    - Tarball download URL
    - Products that are built that need to be copied out
    - Architecture to build for
  - Come up with a manifest system that Jenkins will parse
    - The manifest describes:
      - what packages will be built
      - which versions of those packages will be built
      - for which architectures
      - job dependencies that need to be built prior to this job
        - dependencies can also be disabled if it's know that the dependency
          jobs are already up to date

## Examples of commands ##

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

vim: filetype=markdown shiftwidth=2 tabstop=2
