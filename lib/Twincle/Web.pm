package Twincle::Web;
use strict;
use warnings;
use parent qw/ Twincle Amon2::Web /;
use File::Spec;

# dispatcher
use Twincle::Web::Dispatcher;
sub dispatch
{
    return (Twincle::Web::Dispatcher->dispatch($_[0]) or die "response is not generated");
}

# setup view class
use Text::Xslate;
{
    my $conf = __PACKAGE__->config->{xslate} || +{ };
    my $view = Text::Xslate->new(
        +{
            module   => ['Text::Xslate::Bridge::Star'],
            function => +{
                c => sub { Amon2->context },
                uri_with => sub { Amon2->context->req->uri_with(@_) },
                uri_for  => sub { Amon2->context->uri_for(@_) },
                static_file => do {
                    my %static_file_cache;
                    sub {
                        my $fname = shift;
                        my $c = Amon2->context;
                        if (not exists $static_file_cache{$fname}) {
                            my $fullpath = File::Spec->catfile($c->base_dir, $fname);
                            $static_file_cache{$fname} = (stat $fullpath)[9];
                        }
                        return $c->uri_for($fname, { 't' => $static_file_cache{$fname} || 0 });
                    }
                },
            },
            %$conf,
        }
    );

    sub create_view { $view }
}

# Gaia
use Twincle::Gaia;
{
    my $gaia = Twincle::Gaia->new(
        config => __PACKAGE__->config,
        view   => __PACKAGE__->create_view,
    );

    sub gaia { $gaia };
}

# load plugins
use Twincle::Auth::Site::Twitter;
__PACKAGE__->load_plugins(
    '+Twincle::Web::Plugin::WebSocket',
    'Web::Auth' => +{
        module            => 'Twitter',
        authenticate_path => '/login/twitter',
        callback_path     => '/login/twitter/callback',
        on_finished       => sub {
            my ($c, $token, $secret, $user_id) = @_;
            $c->session->set(logged_in           => 'Twitter');
            $c->session->set(user_id             => $user_id);
            $c->session->set(access_token        => $token);
            $c->session->set(access_token_secret => $secret);
            $c->request->session_options->{change_id}++;

            return $c->redirect('/');
        },
        on_error => sub {
            my ($c, $error) = @_;
            return $c->redirect('/');
        },
    },
#    'Web::FillInFormLite',
#    'Web::CSRFDefender',
);

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ($c, $res) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header('X-Content-Type-Options' => 'nosniff');

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header('X-Frame-Options' => 'DENY');

        # Cache control.
        $res->header('Cache-Control' => 'private');
    },
);

#__PACKAGE__->add_trigger(
#    BEFORE_DISPATCH => sub {
#        my ( $c ) = @_;
#        # ...
#        return;
#    },
#);

1;
