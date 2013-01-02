use strict;
use warnings;
use File::Spec;
use File::Basename qw/ dirname /;
my $APP_ROOT;
BEGIN { $APP_ROOT = File::Spec->catdir( dirname(__FILE__) ) }
use lib File::Spec->catdir($APP_ROOT, 'lib');
use Plack::Builder;
use Plack::Session::State::Cookie;
use Plack::Session::Store::Redis;
use Twincle::Config;
use Twincle::Web;

my $redis = Twincle::Config->param('storage');

builder {
    enable 'Plack::Middleware::Static', (
        path => qr{^(?:/asset/)},
        root => File::Spec->catdir($APP_ROOT),
    );

    enable 'Session', (
        state => Plack::Session::State::Cookie->new(httponly => 1),
        store => Plack::Session::Store::Redis->new(%$redis),
    );

    enable 'Plack::Middleware::ReverseProxy';

    mount '/' => Twincle::Web->to_app( );
};
