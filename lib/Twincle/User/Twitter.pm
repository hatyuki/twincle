package Twincle::User::Twitter;
use Net::Twitter::Lite;
use Mouse;
extends qw/ Twincle::User /;

around BUILDARGS => sub {
    my $origin = shift;
    my $class  = shift;
    my $args   = scalar @_ == 1 && ref $_[0] eq 'HASH' ? $_[0] : +{ @_ };

    my $twitter = Net::Twitter::Lite->new(
        consumer_key        => $args->{consumer_key},
        consumer_secret     => $args->{consumer_secret},
        access_token        => $args->{access_token},
        access_token_secret => $args->{access_token_secret},
    );
    my $user = $twitter->show_user($args->{user_id});

    return $class->$origin(
        session_id => $args->{session_id},
        id         => $user->{id},
        name       => $user->{screen_name},
        icon       => $user->{profile_image_url},
        authorized => 1,
    );
};

no Mouse;

__PACKAGE__->meta->make_immutable;
