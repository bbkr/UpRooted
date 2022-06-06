unit role UpRooted::Cartographer::Source::DBIish;

use DBIish;

has $.connection is required;

method !fetch-array-of-hashes ( Str:D $query, *@params ) {
    
    my $statement = $.connection.execute( $query, |@params );
    my @data = $statement.allrows( :array-of-hash );
    $statement.dispose( );
    
    return @data;
}