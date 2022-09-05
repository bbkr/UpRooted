use UpRooted::Writer;
use UpRooted::Helper::DBIConnection;

unit class UpRooted::Writer::MySQL does UpRooted::Writer does UpRooted::Helper::DBIConnection;

=begin pod

=head1 NAME

UpRooted::Writer::MySQL

=head1 DESCRIPTION

Writes data from L<UpRooted::Reader> to another MySQL database connection.

=head1 SYNOPSIS

    use UpRooted::Writer::MySQL;
    
    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., database => ... );
    my $writer = UpRooted::Writer::MySQL.new(
        :$connection
    );
    
    $writer.write( $reader, id => 1 );
    $writer.write( $reader, id => 2 );

Each write is made on transaction.

=end pod

has $!statement;

method !write-start ( $tree, %conditions ) {
    
    $.connection.execute( 'BEGIN' );
    
}

method !write-table ( $table ) {
    
    my $query-insert = 'INSERT INTO ' ~ self!table-fqn($table) ~ ' ';
    my @query-insert-columns = $table.columns.map: { self!column-fqn( $_ ) };
    $query-insert ~= '( ' ~ @query-insert-columns.join( ', ' ) ~ ' ) VALUES ';
    my @query-insert-values = '?' xx @query-insert-columns;
    $query-insert ~= '( ' ~  @query-insert-values.join( ', ' ) ~ ' )';
    
    $!statement = $.connection.prepare( $query-insert );

}

method !write-row ( @row ) {
    
    $!statement.execute( @row );
    
}

method !write-flush ( ) {
    
    $!statement.finish( );
    
}

method !write-end ( ) {
    
    $.connection.execute( 'COMMIT' );
    
}
