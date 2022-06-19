unit role UpRooted::Schema::DBIish;

use DBIish;

has $.connection;

method !fetch-array-of-hashes ( Str:D $query, *@params ) {
    
    my $statement = $.connection.execute( $query, |@params );
    my @data = $statement.allrows( :array-of-hash );
    $statement.dispose( );
    
    return @data;
}
