package Foorum::TheSchwartz::Worker::RemoveObject;

use strict;
use warnings;
use TheSchwartz::Job;
use base qw( TheSchwartz::Worker );
use Foorum::ExternalUtils qw/schema error_log cache/;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    my ($args) = $job->arg;
    my $schema = schema();
    my $cache  = cache();

    #error_log( $schema, 'info', $log_text );
    $job->completed();
}

1;
__END__

=head1 NAME

Foorum::TheSchwartz::Worker::RemoveObject - remove object in Foorum

=head1 DESCRIPTION

we move 'remove object' here to let HTTP/Apache handle process more faster.

=head1 WORKFLOW

Generally we have a table 'object_remove' record the object_type+object_id.

(Here we do B<not> use TheSchwartz databse because we need log them for a long time while TheSchwartz remove database records after done or failure.)

=head1 USAGE

  use Foorum::ExternalUtils qw/theschwartz schema/;
  my $schema = schema();
  $schema->resultset('ObjectRemove')->create( { # or $c->model('DBIC')
      object_type => 'topic',
      object_id   => 12,
      time        => time(),
  } );
  my $client = theschwartz();
  $client->insert('Foorum::TheSchwartz::Worker::RemoveObject');

=head1 AUTHOR

Fayland Lam <fayland at gmail dot com>

=cut