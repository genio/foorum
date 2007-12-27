use strict;
use warnings;
use Test::More tests => 2;

use Foorum::ExternalUtils qw/schema/;
my $schema = schema();

foreach (1, 2) {
    my $return = $schema->resultset('Star')->del_or_create( {
        user_id => 1,
        object_type => 'test',
        object_id => 1
    } );
    
    my $count = $schema->resultset('Star')->count( {
        user_id => 1,
        object_type => 'test',
        object_id => 1
    } );
    
    if ($return == 1) {
        is($count, 1, 'star OK');
    } else {
        is($count, 0, 'unstar OK');
    }
}

# cleanup
$schema->resultset('Star')->search( {
    user_id => 1,
    object_type => 'test',
    object_id => 1,
} )->delete;