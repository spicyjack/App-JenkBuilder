use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::JenkBuilder',
    AUTHOR              => q{Brian Manning <xaoc at cpan dot org>},
    VERSION_FROM        => 'lib/App/JenkBuilder.pm',
    ABSTRACT_FROM       => 'lib/App/JenkBuilder.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Config::Std' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-JenkBuilder-*' },
);
