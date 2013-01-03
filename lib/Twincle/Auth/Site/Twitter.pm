package Twincle::Auth::Site::Twitter;
use Amon2::Auth::Site::Twitter;
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

    *Amon2::Auth::Site::Twitter::callback = sub {
        my ($self, $c, $callback) = @_;

        my $cookie = $c->session->get('auth_twitter')
            or return $callback->{on_error}->("Session error");

        my $nt = $self->_nt();
        $nt->request_token($cookie->[0]);
        $nt->request_token_secret($cookie->[1]);
        my $verifier = $c->req->param('oauth_verifier')
            or return $callback->{on_error}->("Authentication error");
        my ($access_token, $access_token_secret, $user_id, $screen_name) =
        $nt->request_access_token(verifier => $verifier);
        return $callback->{on_finished}->($access_token, $access_token_secret, $user_id, $screen_name);
    };
}

1;
