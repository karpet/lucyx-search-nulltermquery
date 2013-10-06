#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'LucyX::Search::NullTermQuery' );
}

diag( "Testing LucyX::Search::NullTermQuery $LucyX::Search::NullTermQuery::VERSION, Perl $], $^X" );
