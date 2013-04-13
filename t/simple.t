#! perl

use strict;
use warnings FATAL => 'all';

use version; our $VERSION = qv(0.0.1);

use FindBin::Real qw(Bin);
use Test::More;
use Test::Approvals::Namers::DefaultNamer;
use Test::Approvals::Core::FileApprover qw(verify_files verify_parts);
use Test::Approvals::Reporters;
use Test::Approvals::Writers::TextWriter;
use Readonly;

sub Namer {
    my %args = @_;
    return Test::Approvals::Namers::DefaultNamer->new( name => $args{name} );
}

sub test {
    my ( $name, $test_method ) = @_;

    my $working_dir = Bin();

    $test_method->( Namer( name => $name ) );
    return;
}

sub verify {
    my ( $name, $reporter, $test_method, ) = @_;
    $reporter =
      $reporter || Test::Approvals::Reporters::IntroductionReporter->new();
    my $namer  = Namer( name => $name );
    my $result = $test_method->($namer);
    my $writer = Test::Approvals::Writers::TextWriter->new(
        result         => $result,
        file_extension => '.txt'
    );
    my $full_reporter =
      Test::Approvals::Reporters::AndReporter->new( reporters => [$reporter] );
    return Test::Approvals::Core::FileApprover::verify( $writer, $namer,
        $full_reporter );
}

{
    Readonly my $REPORTER => Test::Approvals::Reporters::DiffReporter->new();

    verify 'Verify Hello World', $REPORTER, sub {
        return 'Hello World';
    };

}

test 'Test Files Match', sub {
    my ($namer) = @_;

    my $writer = Test::Approvals::Writers::TextWriter->new( result => "a.txt" );
    my $approved = 't/a1.txt';
    $writer->write_to($approved);

    my $received = 't/a.txt';
    $writer->write_to($received);

    my $reporter = Test::Approvals::Reporters::FakeReporter->new();
    verify_files( $approved, $received, $reporter );
    ok( !$reporter->was_called(), $namer->name() );
};

test 'Namer knows approval file', sub {
    my ($namer) = @_;
    like(
        $namer->get_approved_file('txt'),
        qr/simple[.]t[.]namer_knows_approval_file[.]approved[.]txt\z/mxs,
        $namer->name()
    );
};

done_testing();
