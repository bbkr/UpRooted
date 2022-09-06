use UpRooted::Table;
use UpRooted::Column;
use UpRooted::Relation;

unit role UpRooted::Schema::Helper::Information;

=begin pod

=head1 NAME

UpRooted::Schema::Helper::Information

=head1 DESCRIPTION

Common code for discovering L<UpRooted::Schema>
from Information Schema: L<https://en.wikipedia.org/wiki/Information_schema>.

=head1 METHODS

=head2 discover

Expects connection and four queries. Each row in these queries should represent single entity and have following columns:

C<$query-schemata> - schema C<name>.

C<$query-tables> - table C<name>.

C<$query-columns> - C<table_name>, column C<name>, C<type>, C<is_nullable> and C<order> in table.

C<$query-relations> - constraint C<name>, C<parent_table_name>, C<parent_column_name>, C<child_table_name>, C<child_column_name>.

WARNING: All returned column names (not values) must be lowercased.

Returns schema name when discovery is complete
so that class composing this role can set C<$!name> attribute during construction.

=end pod

method !discover ( :$connection!, Str:D :$query-schemata!, Str:D :$query-tables!, Str:D :$query-columns!, Str:D :$query-relations! ) {
    
    sub fetch-array-of-hashes ( $connection, $query ) {
    
        my $statement = $connection.execute( $query );
        my @data = $statement.allrows( :array-of-hash );
        $statement.dispose( );
    
        return @data;
    }
    
    my $name = fetch-array-of-hashes( $connection, $query-schemata )[ 0 ]{ 'name' };
    
    for fetch-array-of-hashes( $connection, $query-tables ) -> %table {
        
        UpRooted::Table.new(
            schema => self,
            name => %table{ 'name' }
        );
        
    }

    for fetch-array-of-hashes( $connection, $query-columns ).classify( *{ 'table_name' } ).kv -> $name, @columns {

        my $table := self.table( $name );

        for @columns -> %column {

            UpRooted::Column.new(
                :$table,
                name => %column{ 'name' },
                type => %column{ 'type' }.lc,
                is-nullable => %column{ 'is_nullable' }.so,   # cast because not every database support true boolean values
                order => %column{ 'order' }
            );
            
        }
        
    }

    for fetch-array-of-hashes( $connection, $query-relations ).classify( *{ 'name' } ).kv -> $name, @columns {

        # it is impossible in known databases to have foreign key of given name referencing two different Tables
        # so it is safe to take parent and child Table names from first Column set
        my $parent-table := self.table( @columns.first{ 'parent_table_name' } );
        my $child-table := self.table( @columns.first{ 'child_table_name' } );

        UpRooted::Relation.new(
            parent-columns => $parent-table.columns( @columns.map: *{ 'parent_column_name' } ),
            child-columns => $child-table.columns( @columns.map: *{ 'child_column_name' } ),
            :$name
        );

    }
    
    return $name;
}
