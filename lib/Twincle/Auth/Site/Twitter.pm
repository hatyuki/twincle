package Twincle::Auth::Site::Twitter;
use Net::Twitter::Lite;
use Furl;
use strict;
use warnings;

sub import
{
    no warnings 'redefine';

    *Furl::default_header = sub { };

    my $orig = *Net::Twitter::Lite::new{CODE};
    *Net::Twitter::Lite::new = sub {
        my ($class, %args) = @_;

        $args{ua} = Furl->new;
        $args{legacy_lists_api} = 0;

        $orig->($class, %args);
    };
}

1;
