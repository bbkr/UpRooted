use UpRooted::Reader;

unit class UpRooted::Reader::MySQL does UpRooted::Reader;

=begin pod

=head1 NAME

UpRooted::Reader::MySQL

=head1 DESCRIPTION

Reads L<UpRooted::Tree> from MySQL database.

=head1 SYNOPSIS

    use UpRooted::Reader::MySQL;

    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., database => ... );
    my $reader = UpRooted::Reader::MySQL.new( :$connection, :$tree );

    for gather $reader.read( id => 1 ) {
        if $_ ~~ UpRooted::Table {
            say 'In Table ' ~ .name;
        }
        else {
            say 'there is row ' ~ $_;
        }
    }


=head1 ATTRIBUTES

=head2 connection

MySQL DBIish connection.
It must be kept open during every L<read( )> call.

=end pod

has $.connection is required;

method !read ( $path, %conditions ) {
    
    # get list of columns from leaf Table
    my $query-select = 'SELECT ';
    my @query-select-columns = $path.leaf-table.columns.map: { self!column-fqn( $_ ) };
    $query-select ~= @query-select-columns.join: ', ';
    
    # make chain of joins from root Table to leaf Table
    my $query-from = 'FROM ';
    my @query-from-tables = self!table-fqn( $!tree.root-table );
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
    
    my $query-where = 'WHERE ';
    if %conditions {
        my @query-where-conditions = %conditions.sort.map: {
            self!column-fqn( $!tree.root-table.column( .key ) ) ~ ' = ' ~ $!connection.quote( .value.Str )
        };
        $query-where ~= @query-where-conditions.join: ' AND ';
    }
    else {
        $query-where ~= 'TRUE';
    }
    
    my $query = ( $query-select, $query-from, $query-where ).join( ' ' );

    my $statement = $!connection.execute( $query );
    while my @row = $statement.row( ) {
        take @row;
    }
    $statement.dispose( );
    
}

# greatly speeds up subsequent read() calls
# by caching Fully Qualified Names quoted by driver
has %!fqns;

method !schema-fqn {
    
    return %!fqns{ $.tree.root-table.schema.WHICH } //= $!connection.quote( $.tree.root-table.schema.name, :as-id );
}

method !table-fqn ( $table ) {
    
    return %!fqns{ $table.WHICH } //= self!schema-fqn ~ '.' ~ $!connection.quote( $table.name, :as-id );
}

method !column-fqn ( $column ) {
    
    return %!fqns{ $column.WHICH } //= self!table-fqn( $column.table ) ~ '.' ~ $!connection.quote( $column.name, :as-id );
}
