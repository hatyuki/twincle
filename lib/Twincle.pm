package Twincle;
use strict;
use warnings;
use parent qw/ Amon2 /;
our $VERSION='0.03';
use Twincle::Config;

sub load_config { Twincle::Config->current }

1;
