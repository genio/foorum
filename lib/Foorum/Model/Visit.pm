package Foorum::Model::Visit;

use strict;
use warnings;
use base 'Catalyst::Model';

sub make_visited {
    my ( $self, $c, $object_type, $object_id ) = @_;

    return unless ( $c->user_exists );
    return
        if (
        $c->model('DBIC::Visit')->count(
            {   user_id     => $c->user->user_id,
                object_type => $object_type,
                object_id   => $object_id
            }
        )
        );
    $c->model('DBIC::Visit')->create(
        {   user_id     => $c->user->user_id,
            object_type => $object_type,
            object_id   => $object_id,
            time        => time(),
        }
    );
}

sub make_un_visited {
    my ( $self, $c, $object_type, $object_id ) = @_;

    my @extra_cols;
    if ( $c->user_exists ) {
        @extra_cols = ( user_id => { '!=', $c->user->user_id } );
    }

    $c->model('DBIC::Visit')->search(
        {   object_type => $object_type,
            object_id   => $object_id,
            @extra_cols,
        }
    )->delete;
}

sub is_visited {
    my ( $self, $c, $object_type, $object_id ) = @_;

    return {} unless ( $c->user_exists );
    my $visit;
    my @visits = $c->model('DBIC::Visit')->search(
        {   user_id     => $c->user->user_id,
            object_type => $object_type,
            object_id   => $object_id,
        },
        { columns => ['object_id'], }
    )->all;
    foreach (@visits) {
        $visit->{$object_type}->{ $_->object_id } = 1;
    }

    return $visit;
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
