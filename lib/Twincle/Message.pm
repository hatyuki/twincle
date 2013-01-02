package Twincle::Message;
use Data::MessagePack;
use Protocol::WebSocket::Frame;
our $PACKER;
our $VIEW;

use Mouse;

has type => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
    trigger => sub { $_[0]->reset },
);

has room => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
    trigger => sub { $_[0]->reset },
);

has body => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
    trigger => sub { $_[0]->reset },
);

has packed => (
    is      => 'ro',
    isa     => 'Str',
    clearer => 'reset',
    default => '',
);

around BUILDARGS => sub {
    my $origin = shift;
    my $class  = shift;
    my $args   = scalar @_ == 1 && ref $_[0] eq 'HASH' ? $_[0] : +{ @_ };

    if (my $packed = $args->{packed}) {
        eval {
            my $raw = $PACKER->unpack($packed);
            $args->{$_} = $raw->{$_} for qw/ type room body /;
        };
        if ($@) {
            die;  ## TODO
        }
    }

    return $class->$origin($args);
};

no Mouse;

sub render
{
    my ($self, $template, $args) = @_;
    my $str = $VIEW->render($template, $args);
    $self->body($str);

    return $str;
}

sub pack
{
    my $self   = shift;
    my $packed = $PACKER->pack( +{
            type => $self->type,
            room => $self->room,
            body => $self->body,
        },
    );

    $self->{packed} = $packed;

    return $packed;
}

sub publish
{
    my $self = shift;

    return Protocol::WebSocket::Frame->new(
        type   => 'binary',
        buffer => $self->packed || $self->pack,
    );
}

__PACKAGE__->meta->make_immutable;
