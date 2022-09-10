use UpRooted::Helper::DBIConnection;

unit role UpRooted::Reader::Helper::DBISelect does UpRooted::Helper::DBIConnection;

=begin pod

=head1 NAME

UpRooted::Reader::Helper::DBISelect

=head1 DESCRIPTION

Converts L<UpRooted::Path> to SELECT ... JOIN ... JOIN .. WHERE query
to reach data in leaf L<UpRooted::Table>s starting from given row in root L<UpRooted::Table>.

=head1 METHODS

=head2 !read-path

Requires L<UpRooted::Path> and root L<UpRooted::Table> conditions.
Converts L<UpRooted::Path> to query, executes it and produces rows that can be collected by C<gather>.

=end pod

method !read-path ( $path, %conditions ) {
    
    # get list of UpRooted::Column names from leaf UpRooted::Table
    my $query-select = 'SELECT ';
    my @query-select-columns = $path.leaf-table.columns.map: { self!column-fqn( $_ ) };
    $query-select ~= @query-select-columns.join: ', ';
    
    # make chain of joins from root UpRooted::Table to leaf UpRooted::Table
    my $query-from = 'FROM ';
    my @query-from-tables = self!table-fqn( $path.root-table );
    for $path.relations -> $relation {
        
        my $query-join ~= 'JOIN ' ~ self!table-fqn( $relation.child-table ) ~ ' ON ';
        my @query-join-conditions;
        for $relation.parent-columns Z $relation.child-columns -> ( $parent-column, $child-column ) {
            @query-join-conditions.push: self!column-fqn( $parent-column ) ~ ' = ' ~ self!column-fqn( $child-column );
        }
        $query-join ~= @query-join-conditions.join: ' AND ';
        @query-from-tables.push: $query-join;
    }
    $query-from ~= @query-from-tables.join: ' ';
    
    # add root UpRooted::Table conditions
    # it will be the same for all UpRooted::Paths
    my $query-where = 'WHERE ';
    if %conditions {
        my @query-where-conditions = %conditions.sort.map: {
            self!column-fqn( $path.root-table.column( .key ) ) ~ ' = ' ~ self.connection.quote( .value.Str )
        };
        $query-where ~= @query-where-conditions.join: ' AND ';
    }
    else {
        $query-where ~= 'TRUE';
    }
    
    # compose final query
    my $query = ( $query-select, $query-from, $query-where ).join( ' ' );

    # execute query and allow to gather results by caller
    my $statement = self.connection.execute( $query );
    while my @row := $statement.row( ) {
        take @row;
    }
    $statement.dispose( );
    
}
