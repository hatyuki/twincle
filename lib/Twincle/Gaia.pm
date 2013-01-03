package Twincle::Gaia;
use feature qw/ switch /;
use Log::Minimal;
use Time::Piece ( );
use Twincle::Config;
use Twincle::Message;
use Twincle::Room;
use Twincle::Storage;
use Twincle::User::Guest;
use Twincle::User::Twitter;
use Mouse;

has config => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => [qw/ Hash /],
    required => 1,
    lazy     => 1,
    builder  => '_build_config',
    handles  => +{ get_config => 'get' },
);

has room => (
    is       => 'ro',
    isa      => 'HashRef',
    traits   => [qw/ Hash /],
    builder  => '_build_room',
    handles  => +{ find_room => 'get' },
);

has storage => (
    is       => 'ro',
    isa      => 'Twincle::Storage',
    required => 1,
    lazy     => 1,
    builder  => '_build_storage',
);

around BUILDARGS => sub {
    my $origin = shift;
    my $class  = shift;
    my $args   = scalar @_ == 1 && ref $_[0] eq 'HASH' ? $_[0] : +{ @_ };

    $Twincle::Message::VIEW   = delete $args->{view}   || croakf "'view' is required";
    $Twincle::Message::PACKER = delete $args->{packer} || Data::MessagePack->new;

    return $class->$origin($args);
};

no Mouse;

sub _build_config
{
    my $self = shift;
    return Twincle::Config->current;
}

sub _build_room
{
    my $self = shift;
    return +{
        Lounge => Twincle::Room->new(
            name        => 'Lounge',
            description => 'Lounge',
        ),
    };
}

sub _build_storage
{
    my $self   = shift;
    my $config = $self->get_config('storage');
    my $server = $config->{host} . ':' . $config->{port};
    return Twincle::Storage->new(
        server   => $server,
        encoding => undef,
    );
}

#  Login (join) / Logout (leave)
# --------------------------------------
sub join
{
    # TODO: Room 側で apply_role する ?
    my ($self, $type, $args) = @_;
    my $class = "Twincle::User::$type";
    my $user  = $class->new($args);

    infof 'Logged in: SessionID=%s Name=%s', $user->session_id, $user->name;
    $self->join_room(Lounge => $user);

    return $user;
}

sub join_room
{
    my ($self, $room_name, $user) = @_;
    my $room = $self->find_room($room_name);

    infof 'Join room: Room=%s User=%s', $room_name, $user->name;
    $room->join($user->session_id, $user);

    return $self;
}

sub leave
{
    my ($self, $session_id) = @_;

    $self->leave_room(Lounge => $session_id);

    return $self;
}

sub leave_room
{
    my ($self, $room_name, $session_id) = @_;
    my $room = $self->find_room($room_name);
    $room->leave($session_id);

    return $self;
}

#  Message history
# --------------------------------------
sub get_history
{
    my ($self, $room_name) = @_;
    my $size    = $self->get_config('history_size') || 10;
    my @history = $self->storage->lrange($room_name, 0, $size - 1);
    my $retval;

    for my $h (@history) {
        my $message = Twincle::Message->new(packed => $h);
        push @$retval, $message->body;
    }

    return $retval;
}

sub push_history
{
    my ($self, $room_name, $packed) = @_;
    my $size = $self->get_config('history_size') || 10;
    $self->storage->lpush($room_name, $packed);
    $self->storage->ltrim($room_name, 0, $size - 1);

    return $self;
}

#  Utilities
# --------------------------------------
sub find_user
{
    my ($self, $session_id) = @_;
    my $room = $self->find_room('Lounge');

    return $room->find_user($session_id);
}

sub get_members
{
    my ($self, $room_name) = @_;
    my $room = $self->find_room($room_name);

    return $room->members;
}

#  Message handler
# --------------------------------------
sub setup_socket
{
    my ($self, $session_id, $socket) = @_;
    my $user = $self->find_user($session_id);

    $user->socket($socket);

    return $self;
}

sub handle_message
{
    my ($self, $session_id, $packed) = @_;
    my $message = Twincle::Message->new(packed => $packed);

    return if !$message->body || $message->body =~ m/^\x{fffd}$/;

    debugf 'Receive message: Type=%s Room=%s Body=%s', $message->type, $message->room, $message->body;

    my $user = $self->find_user($session_id);
    given ($message->type) {
        when ('stream') {
            if ($user && $user->authorized) {
                $self->send_message($user, $message);
            }
            else {
                warnf 'Receive message from not logged in user: %s', $session_id;
            }
        }
        when ('ping') {
            my $message = Twincle::Message->new(
                type => 'pong',
                room => 'Lounge',
                body => 'pong',
            );
            $user->send_message($message->publish);
        }
        default {
            warnf 'Unknown message type: Type=%s Room=%s Body=%s', $message->type, $message->room, $message->body;
        }
    }

    return $self;
}

sub send_message
{
    my ($self, $user, $message) = @_;
    my $old = $message->body;

    $message->render('tweet.tx', +{
            userid    => $user->id,
            username  => $user->name,
            usericon  => $user->icon,
            timestamp => Time::Piece::localtime->strftime('%m-%d %H:%M:%S'),
            message   => $message->body,
        },
    );

    if (my $room = $self->find_room($message->room)) {
        debugf 'Send message: Type=%s Room=%s Body=%s', $message->type, $message->room, $old;
        $room->send_message($message);
        $self->push_history($room->name, $message->packed);
    }
    else {
        warnf 'Room not found: Type=%s Room=%s Body=%s', $message->type, $message->room, $message->body;
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;
