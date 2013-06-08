package LucyX::Search::NullMatcher;
use strict;
use warnings;
use base qw( Lucy::Search::Matcher );
use Carp;
use Data::Dump qw( dump );

our $VERSION = '0.001';

# Inside-out member vars.
my ( %doc_ids, %pos, %boosts, %sim, %term_freqs );

sub DESTROY {
    my $self = shift;
    delete $doc_ids{$$self};
    delete $pos{$$self};
    delete $boosts{$$self};
    delete $sim{$$self};
    delete $term_freqs{$$self};
    $self->SUPER::DESTROY;
}

=head1 NAME

LucyX::Search::NullMatcher - Lucy query extension

=head1 SYNOPSIS

 # see Lucy::Search::Matcher

=head1 METHODS

This class isa Lucy::Search::Matcher subclass.
Only new or overridden methods are documented.

=cut

=head2 new( I<args> )

Returns a new Scorer object.

=cut

sub new {
    my ( $class, %args ) = @_;

    my $compiler      = delete $args{compiler};
    my $posting_lists = delete $args{posting_lists};
    my $self          = $class->SUPER::new(%args);
    
    warn "posting_lists: " . dump($posting_lists);

    my %hits;    # The keys are the doc nums; the values the tfs.
    for my $posting_list (@$posting_lists) {
        warn "posting_list doc_freq: " . $posting_list->get_doc_freq();
        while ( my $doc_id = $posting_list->next ) {
            warn "doc_id=$doc_id";
            my $posting = $posting_list->get_posting;
            $hits{$doc_id} += $posting->get_freq;
        }
    }

    warn "hits: " . dump \%hits;

    $sim{$$self}        = $compiler->get_similarity;
    $doc_ids{$$self}    = [ sort { $a <=> $b } keys %hits ];
    $term_freqs{$$self} = \%hits;
    $pos{$$self}        = -1;
    $boosts{$$self}     = $compiler->get_boost;

    return $self;
}

=head2 next

Returns the next doc_id.

=cut

sub next {
    my $self    = shift;
    my $doc_ids = $doc_ids{$$self};
    return 0 if $pos{$$self} >= $#$doc_ids;
    return $doc_ids->[ ++$pos{$$self} ];
}

=head2 get_doc_id

Returns the doc_id for the current position.

=cut

sub get_doc_id {
    my $self = shift;
    my $pos  = $pos{$$self};
    my $dids = $doc_ids{$$self};
    return $pos < scalar @$dids ? $$dids[$pos] : 0;
}

=head2 score

Returns the score of the hit.

=cut

sub score {
    my $self      = shift;
    my $pos       = $pos{$$self};
    my $dids      = $doc_ids{$$self};
    my $boost     = $boosts{$$self};
    my $doc_id    = $$dids[$pos];
    my $term_freq = $term_freqs{$$self}->{$doc_id};

    carp "doc_id=$doc_id  term_freq=$term_freq  boost=$boost";
    return ( $boost * $sim{$$self}->tf($term_freq) ) / 10;
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

Copyright 2011 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
