package Foorum::Controller::Ajax;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Data::Dumper;

sub auto : Private {
    my ( $self, $c ) = @_;

    # no cache
    $c->res->header(
        'Cache-Control' => 'no-cache, must-revalidate, max-age=0' );
    $c->res->header( 'Pragma' => 'no-cache' );

    return 1;
}

=pod

=item new_message

(Global Site) check if a user get any new message

=cut

sub new_message : Local {
    my ( $self, $c ) = @_;

    $c->stash->{donot_log_path} = 1;

    return $c->res->body(' ') unless ( $c->user_exists );

    my $count = $c->model('DBIC::MessageUnread')
        ->count( { user_id => $c->user->user_id, } );

    if ($count) {
        $c->res->body( "<a href='/message'><span style='color:red'>"
                . $c->localize( "You have new messages ([_1])", $count )
                . "</span></a>" );
    } else {
        return $c->res->body(' ');
    }
}

=pod

=item validate_username

Ajax way to validate the username in Register progress.

=cut

sub validate_username : Local {
    my ( $self, $c ) = @_;

    my $username = $c->req->param('username');

    my $ERROR = $c->model('Validation')->validate_username( $c, $username );
    return $c->res->body($ERROR) if ($ERROR);

    $c->res->body('OK');
}

sub star : Local {
    my ( $self, $c ) = @_;

    return $c->res->body('LOGIN FIRST') unless ( $c->user_exists );

    my $object_type = $c->req->param('obj_type');
    my $object_id   = $c->req->param('obj_id');

    # validate
    $object_type =~ s/\W+//g;
    $object_id   =~ s/\D+//g;
    return $c->res->body('ERROR') unless ( $object_type and $object_id );

    # if we already has it, it's unstar, or else, it's star
    my $ret = $c->model('DBIC')->resultset('Star')->del_or_create(
        {   user_id     => $c->user->user_id,
            object_type => $object_type,
            object_id   => $object_id,
        }
    );
    $c->res->body($ret);
}

sub share : Local {
    my ( $self, $c ) = @_;

    return $c->res->body('LOGIN FIRST') unless ( $c->user_exists );

    my $object_type = $c->req->param('obj_type');
    my $object_id   = $c->req->param('obj_id');

    # validate
    $object_type =~ s/\W+//g;
    $object_id   =~ s/\D+//g;
    return $c->res->body('ERROR') unless ( $object_type and $object_id );

    # if we already has it, it's unstar, or else, it's star
    my $ret = $c->model('DBIC')->resultset('Share')->del_or_create(
        {   user_id     => $c->user->user_id,
            object_type => $object_type,
            object_id   => $object_id,
        }
    );
    $c->res->body($ret);
}

=pod

=head2 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut

1;
