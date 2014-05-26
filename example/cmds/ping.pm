package example::cmds::ping;

use Term::ReadLine::CLISH::Command::Moose;
use namespace::autoclean;

use Net::DNS;
use Net::IP;
use IPC::System::Simple 'systemx';
use Scalar::Util qw(looks_like_number);
use Term::ReadLine::CLISH::MessageSystem;
use common::sense;

command(
    help => "send icmp echo requests to a host",
    arguments => [
        optional_argument( count => 'Scalar::Util::looks_like_number',
            help => "number of packets to send" ),

        optional_argument( size  => 'Scalar::Util::looks_like_number',
            help => "size of the packets in bytes" ),

        optional_argument( df => undef, help => "set the don't fragment bit" ),

        required_argument(
            target => ['validate_ipv4', 'validate_ipv6', 'validate_hostname'],
            tag_optional=>1, help => "target host for the pings" ),
    ],
);

has qw'resolver is rw isa Net::DNS::Resolver';

__PACKAGE__->meta->make_immutable;

sub exec {
    my $this = shift;
    my $opts = shift;

    my @args = ($opts->{target});

    push @args, -c => $opts->{count} if defined $opts->{count};
    push @args, -s => $opts->{size}  if defined $opts->{size};
    push @args, -M => "dont"         if defined $opts->{df};

    return eval { systemx( ping => @args ); 1};
}

sub validate_ipv6 {
    my $this = shift;
    my $arg = shift;

    debug "validating ipv6 $arg";

    return eval { Net::IP->new($arg) };
}

sub validate_ipv4 {
    my $this = shift;
    my $arg = shift;

    debug "validating ipv4 $arg";

    # Don't let people ping local NAT things
    return if $arg =~ m/^10\./;
    return if $arg =~ m/^192\./;
    return if $arg =~ m/^172\./;

    # or this host
    return if $arg eq "1.2.3.4"; # also naughty

    return eval { Net::IP->new($arg) };
}

sub validate_hostname {
    my $this = shift;
    my $res  = $this->resolver || $this->resolver( Net::DNS::Resolver->new );
    my $arg  = shift;

    debug "host lookup $arg";

    if ( my $query = $res->search($arg) ) {
        for my $rr ($query->answer) {
            my $type = $rr->type;

            given($type) {
                when( "A" )    { return $this->validate_ipv4($rr->address) }
                when( "AAAA" ) { return $this->validate_ipv6($rr->address) }
                default { next }
            }
        }

    } else {
        $@ = "host '$arg' lookup faliure: " . $res->errorstring;
        debug "set \$@ = \"$@\"";
    }

    $@ = "host '$arg' not found";
    debug "set \$@ = \"$@\"";

    return;
}

1;
