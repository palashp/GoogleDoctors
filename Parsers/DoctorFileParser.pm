package DoctorFileParser;
use ParsingFramework::FileParser;
@ISA = ("FileParser");

# Parent class for a general doctor file parser. 
# Establishes a parser that gets: doctorID, Review-Lastname, Review-Firstname, rating, number-of-ratings
# To use this, you must call init and teardown yourself
# Subclasses must implement several methods!

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{RESULTDIR} = shift;
    $self->{INITED} = 0;
    my $fieldListRef = shift;
    my @fieldList;
    if ($fieldListRef) {
	@fieldList = @$fieldListRef;
    } else {
	@fieldList = ["ID", "Review-LastName", "Review-FirstName", "Rating", "Number-of-Ratings"];
    }
    $self->{FIELDS} = \@fieldList;

    bless($self, $class);
    return $self;
}

sub init() {
    # Initializes this parser and sub-parsers
    my $self = shift;
    my $resultFile = "$self->{RESULTDIR}/" . $self->outputFilename();
    open($self->{OUTHANDLE}, "> $resultFile") or die "Could not open results file $resultFile $!";
    my $handle = $self->{OUTHANDLE};
    print $handle ParserCommon::tabSeparate(@{$self->{FIELDS}});
    $self->{INITED} = 1;
}

sub teardown() {
    my $self = shift;
    my $handle = $self->{OUTHANDLE};
    close($handle);
    $self->{INITED} = 0;
}

sub canParseUrl {
    die "Subclasses must implement this";
}

sub outputFilename {
    die "Subclasses must implement this";
}

sub pageName {
    die "Subclasses must implement this";
}

sub getNameFromTree {
    die "Subclasses must implement this";
}

sub getRatingFromTree {
    die "Subclasses must implement this";
}

sub getDataFields {
    # returns dictionary of field name (from $self->{FIELDS}) -> field value.
    # many subparsers will override this.
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;
    
    my $tree = HTML::Tree->new_from_file($path);
 
    my ($firstName, $lastName) = $self->getNameFromTree($tree, $path);

    my ($rating, $ratingCount) = $self->getRatingFromTree($tree, $path);

    my %output;
    $output{"ID"} = $doctorId;
    $output{"Review-LastName"} = $lastName;
    $output{"Review-FirstName"} = $firstName;
    $output{"Rating"} = $rating;
    $output{"Number-of-Ratings"} = $ratingCount;
    return %output;
}

sub parse {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;

    my %fieldValues = $self->getDataFields($doctorId, $path);
 
    my @outputValues;
    foreach my $field (@{@{$self->{FIELDS}}[0]}) {
	push(@outputValues, $fieldValues{$field});
    }

    my $handle = $self->{OUTHANDLE};
    print $handle ParserCommon::tabSeparate(\@outputValues);
}

1;
