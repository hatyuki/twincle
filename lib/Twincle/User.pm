package Twincle::User;
use Digest::SHA1 ( );
use Mouse;

has session_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    trigger  => sub { $_[0]->{digest} = Digest::SHA1::sha1_hex($_[1]) },
);

has digest => (
    is  => 'ro',
    isa => 'Str',
);

has id => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has icon => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has authorized => (
    is       => 'rw',
    isa      => 'Bool',
    required => 1,
);

has socket => (
    is      => 'rw',
    trigger => sub { $_[0]->_setup_socket($_[1]) },
    handles => [qw/ send_message /],
);

no Mouse;

sub _setup_socket
{
    my ($self, $socket) = @_;

    $socket->on_receive_message( sub {
            my ($c, $packed) = @_;
            $c->gaia->handle_message($c->session->id, $packed);
        },
    );

    # TODO:
    $socket->on_eof( );
    $socket->on_error( );
}

__PACKAGE__->meta->make_immutable;
