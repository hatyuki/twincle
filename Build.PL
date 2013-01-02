use strict;
use warnings;
use Module::Build;

my $build = Module::Build->subclass(
    code => q{
        sub ACTION_install {
            die "Do not install web application.\n";
        }

        # do not make blib.
        sub ACTION_code {
            my $self = shift;
            $self->depends_on('config_data');
        }

        # run prove
        sub ACTION_test {
            my $self = shift;
            my $tests = $self->find_test_files;

            require App::Prove;
            my $prove = App::Prove->new();
            $prove->process_args('-l', @$tests);
            $prove->run();
        }
    }
)->new(
    license        => 'unknown',
    dynamic_config => 0,
    build_requires => {
        'Test::More'     => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires => { 'Module::Build' => '0.38' },
    requires           => {
        'perl'                            => '5.010000',
        'Amon2'                           => '3.66',
        'Amon2::Auth'                     => '0.02',
        'Config::ENV'                     => '0.11',
        'Data::MessagePack'               => '0.46',
        'Digest::SHA1'                    => '2.13',
        'EV'                              => '4.11',
        'Furl'                            => '1.00',
        'Log::Minimal'                    => '0.11',
        'MouseX::NativeTraits'            => '1.08',
        'Plack'                           => '1.0013',
        'Plack::Middleware::ReverseProxy' => '0.14',
        'Plack::Middleware::Session'      => '0.15',
        'Plack::Session::Store::Redis'    => '0.03',
        'Proclet'                         => '0.19',
        'Protocol::WebSocket'             => '0.11',
        'Redis'                           => '1.955',
        'Text::Xslate'                    => '1.5017',
        'Twiggy'                          => '0.1020',
    },

    no_index             => { directory => [ 'inc' ] },
    name                 => 'Twincle',
    module_name          => 'Twincle',
    author               => 'hatyuki <hatyuki29@gmail.com>',
    dist_abstract        => '',

    test_files           => 't/',
    recursive_test_files => 1,

    create_readme        => 0,
    create_license       => 0,
);
$build->create_build_script();
