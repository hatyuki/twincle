package Twincle::User::Guest;
use Mouse;
extends qw/ Twincle::User /;

around BUILDARGS => sub {
    my ($origin, $class, $session_id) = @_;

    return $class->$origin(
        session_id => $session_id,
        id         => 0,
        name       => 'guest',
        icon       => '//si0.twimg.com/sticky/default_profile_images/default_profile_0_normal.png',
        authorized => 0,
    );
};

no Mouse;

__PACKAGE__->meta->make_immutable;
