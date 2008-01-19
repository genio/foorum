#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBI }
        or plan skip_all => "DBI is required for this test";
    eval { require DBD::SQLite }
        or plan skip_all => "DBD::SQLite is required for this test";
    plan tests           => 3;
}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Foorum::TestUtils qw/schema cache/;
my $schema = schema();
my $cache  = cache();

my $filter_word_res = $schema->resultset('FilterWord');

# create
$filter_word_res->create(
    {   word => 'system',
        type => 'username_reserved'
    }
);
$filter_word_res->create(
    {   word => 'fuck',
        type => 'bad_word'
    }
);
$filter_word_res->create(
    {   word => 'asshole',
        type => 'offensive_word'
    }
);

$cache->remove("filter_word|type=username_reserved");
$cache->remove("filter_word|type=bad_word");
$cache->remove("filter_word|type=offensive_word");

my @data = $filter_word_res->get_data('username_reserved');

ok( grep { $_ eq 'system' } @data, "get 'username_reserved' OK" );

my $has_bad_word = $filter_word_res->has_bad_word("oh, fuck you!");
is( $has_bad_word, 1, 'has_bad_word OK' );

my $return_text = $filter_word_res->convert_offensive_word("kick your asshole la, dude!");
like( $return_text, qr/\*/, 'convert_offensive_word OK' );

#remove
$filter_word_res->search(
    {   word => 'system',
        type => 'username_reserved'
    }
)->delete;
$filter_word_res->search(
    {   word => 'fuck',
        type => 'bad_word'
    }
)->delete;
$filter_word_res->search(
    {   word => 'asshole',
        type => 'offensive_word'
    }
)->delete;

$cache->remove("filter_word|type=username_reserved");
$cache->remove("filter_word|type=bad_word");
$cache->remove("filter_word|type=offensive_word");

1;
