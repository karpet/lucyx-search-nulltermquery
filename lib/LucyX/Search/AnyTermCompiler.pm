package LucyX::Search::AnyTermCompiler;
use strict;
use warnings;
use base qw( Lucy::Search::Compiler );
use Carp;
use Lucy::Search::ORQuery;
use Lucy::Search::TermQuery;
use LucyX::Search::WildcardQuery;
use Data::Dump qw( dump );

our $VERSION = '0.004';

my $DEBUG = $ENV{LUCYX_DEBUG} || 0;

# inside out vars
my ( %searcher, %ChildCompiler, %ChildQuery, %subordinate, %term_limit );

sub DESTROY {
    my $self = shift;
    delete $ChildQuery{$$self};
    delete $ChildCompiler{$$self};
    delete $searcher{$$self};
    delete $subordinate{$$self};
    delete $term_limit{$$self};
    $self->SUPER::DESTROY;
}

=head1 NAME

LucyX::Search::AnyTermCompiler - Lucy query extension

=head1 SYNOPSIS

    # see Lucy::Search::Compiler

=head1 METHODS

This class isa Lucy::Search::Compiler subclass. Only new
or overridden methods are documented.

=cut

=head2 new( I<args> )

Returns a new Compiler object.

I<args> may contain optional B<term_limit> key/value pair.
If the number of unique values for the relevant field exceeds
the limit, a WildcardQuery will be used internally instead of an ORQuery,
as an optimization.

=cut

sub new {
    my $class    = shift;
    my %args     = @_;
    my $searcher = $args{searcher} || $args{searchable};
    if ( !$searcher ) {
        croak "searcher required";
    }

    my $subordinate = delete $args{subordinate};
    my $limit = delete $args{term_limit} || $ENV{LUCYX_TERM_LIMIT} || 1000;
    my $self  = $class->SUPER::new(%args);
    $searcher{$$self}    = $searcher;
    $subordinate{$$self} = $subordinate;
    $term_limit{$$self}  = $limit;

    return $self;
}

=head2 get_term_limit

Returns the I<term_limit> set in new.

=cut

sub get_term_limit {
    my $self = shift;
    return $term_limit{$$self};
}

=head2 make_matcher( I<args> )

Returns a Lucy::Search::Matcher-based object.

make_matcher() creates a Lucy::Search::ORQuery or LucyX::Search::WildcardQuery
internally based on the terms associated with the parent AnyTermQuery field value,
and returns the internal Query's Matcher.

=cut

sub make_matcher {
    my ( $self, %args ) = @_;

    my $parent = $self->get_parent;
    my $field  = $parent->get_field;

    # Retrieve low-level components
    my $seg_reader = $args{reader} or croak "reader required";
    my $lex_reader = $seg_reader->obtain("Lucy::Index::LexiconReader");
    my $lexicon    = $lex_reader->lexicon( field => $field );

    $DEBUG and warn "field:$field\n";

    if ( !$lexicon ) {

        #warn "no lexicon for field:$field";
        return;
    }

    # create ORQuery for all terms associated with $field
    my @terms;
    my $limit        = $self->get_term_limit();
    my $use_wildcard = 0;
    while ( defined( my $lex_term = $lexicon->get_term ) ) {

        $DEBUG and warn sprintf( "\n lex_term='%s'\n",
            ( defined $lex_term ? $lex_term : '[undef]' ),
        );

        if ( !defined $lex_term || !length $lex_term ) {
            last unless $lexicon->next;
            next;
        }

        push @terms,
            Lucy::Search::TermQuery->new(
            term  => $lex_term,
            field => $field,
            );

        last unless $lexicon->next;
        if ( scalar @terms > $limit ) {
            $use_wildcard = 1;
            last;
        }
    }

    return if !@terms;

    if ($use_wildcard) {

        my $wcq = LucyX::Search::WildcardQuery->new(
            field => $field,
            term  => '?*'
        );
        $ChildQuery{$$self} = $wcq;
        my $wcc = $wcq->make_compiler( searcher => $searcher{$$self} );
        $ChildCompiler{$$self} = $wcc;
        return $wcc->make_matcher(%args);
    }

    $DEBUG and warn dump \@terms;

    my $or_query = Lucy::Search::ORQuery->new( children => \@terms, );
    $ChildQuery{$$self} = $or_query;
    my $or_compiler
        = $or_query->make_compiler( searcher => $searcher{$$self} );
    $ChildCompiler{$$self} = $or_compiler;
    return $or_compiler->make_matcher(%args);

}

=head2 get_child_compiler

Returns the child Compiler, or undef if not defined.

=cut

sub get_child_compiler {
    my $self = shift;
    return $ChildCompiler{$$self};
}

=head2 get_weight

Delegates to ChildCompiler child.

=cut

sub get_weight {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->get_weight(@_)
        : $self->SUPER::get_weight(@_);
}

=head2 get_similarity

Delegates to ChildCompiler child.

=cut

sub get_similarity {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->get_similarity(@_)
        : $self->SUPER::get_similarity(@_);
}

=head2 normalize

Delegates to ChildCompiler child.

=cut

sub normalize {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->normalize(@_)
        : $self->SUPER::normalize(@_);
}

=head2 sum_of_squared_weights

Delegates to ChildCompiler child.

=cut

sub sum_of_squared_weights {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->sum_of_squared_weights(@_)
        : $self->SUPER::sum_of_squared_weights(@_);
}

=head2 highlight_spans

Delegates to ChildCompiler child.

=cut

sub highlight_spans {
    my $self = shift;
    return $self->get_child_compiler
        ? $self->get_child_compiler->highlight_spans(@_)
        : $self->SUPER::highlight_spans(@_);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lucyx-search-wildcardquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LucyX-Search-NullTermQuery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LucyX::Search::NullTermQuery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LucyX-Search-NullTermQuery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LucyX-Search-NullTermQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LucyX-Search-NullTermQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/LucyX-Search-NullTermQuery/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
