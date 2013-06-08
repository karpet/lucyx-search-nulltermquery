package LucyX::Search::NullQuery;
use strict;
use warnings;
use base qw( Lucy::Search::Query );
use Carp;
use Scalar::Util qw( blessed );
use LucyX::Search::NullCompiler;

our $VERSION = '0.001';

=head1 NAME

LucyX::Search::NullQuery - Lucy query extension for NULL values

=head1 SYNOPSIS

 my $query = LucyX::Search::NullQuery->new(
    field   => 'color',
 );
 my $hits = $searcher->hits( query => $query );
 # $hits == documents where the 'color' field is empty

=head1 DESCRIPTION

LucyX::Search::NullQuery extends the 
Lucy::QueryParser syntax to support NULL values.

=head1 METHODS

This class is a subclass of Lucy::Search::Query. Only new or overridden
methods are documented here.

=cut

# Inside-out member vars
my %field;
my %lex_terms;

=head2 new( I<args> )

Create a new NullQuery object. I<args> must contain key/value pairs
for C<field> and C<term>.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $field = delete $args{field};
    my $self  = $class->SUPER::new(%args);
    confess("'field' param is required")
        unless defined $field;
    $field{$$self} = $field;
    return $self;
}

=head2 get_field

Retrieve the value set in new().

=cut

sub get_field { my $self = shift; return $field{$$self} }

=head2 add_lex_term( I<term> )

Push I<term> onto the stack of lexicon terms that this Query matches.

=cut

sub add_lex_term {
    my $self = shift;
    my $t    = shift;
    croak "term required" unless defined $t;
    $lex_terms{$$self}->{$t}++;
}

=head2 get_lex_terms

Returns array ref of terms in the lexicons that this
query matches.

=cut

sub get_lex_terms {
    my $self = shift;
    return [ keys %{ $lex_terms{$$self} } ];
}

sub DESTROY {
    my $self = shift;
    delete $field{$$self};
    delete $lex_terms{$$self};
    $self->SUPER::DESTROY;
}

=head2 equals

Returns true (1) if the object represents the same kind of query
clause as another NullQuery.

NOTE: Currently a NOTNullQuery and a NullQuery object will
evaluate as equal if they have the same field. This is a bug.

=cut

sub equals {
    my ( $self, $other ) = @_;
    return 0 unless blessed($other);
    return 0
        unless $other->isa( ref $self );
    return $self->get_field eq $other->get_field;
}

=head2 to_string

Returns the query clause the object represents.

=cut

sub to_string {
    my $self = shift;
    return join( ':', $self->get_field, "NULL" );
}

=head2 make_compiler

Returns a LucyX::Search::NullCompiler object.

=cut

sub make_compiler {
    my $self        = shift;
    my %args        = @_;
    my $subordinate = delete $args{subordinate};    # new in Lucy 0.2.2
    $args{parent}  = $self;
    $args{include} = 1;
    my $compiler = LucyX::Search::NullCompiler->new(%args);

    # unlike Search::Query synopsis, normalize()
    # is called internally in $compiler.
    # This should be fixed in a C re-write.
    #$compiler->normalize unless $subordinate;

    return $compiler;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lucyx-search-wildcardquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LucyX-Search-NullQuery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LucyX::Search::NullQuery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LucyX-Search-NullQuery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LucyX-Search-NullQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LucyX-Search-NullQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/LucyX-Search-NullQuery/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
