#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'LucyX::Search::NullQuery' );
}

diag( "Testing LucyX::Search::NullQuery $LucyX::Search::NullQuery::VERSION, Perl $], $^X" );
