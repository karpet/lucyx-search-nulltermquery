package LucyX::Search::NOTNullQuery;
use strict;
use warnings;
use base qw( Lucy::Search::NOTQuery );
use Carp;
use LucyX::Search::NullQuery;

our $VERSION = '0.001';

=head1 NAME

LucyX::Search::NOTNullQuery - Lucy query extension

=head1 SYNOPSIS


 my $query = LucyX::Search::NOTNullQuery->new(
    term    => 'green*',
    field   => 'color',
 );
 my $hits = $searcher->hits( query => $query );
 
=head1 DESCRIPTION

If a NullQuery is equivalent to this:

 $term =~ m/$query/

then a NOTNullQuery is equivalent to this:

 $term !~ m/$query/

=head1 METHODS

This class isa Lucy::Search::NOTQuery subclass.
Only new or overridden methods are documented.

=head2 new( term => $term, field => $field )

Returns a NOTNullQuery.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $wc_query = LucyX::Search::NullQuery->new(%args);
    return $class->SUPER::new( negated_query => $wc_query, );
}

=head2 to_string

Returns the query clause the object represents.

=cut

sub to_string {
    my $self = shift;
    return "NOT " . $self->get_negated_query->to_string();
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

Copyright 2011 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
