package Foorum::Controller::Comment;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Foorum::Utils qw/encodeHTML/;

sub auto : Private {
    my ( $self, $c ) = @_;

    unless ( $c->user_exists ) {
        $c->res->redirect('/login');
        return 0;
    }

    if ( $c->user->{status} eq 'banned' or $c->user->{status} eq 'blocked' ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }

    return 1;
}

sub post : Local {
    my ( $self, $c ) = @_;

    # get object_type and object_id from c.req.referer
    my $path = $c->req->referer || '/';
    my ( $object_id, $object_type, $forum_id )
        = $c->model('Object')->get_object_from_url( $c, $path );
    return $c->res->redirect($path) unless ( $object_id and $object_type );

    if ($forum_id) {    # maybe that's a ForumCode
        my $forum = $c->controller('Get')->forum( $c, $forum_id );
        $forum_id = $forum->{forum_id};
    }

    my $reply_to = 0;
    if ( $object_type eq 'topic' ) {
        my $topic
            = $c->controller('Get')->topic( $c, $object_id, { forum_id => $forum_id } );

        # topic is closed or not
        $c->detach( '/print_error', ['ERROR_CLOSED'] ) if ( $topic->{closed} );

        # for topic. only the first comment (topic) is reply_to == 0.
        # get the first comment for reply_to
        my $rs = $c->model('DBIC::Comment')->search(
            {   object_type => 'topic',
                object_id   => $object_id,
            },
            {   order_by => 'post_on',
                rows     => 1,
                page     => 1,
                columns  => ['comment_id'],
            }
        )->first;
        $reply_to = $rs->comment_id;
    }

    # execute validation.
    $c->model('Validation')->validate_comment($c);

    my $upload    = $c->req->upload('upload');
    my $upload_id = 0;
    if ($upload) {
        $upload_id
            = $c->model('Upload')->add_file( $c, $upload, { forum_id => $forum_id } );
        unless ($upload_id) {
            $c->detach( '/print_error', [ $c->stash->{upload_error} ] );
        }
    }

    my $title     = $c->req->param('title');
    my $formatter = $c->req->param('formatter');
    my $text      = $c->req->param('text');

    # create record
    my $new_comment = $c->model('Comment')->create(
        $c,
        {   object_type => $object_type,
            object_id   => $object_id,
            forum_id    => $forum_id,
            upload_id   => $upload_id,
            reply_to    => $reply_to,
            title       => $title,
            text        => $text,
            formatter   => $formatter,
        }
    );

    # go this comment
    my $comment_id = $new_comment->comment_id;
    $path .= "/comment_id=$comment_id/#c$comment_id";

    $c->res->redirect($path);
}

sub reply : LocalRegex('^(\d+)/reply$') {
    my ( $self, $c ) = @_;

    $c->stash(
        {   template => 'comment/new.html',
            mode     => 'reply',
        }
    );

    my $comment_id = $c->req->snippets->[0];
    my $comment    = $c->model('Get')
        ->comment( $c, $comment_id, { with_author => 1, with_text => 1 } );

    my ( $object_id, $object_type, $forum_id )
        = ( $comment->{object_id}, $comment->{object_type}, $comment->{forum_id} );

    my $forum;
    $forum = $c->controller('Get')->forum( $c, $forum_id ) if ($forum_id);
    if ( $object_type eq 'topic' ) {
        my $topic
            = $c->controller('Get')->topic( $c, $object_id, { forum_id => $forum_id } );

        # topic is closed or not
        $c->detach( '/print_error', ['ERROR_CLOSED'] ) if ( $topic->{closed} );
    }

    return unless ( $c->req->method eq 'POST' );

    # execute validation.
    $c->model('Validation')->validate_comment($c);

    my $upload    = $c->req->upload('upload');
    my $upload_id = 0;
    if ($upload) {
        $upload_id = $c->model('Upload')
            ->add_file( $c, $upload, { forum_id => $comment->{forum_id} } );
        unless ($upload_id) {
            return $c->set_invalid_form( upload => $c->stash->{upload_error} );
        }
    }

    my $title     = $c->req->param('title');
    my $formatter = $c->req->param('formatter');
    my $text      = $c->req->param('text');

    my $info = {
        object_type => $object_type,
        object_id   => $object_id,
        forum_id    => $forum_id,
        upload_id   => $upload_id,
        reply_to    => $comment_id,
        title       => $title,
        text        => $text,
        formatter   => $formatter,
    };

    # create record
    my $new_comment = $c->model('Comment')->create( $c, $info );

    # update object after create
    if ( $object_type eq 'topic' ) {

        # update forum and topic
        $c->model('Forum')->update(
            $c,
            $forum_id,
            {   total_replies => \'total_replies + 1',    #'
                last_post_id  => $object_id,
            }
        );
        $c->model('Topic')->update(
            $c,
            $object_id,
            {   total_replies    => \"total_replies + 1",
                last_update_date => \"NOW()",
                last_updator_id  => $c->user->user_id,
            }
        );
    }

    # update user stat
    $c->model('User')->update( $c, $c->user, { replies => \"replies + 1" } );    #"

    if ($forum_id) {
        $c->model('ClearCachedPage')->clear_when_topic_changes( $c, $forum );
    }

    my $path = $c->model('Object')->get_url_from_object( $c, $info );

    # go this comment
    $comment_id = $new_comment->comment_id;
    $path .= "/comment_id=$comment_id/#c$comment_id";

    $c->forward(
        '/print_message',
        [   {   msg => 'Post Reply OK',
                url => $path,
            }
        ]
    );
}

sub edit : LocalRegex('^(\d+)/edit$') {
    my ( $self, $c ) = @_;

    my $comment_id = $c->req->snippets->[0];
    my $comment = $c->model('Get')->comment( $c, $comment_id );

    # permission
    if ( $c->user->user_id != $comment->{author_id} ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    $c->stash(
        {   template => 'comment/new.html',
            mode     => 'edit',
        }
    );

    # edit upload
    my $old_upload;
    if ( $comment->{upload_id} ) {
        $old_upload
            = $c->model('DBIC::Upload')->find( { upload_id => $comment->{upload_id} } );
    }
    $c->stash->{upload} = $old_upload;

    return unless ( $c->req->method eq 'POST' );

    # execute validation.
    $c->model('Validation')->validate_comment($c);

    my $new_upload = $c->req->upload('upload');
    my $upload_id  = $comment->{upload_id};
    if ( ( $c->req->param('attachment_action') eq 'delete' ) or $new_upload ) {

        # delete old upload
        if ($old_upload) {
            $c->model('Upload')->remove_by_upload( $c, $old_upload );
            $upload_id = 0;
        }

        # add new upload
        if ($new_upload) {
            $upload_id = $c->model('Upload')
                ->add_file( $c, $new_upload, { forum_id => $comment->{forum_id} } );
            unless ($upload_id) {
                return $c->set_invalid_form( upload => $c->stash->{upload_error} );
            }
        }
    }

    my $title     = $c->req->param('title');
    my $text      = $c->req->param('text');
    my $formatter = $c->req->param('formatter');

    $title = encodeHTML($title);

    $c->model('DBIC')->resultset('Comment')->search( { comment_id => $comment_id, } )
        ->update(
        {   title     => $title,
            text      => $text,
            formatter => $formatter,
            update_on => \'NOW()',           #'
            post_ip   => $c->req->address,
            upload_id => $upload_id,
        }
        );

    my ( $object_id, $object_type, $forum_id )
        = ( $comment->{object_id}, $comment->{object_type}, $comment->{forum_id} );
    my $info = {
        object_type => $object_type,
        object_id   => $object_id,
        forum_id    => $forum_id,
    };
    my $path = $c->model('Object')->get_url_from_object( $c, $info );

    # for topic
    if ( $object_type eq 'topic' and $comment->{reply_to} == 0 ) {
        $c->model('DBIC')->resultset('Topic')->search( { topic_id => $object_id } )
            ->update( { title => $title } );
    }

    my $cache_key = "comment|object_type=$object_type|object_id=$object_id";
    $c->cache->remove($cache_key);

    # go this comment
    $path .= "/comment_id=$comment_id/#c$comment_id";

    $c->forward(
        '/print_message',
        [   {   msg => 'Edit Reply OK',
                url => $path,
            }
        ]
    );
}

sub delete : LocalRegex('^(\d+)/delete$') {
    my ( $self, $c ) = @_;

    my $comment_id = $c->req->snippets->[0];
    my $comment = $c->model('Get')->comment( $c, $comment_id );

    my ( $object_id, $object_type, $forum_id )
        = ( $comment->{object_id}, $comment->{object_type}, $comment->{forum_id} );

    my $forum;
    $forum = $c->controller('Get')->forum( $c, $forum_id ) if ($forum_id);

    my $is_admin = 0;
    if ($forum_id) {
        $is_admin = $c->model('Policy')->is_moderator( $c, $forum_id );
    } else {
        $is_admin = $c->model('Policy')->is_moderator( $c, 'site' );
    }

    # permission
    if ( $c->user->user_id != $comment->{author_id}
        and not $is_admin ) {
        $c->detach( '/print_error', ['ERROR_PERMISSION_DENIED'] );
    }

    my $info = {
        object_type => $comment->{object_type},
        object_id   => $comment->{object_id},
        forum_id    => $comment->{forum_id},
    };
    my $path = $c->model('Object')->get_url_from_object( $c, $info );

    # esp treat
    if ( $object_type eq 'topic' ) {
        my $topic
            = $c->controller('Get')->topic( $c, $object_id, { forum_id => $forum_id } );
        if ( $comment->{reply_to} == 0 ) {

            # u can only delete 5 topics one day
            my $most_deletion_per_day = $c->config->{per_day}->{most_deletion_topic}
                || 5;
            my $deleted_count = $c->model('DBIC')->resultset('LogAction')->count(
                {   forum_id => $forum_id,
                    action   => 'delete',
                    time     => \"> DATE_SUB(NOW(), INTERVAL 1 DAY)",    #"
                }
            );
            if ( $deleted_count >= $most_deletion_per_day ) {
                $c->detach(
                    '/print_error',
                    [   "For security reason, you can't delete more than $most_deletion_per_day topics in one day"
                    ]
                );
            }

            $c->model('Topic')
                ->remove( $c, $forum_id, $object_id, { log_text => $comment->{title} } );
            $path = $forum->{forum_url};
            $c->model('ClearCachedPage')->clear_when_topic_changes( $c, $forum );
        }
    }

    # delete comment
    $c->model('Comment')->remove( $c, $comment );

    if ( $object_type eq 'topic' ) {

        # update topic
        my $lastest = $c->model('DBIC')->resultset('Comment')->find(
            {   object_type => 'topic',
                object_id   => $object_id,
            },
            { order_by => 'post_on DESC', }
        );

        my @extra_cols;
        if ($lastest) {
            @extra_cols = (
                last_updator_id  => $lastest->author_id,
                last_update_date => $lastest->update_on || $lastest->post_on,
            );
        } else {
            @extra_cols = (
                last_updator_id  => '',
                last_update_date => '',
            );
        }
        $c->model('Topic')->update(
            $c,
            $object_id,
            {   total_replies => \"total_replies - 1",    #"
                @extra_cols,
            }
        );

        # update forum
        $c->model('Forum')
            ->update( $c, $forum_id, { total_replies => \'total_replies - 1' } );    #'
    }

    $c->forward(
        '/print_message',
        [   {   msg => 'Delete Reply OK',
                url => $path,
            }
        ]
    );
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
