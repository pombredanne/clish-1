package Term::ReadLine::CLISH;

=encoding UTF-8
=head1 NAME

Term::ReadLine::CLISH — command line interface shell

=cut

=head1 SYNOPSIS

XXX: Cut from example/MyShell.pm

=cut

use Moose;
use namespace::autoclean;
use Term::ReadLine;
use Moose::Util::TypeConstraints;
use common::sense;

our $VERSION = '0.0000'; # string for the CPAN

subtype 'pathArray', as 'ArrayRef[Str]';
coerce 'pathArray', from 'Str', via { [ split m/[:; ]+/ ] };

has qw(prompt is rw isa Str default) => "clish> ";
has qw(path   is rw isa Str default) => sub { [@INC] };
has qw(prefix is rw isa Str default) => "Term::ReadLine::CLISH::Command";

has qw(name is ro isa Str default) => "CLISH";
has qw(version is ro isa Str default) => $VERSION;
has qw(prompt is rw isa Str default) => "clish> ";
has qw(prefix is rw isa Str default) => "Term::ReadLine::CLISH::Command";
has qw(path is rw isa pathArray default) => sub { [@INC] };
has qw(history_location is rw);
has qw(term is rw isa Term::ReadLine);

my $done;
my @CLEANUP;
END { $_->() for @CLEANUP }

sub run {
    my $this = shift;
    my $term = Term::ReadLine->new($this->name);

    $this->term( $term );

    eval { $term->ornaments('', '', '', '') };
    $this->init_history;

    print "Welcome to " . $this->name . " v" . $this->version . ".\n\n";

    push @CLEANUP, sub { $this->save_history };

    INPUT: while(1) {
        my $prompt = $this->prompt;
        $_ = $term->readline($prompt);
        last INPUT unless defined;
        s/^\s*//; s/\s*$//; s/[\r\n]//g;

        say "You hear a voice in your head say, \"$_\""
    }
}

sub init_history {
    my $this = shift;
    my $term = $this->term;

    my $hl = $this->history_location;
    if( !$hl ) {
        my $n = lc $this->name;
        $this->history_location( $hl = "$ENV{HOME}/.$n\_history" );
    }
    $term->read_history($hl);
    print "[loaded ", int ($term->GetHistory), " command(s) from history file]\n";
}

sub save_history {
    my $this = shift;
    my $term = $this->term;
    my $hl = $this->history_location;

    return unless $hl;
    $term->write_history($hl);
    $term->history_truncate_file($hl, 100);
}

__PACKAGE__->meta->make_immutable;

1;
