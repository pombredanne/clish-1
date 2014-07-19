
use common::sense;
use Test;
use lib 'example';
use Term::ReadLine::CLISH;
use Net::DNS;

$ENV{CLISH_DEBUG} = 1; # this messages up the message capture if it's set

my @output;
*Term::ReadLine::CLISH::Message::spew = sub { push @output, "@_" };

my $clish  = Term::ReadLine::CLISH->new->add_namespace("example::cmds") or die "couldn't make clish";
   $clish -> rebuild_parser;
my $parser = $clish->parser or die "couldn't make parser";

my %LINES = (
    q    => [ "quit" ],
    qu   => [ "quit" ],
    qui  => [ "quit" ],
    quit => [ "quit" ],

    "ping " => [ qw(df count size) ],
);

plan tests => 0 + (map { @$_ } values %LINES);

for my $line (keys %LINES) {
    my @options = sort $parser->parse_for_tab_completion($line);
    my @expect  = sort @{ $LINES{$line} };

    ok( "@options" => "@expect" );
}
