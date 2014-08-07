package Term::ReadLine::CLISH::Configuration;

use Moose;
use File::Slurp;
use File::Spec;
use Term::ReadLine::CLISH::MessageSystem qw(:msgs);
use Term::ReadLine::CLISH::Library::InputModels::ConfigurationInputModel;
use common::sense;

has qw(slots is ro isa HashRef default) => sub { +{} };
has qw(subspace is rw isa Str default Configure);
has qw(model is ro isa Term::ReadLine::CLISH::InputModel default) => sub {
    Term::ReadLine::CLISH::Library::InputModels::ConfigurationInputModel->new;
};

has qw(startup_config_filename is rw isa Str default startup-config);

__PACKAGE__->meta->make_immutable;

{
    my %CONFIGS;
    sub value {
        my $this = shift;
        my $key  = shift or return;
        $CONFIGS{$key} = shift if @_;
        return $CONFIGS{$key};
    }
}

sub stringify_config {
    my $this = shift;
    my $slots = $this->slots;
    my @lines = map {$slots->{$_}} sort keys %$slots;

    my $PKG = ref $::THIS_CLISH;
    my $pkg = ref $this;
    my $date = localtime;

    local $" = "\n";
    return "! $PKG configuration\n! generated by $pkg on $date\n\n@lines\n";
}

sub recompute_prefix {
    my $this  = shift;
    my $model = $this->model;
    my $sub   = $this->subspace;

    $model->prefix( [ map { $_ . "::$sub" } @{$::THIS_CLISH->prefix} ] );
    $model->rebuild_parser;

    return $this;
}

sub execute_configuration {
    my $this = shift;
    my $config = shift;

    my $parser = $this->recompute_prefix->model->rebuild_parser->parser;

    for my $line ( split m/\s*\x0d?\x0a\s*/, $config ) {
        next if $line =~ m/^\s*\!/; # comment line
        next unless $line =~ m/\S/;
        todo "actually execute the configs: $line";
    }
}

sub set {
    my $this = shift;
    my ($slot, $line) = @_;

    debug "configuration set($slot => $line)" if $ENV{CLISH_DEBUG};

    return $this->slots->{slot} = $line;
}

sub clear_slot {
    my $this = shift;
    my ($slot) = @_;

    debug "configuration clear($slot)" if $ENV{CLISH_DEBUG};

    return delete $this->slots->{slot};
}

1;
