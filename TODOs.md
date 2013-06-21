# App::JenkBuilder TODOs ##
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

vim: filetype=markdown shiftwidth=2 tabstop=2
