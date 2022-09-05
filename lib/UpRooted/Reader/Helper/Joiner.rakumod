use UpRooted::Reader;

unit role UpRooted::Reader::Helper::Joiner;

=begin pod

=head1 NAME

UpRooted::Reader::Helper::Joiner

=head1 DESCRIPTION

Converts L<UpRooted::Path>s in L<UpRooted::Tree> to series of JOIN
to reach data in leaf L<UpRooted::Table>s starting from given row in root L<UpRooted::Table>.

Requires L<UpRooted::Helper::DBIConnection> to be used by class composing this role.

=head1 METHODS

=head2 read-path

Accepts L<DBIish> compatible connection, L<UpRooted::Path> and root L<UpRooted::Table> conditions.
Converts L<UpRooted::Path> to query, executes it and produces rows that can be collected by C<gather>.

=end pod

method !read-path ( :$path, :%conditions ) {
    
    # get list of columns from leaf Table
    my $query-select = 'SELECT ';
    my @query-select-columns = $path.leaf-table.columns.map: { self!column-fqn( $_ ) };
    $query-select ~= @query-select-columns.join: ', ';
    
    # make chain of joins from root Table to leaf Table
    my $query-from = 'FROM ';
    my @query-from-tables = self!table-fqn( $.tree.root-table );
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
    
    # add root Table conditions, the same for all root to leaf chains
    my $query-where = 'WHERE ';
    if %conditions {
        my @query-where-conditions = %conditions.sort.map: {
            self!column-fqn( $.tree.root-table.column( .key ) ) ~ ' = ' ~ $.connection.quote( .value.Str )
        };
        $query-where ~= @query-where-conditions.join: ' AND ';
    }
    else {
        $query-where ~= 'TRUE';
    }
    
    # compose final query
    my $query = ( $query-select, $query-from, $query-where ).join( ' ' );

    # execute query and allow to gather results by caller
    my $statement = $.connection.execute( $query );
    while my @row := $statement.row( ) {
        take @row;
    }
    $statement.dispose( );
    
}
