package Twincle::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;

# Lounge
get '/' => sub {
    my ($c) = @_;
    my $session = $c->session;
    my $sid     = $session->id;
    my $gaia    = $c->gaia;
    my $myself  = $gaia->find_user($sid);

    unless ($myself) {
        # Twitter のみ
        if (my $provider = $session->get('logged_in')) {
            $myself = $gaia->join(Twitter => +{
                    session_id          => $sid,
                    consumer_key        => $c->config->{Auth}->{Twitter}->{consumer_key},
                    consumer_secret     => $c->config->{Auth}->{Twitter}->{consumer_secret},
                    user_id             => $session->get('user_id'),
                    access_token        => $session->get('access_token'),
                    access_token_secret => $session->get('access_token_secret'),
                },
            );
        }
        # Guest
        else {
            $myself = $gaia->join(Guest => $sid);
        }
    }

    my $room = $gaia->find_room('Lounge');
    my $members;
    for my $member ($gaia->get_members($room->name)) {
        next unless $member->authorized;       ## guest user
        next if $sid eq $member->session_id;  ## myself
        push @$members, $member;
    }

    return $c->render('index.tx', +{
            room      => $room,
            history   => $gaia->get_history($room->name),
            members   => $members,
            myself    => $myself,
            websocket => $c->config->{websocket} || $c->request->env->{'HTTP_HOST'},
        },
    );
};

get '/logout' => sub {
    my ($c) = @_;
    my $session = $c->session;

    $c->gaia->leave($session->id);
    $session->expire( );

    return $c->redirect('/');
};

any '/socket' => sub {
    my ($c)  = @_;
    my $gaia = $c->gaia;

    return $c->websocket( sub {
            my $ws = shift;
            $gaia->setup_socket($c->session->id, $ws);
        },
    );
};

1;
