
use common::sense;
use Test;
use lib 'example';
use Term::ReadLine::CLISH;
use Net::DNS;

binmode STDERR, ":utf8";
binmode STDOUT, ":utf8";

my $NOTHING_YET_PLEASE = 1;
my @output;
*Term::ReadLine::CLISH::Message::spew = sub { unless($NOTHING_YET_PLEASE) { warn "$_\n" for @_ } };

my $clish  = Term::ReadLine::CLISH->new->add_namespace("example::cmds") or die "couldn't make clish";
   $clish -> rebuild_parser;
my $parser = $clish->parser or die "couldn't make parser";

$NOTHING_YET_PLEASE = 0;

my @LINES = (
    q    => [ "quit" ],
    qu   => [ "quit" ],
    qui  => [ "quit" ],
    quit => [ "quit" ],

    e => [ qw(execute exit) ],
    x => [ qw(x) ], # x is the whole word alias for execute

    "ping "            => [ qw(df count size target) ],
    "ping df size"     => [ qw(size) ],
    "ping df size "    => [ ], # integer next, no completion
    "ping count "      => [ ], # integer next, no completion
    "ping count 3 "    => [ qw(df size target) ],
    "ping df size 1 c" => [ qw(count) ],
    "p d s 1 c 1 "     => [ qw(target) ],
    "p c 1 s 1 df"     => [ qw(df) ],
    "p c 1 s 1 df "    => [ qw(target) ],
);

my %RESULTS = @LINES;
   @LINES = grep {!ref} @LINES;

plan tests => 0 + @LINES;

@output = ();

for my $line (@LINES) {
    my @options = sort $parser->parse_for_tab_completion($line);
    my @expect  = sort @{ $RESULTS{$line} };

    ok( "$line: @options" => "$line: @expect" );
}
