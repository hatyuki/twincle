package Twincle::Web::Plugin::WebSocket;
use strict;
use warnings;

use Amon2::Util;
use AnyEvent::Handle;
use Amon2::Web::WebSocket;
use Amon2::Web::Response::Callback;
use Protocol::WebSocket 0.00906;
use Protocol::WebSocket::Frame;
use Protocol::WebSocket::Handshake::Server;

sub init {
    my ($class, $c, $conf) = @_;

    Amon2::Util::add_method(ref $c || $c, 'websocket', \&_websocket);
}

sub _websocket {
    my ($c, $code) = @_;

    my $fh = $c->req->env->{'psgix.io'} or return $c->create_response(500, [ ], [ ]);
    my $ws = Amon2::Web::WebSocket->new( );
    my $hs = Protocol::WebSocket::Handshake::Server->new_from_psgi($c->req->env);
    $hs->parse($fh) or return $c->create_response(400, [ ], [$hs->error]);
    my @messages;
    $ws->{send_message} = sub {
        my $message = shift;
        push @messages, $message;
    };
    $code->($ws);
    my $res = Amon2::Web::Response::Callback->new(
        code => sub {
            my $respond = shift;
            eval {
                my $h = AnyEvent::Handle->new(fh => $fh);
                $ws->{send_message} = sub {
                    my $message = shift;

                    unless (eval { $message->isa('Protocol::WebSocket::Frame') }) {
                        $message = Protocol::WebSocket::Frame->new($message);
                    }

                    $h->push_write($message->to_bytes);
                };
                my $frame = Protocol::WebSocket::Frame->new( );
                $h->push_write($hs->to_string);
                $ws->send_message($_) for @messages;
                @messages = ( );

                $h->on_read(
                    sub {
                        $frame->append($_[0]->rbuf);

                        while (my $message = $frame->next_bytes) {
                            $ws->call_receive_message($c, $message);
                        }
                    }
                );
                $h->on_error(sub { $ws->call_error($c, $_[1], $_[2]) });
                $h->on_eof(sub { $ws->call_eof($c) });
            };
            if ($@) {
                warn $@;
                die "Cannot process websocket";
            }
        },
    );
    return $res;
}

1;
