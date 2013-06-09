#!/usr/bin/env perl
use strict;
use warnings;
use Lucy;
use LucyX::Search::WildcardQuery;
use LucyX::Search::NullTermQuery;
use Benchmark qw(:all);

my $idx = shift(@ARGV) or die "$0 index\n";

my $idx_searcher = Lucy::Search::IndexSearcher->new( index => $idx );
my $searcher = Lucy::Search::PolySearcher->new(
    searchers => [$idx_searcher],
    schema    => $idx_searcher->get_schema(),
);

cmpthese(
    10,
    {   'wildcard' => sub {
            my $query = LucyX::Search::WildcardQuery->new(
                term  => '?*',
                field => 'swishdefault',
            );
            my $hits = $searcher->hits( query => $query );
        },
        'anyterm' => sub {
            my $query
                = LucyX::Search::AnyTermQuery->new( field => 'swishdefault',
                );
            my $hits = $searcher->hits( query => $query );
        },
        'nullterm' => sub {
            my $query
                = LucyX::Search::NullTermQuery->new( field => 'swishdefault',
                );
            my $hits = $searcher->hits( query => $query );
        },
    }
);
