package Foorum::Model::Topic;

use strict;
use warnings;
use base 'Catalyst::Model';

sub get {
    my ( $self, $c, $topic_id, $attrs ) = @_;

    my $cache_key   = "topic|topic_id=$topic_id";
    my $cache_value = $c->cache->get($cache_key);

    my $topic;
    if ( $cache_value and $cache_value->{val} ) {
        $topic = $cache_value->{val};
    } else {
        $topic = $c->model('DBIC')->resultset('Topic')->find( { topic_id => $topic_id } );
        return unless ($topic);
        $topic = $topic->{_column_data};    # for cache
        $c->cache->set( $cache_key, { val => $topic, 1 => 2 }, 7200 );
    }

    if ( $attrs->{with_author} ) {
        $topic->{author}
            = $c->model('User')->get( $c, { user_id => $topic->{author_id} } );
    }

    return $topic;
}

sub create {
    my ( $self, $c, $create ) = @_;

    my $topic = $c->model('DBIC')->resultset('Topic')->create($create);

    # star it by default
    $c->model('DBIC')->resultset('Star')->create(
        {   user_id     => $create->{author_id},
            object_type => 'topic',
            object_id   => $topic->topic_id,
            time        => time(),
        }
    );

    return $topic;
}

sub update {
    my ( $self, $c, $topic_id, $update ) = @_;

    $c->model('DBIC')->resultset('Topic')->search( { topic_id => $topic_id } )
        ->update($update);

    $c->cache->remove("topic|topic_id=$topic_id");
}

sub remove {
    my ( $self, $c, $forum_id, $topic_id, $info ) = @_;

    # delete topic
    $c->model('DBIC::Topic')->search( { topic_id => $topic_id } )->delete;
    $c->cache->remove("topic|topic_id=$topic_id");

    # delete comments with upload
    my $total_replies = $c->model('Comment')->remove_by_object( $c, 'topic', $topic_id );

    # since one comment is topic indeed. so total_replies = delete_counts - 1
    $total_replies-- if ( $total_replies > 0 );

    # delete star/share
    $c->model('DBIC::Star')->search(
        {   object_type => 'topic',
            object_id   => $topic_id,
        }
    )->delete;
    $c->model('DBIC::Share')->search(
        {   object_type => 'topic',
            object_id   => $topic_id,
        }
    )->delete;

    # log action
    $c->model('Log')->log_action(
        $c,
        {   action      => 'delete',
            object_type => 'topic',
            object_id   => $topic_id,
            forum_id    => $forum_id,
            text        => $info->{log_text}
        }
    );

    # update last
    my $lastest
        = $c->model('DBIC')->resultset('Topic')
        ->search( { forum_id => $forum_id }, { order_by => 'last_update_date DESC', } )
        ->first;
    my $last_post_id = $lastest ? $lastest->topic_id : 0;
    $c->model('Forum')->update(
        $c,
        $forum_id,
        {   total_topics  => \"total_topics - 1",
            last_post_id  => $last_post_id,
            total_replies => \"total_replies - $total_replies",
        }
    );
}

1;
__END__

=pod

=head2 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
