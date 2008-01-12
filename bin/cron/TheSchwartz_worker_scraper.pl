#!/usr/bin/perl

use strict;
use warnings;

# for both Linux/Win32
my $has_proc_pid_file = eval "use Proc::PID::File; 1;"; ## no critic (ProhibitStringyEval)
my $has_home_dir      = eval "use File::HomeDir; 1;";   ## no critic (ProhibitStringyEval)
if ( $has_proc_pid_file and $has_home_dir ) {

    # If already running, then exit
    if ( Proc::PID::File->running( { dir => File::HomeDir->my_home } ) ) {
        exit(0);
    }
}

use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use Foorum::ExternalUtils qw/theschwartz config/;
use Foorum::TheSchwartz::Worker::Scraper;

my $config = config();

unless ( $config->{function_on}->{scraper} ) {
    die "Please enable function_on: scraper in your config!\n";
}

my $client = theschwartz();

$client->can_do('Foorum::TheSchwartz::Worker::Scraper');
$client->work();

1;
