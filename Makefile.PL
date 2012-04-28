use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'SQL::Pico',
    VERSION_FROM        =>  'lib/SQL/Pico.pm',
    ABSTRACT_FROM       =>  'lib/SQL/Pico.pm',
    CONFIGURE_REQUIRES  =>  {
        'ExtUtils::MakeMaker' => '6.55',
    },
    BUILD_REQUIRES      =>  {
        'Test::More'    =>  '0',
    },
    PREREQ_PM           =>  {
        'Carp'          =>  '0',
        'DBI'           =>  '1.21',
        'Exporter'      =>  '0',
        'File::Spec'    =>  '0',
        'Scalar::Util'  =>  '0',
    },
    AUTHOR              =>  'Yusuke Kawasaki',
    LICENSE             =>  'perl',
};

WriteMakefile( %$opt );
