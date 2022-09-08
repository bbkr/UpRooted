unit role UpRooted::Writer::Helper::DBIInsert;

=begin pod

=head1 NAME

UpRooted::Writer::MySQL::Helper::DBIInsert

=head1 DESCRIPTION

Converts L<UpRooted::Table> and rows provided by L<UpRooted::Reader>
to INSERT INTO .. VALUES query executed on another DBI compatible database connection.

Requires L<UpRooted::Helper::DBIConnection> to be used by class composing this role.

Each write is made on transaction.

=end pod

has $!statement;

method !write-start ( $tree, %conditions ) {
    
    $.connection.execute( 'BEGIN' );
    
}

method !write-table ( $table ) {
    
    my $query-insert = 'INSERT INTO ' ~ self!table-fqn( $table ) ~ ' ';
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
