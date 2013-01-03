#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename qw/ dirname /;
use File::Path qw/ mkpath /;
use File::Spec;

my $APPROOT;
BEGIN { $APPROOT = dirname(__FILE__) }
use lib File::Spec->catdir($APPROOT, 'lib');
use lib File::Spec->catdir($APPROOT, 'local', 'lib', 'perl5');
use Getopt::Long ( );
use Plack::Runner;
use Proclet::Declare;

startup( );

sub startup
{
    my $options = +{ };
    my $usage   = sub {
        require Pod::Usage;
        Pod::Usage::pod2usage(
            -message => $_[0] && $_[0] ne 'help' ? $_[0] : '',
            -verbose => 1,
            -input   => __FILE__,
        );
    };

    Getopt::Long::GetOptions(
        $options,
        'listen=s',
        'env=s',
        'help' => $usage,
    ) or $usage->( );

    service(redis   => 'redis-server', 'config/redis.conf');
    service(twincle => sub {
            my $runner = Plack::Runner->new(server => 'Twiggy', env => $options->{env} || 'deployment');
            $runner->parse_options('--listen', $options->{listen} || ':12345');
            $runner->run;
        },
    );

    run;
}

__END__

=head1 NAME

=head1 SYNOPSIS

 twincle.pl [options]

 Options:
   --listen
   --env
   --help

=cut
