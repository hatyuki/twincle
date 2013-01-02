package Twincle::Config;
use strict;
use warnings;
use Amon2::Util;
use Config::ENV qw/ PLACK_ENV /, default => 'development';
use File::Spec;

my $base;
sub load_config
{
    $base ||= Amon2::Util::base_dir(__PACKAGE__);
    my $path = File::Spec->catfile($base, 'config', @_);
    return -f $path ? load($path) : ( );
}

common +{ load_config('common.pl') };

for my $env (qw/ development test deployment /) {
    config $env => +{ load_config("$env.pl") };
}

1;
