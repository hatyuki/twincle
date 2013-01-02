package Twincle::Room;
use Twincle::Message;
use Mouse;

has name => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has description => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has users => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => [qw/ Hash /],
    default => sub { +{ } },
    handles => +{
        join      => 'set',
        find_user => 'get',
        members   => 'values',
        leave     => 'delete',
    },
);

around join => sub {
    my ($origin, $self, $session_id, $user) = @_;

    if ($user->authorized) {
        my $message = Twincle::Message->new(
            type => 'join',
            room => $self->name,
        );

        $message->render('member.tx', +{
                digest => $user->digest,
                id     => $user->id,
                name   => $user->name,
                icon   => $user->icon,
            },
        );

        $self->send_message($message, $user);
    }

    return $self->$origin($session_id, $user);
};

before leave => sub {
    my ($self, $session_id) = @_;
    my $user    = $self->find_user($session_id);
    
    return unless $user;

    my $message = Twincle::Message->new(
        type => 'leave',
        room => $self->name,
        body => $user->digest,
    );

    $self->send_message($message);
};

no Mouse;

sub send_message
{
    my ($self, $message, $user) = @_;
    my $frame = $message->publish;

    if ($user) {
        for my $member ($self->members) {
            next if $member->session_id eq $user->session_id;
            $member->send_message($frame);
        }
    }
    else {
        map { $_->send_message($frame) } $self->members;
    }

    return $self;
}

__PACKAGE__->meta->make_immutable;
