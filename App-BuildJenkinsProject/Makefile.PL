use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::BuildJenkinsProject',
    AUTHOR              => q{Brian Manning <xaoc at cpan dot org>},
    VERSION_FROM        => 'lib/App/BuildJenkinsProject.pm',
    ABSTRACT_FROM       => 'lib/App/BuildJenkinsProject.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-BuildJenkinsProject-*' },
);
