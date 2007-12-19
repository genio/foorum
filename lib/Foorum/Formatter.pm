package Foorum::Formatter;

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK $VERSION/;
@EXPORT_OK = qw/
    filter_format
    /;
$VERSION = '0.01'; # version

use vars qw/$has_text_textile $has_ubb_code $has_text_wiki $has_pod_simple $has_uri_find/;
$has_text_textile = eval "use Text::Textile; 1;";
$has_ubb_code     = eval "use Foorum::Formatter::BBCode; 1;";
$has_text_wiki    = eval "use Text::GooglewikiFormat; 1;";
$has_pod_simple   = eval "use Pod::Simple::Text; 1;";
$has_uri_find     = eval "use URI::Find; 1;";

sub filter_format {
    my ( $text, $params ) = @_;

    my $format = $params->{format} || 'plain';
    if ( $format eq 'textile' and $has_text_textile ) {
        my $formatter = Text::Textile->new();
        $formatter->charset('utf-8');
        $text = $formatter->process($text);
    } elsif ( $format eq 'ubb' and $has_ubb_code ) {
        my $formatter = Foorum::Formatter::BBCode->new(
            {   stripscripts => 1,
                linebreaks   => 1,
            }
        );
        $text = $formatter->parse($text);
    } elsif ( $format eq 'pod' and $has_pod_simple) {
#        my $pod_format = Pod::Simple::Text->new;
#        my $output;
#        $pod_format->output_string( \$output );
#        $text = "=pod\n\n$text" unless $text =~ /\n=[a-z]+\s/;
#        $pod_format->parse_string_document($text);
#        $text = $output;
    } elsif ( $format eq 'wiki' and $has_text_wiki) {
        $text =~ s/&/&amp;/gs;
        $text =~ s/>/&gt;/gs;
        $text =~ s/</&lt;/gs;
        my %tags = %Text::GooglewikiFormat::tags;
        
        # replace link sub
        my $linksub = sub {
            my ($link, $opts)        = @_;
	        $opts                  ||= {};

            my $ori_text = $link;
	        ($link, my $title)       = Text::GooglewikiFormat::find_link_title( $link, $opts );
	        ($link, my $is_relative) = Text::GooglewikiFormat::escape_link( $link, $opts );
            unless ($is_relative) {
	            return qq|<a href="$link">$title</a>|;
	        } else {
	            return $ori_text;
	        }
	    };
        $tags{link} = $linksub;
        $text = Text::GooglewikiFormat::format($text, \%tags);
    } else {
        $text =~ s/&/&amp;/gs;   # no_html
        $text =~ s|<|&lt;|gs;
        $text =~ s|>|&gt;|gs;
        #$text =~ s/'/&apos;/g; #'
        #$text =~ s/"/&quot;/g; #"
        $text =~ s|\n|<br />\n|gs;    # linebreaks
        
        if ($has_uri_find) {
            # find URIs
            my $finder = URI::Find->new( sub {
                    my($uri, $orig_uri) = @_;
                    return qq|<a href="$uri">$orig_uri</a>|;
            } );
            $finder->find(\$text);
        }
    }

    return $text;
}

1;
__END__

=pod

=head1 NAME

Foorum::Formatter - format content for Foorum

=head1 DESCRIPTION

  use Foorum::Formatter qw/filter_format/;
  
  my $text = q~ :inlove: [b]Test[/b] [size=14]dsadsad[/size] [url=http://fayland/]da[/url]~;
  my $html = filter($text, { format => 'ubb' } );
  print $html;
  # <img src="/static/images/bbcode/emot/inlove.gif"> <span style="font-weight:bold">Test</span> <span style="font-size:14px">dsadsad</span> <a href="http://fayland/">da</a>

=head1 SEE ALSO

L<HTML::BBCode>, L<Text::Textile>, L<Text::GooglewikiFormat>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=cut
