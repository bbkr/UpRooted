use UpRooted::Schema;
use UpRooted::Table;
use UpRooted::Column;
use UpRooted::Relation;

unit class UpRooted::Schema::MySQL is UpRooted::Schema;

=begin pod

=head1 NAME

UpRooted::Schema::MySQL

=head1 DESCRIPTION

Discovers L<UpRooted::Schema> from MySQL database connection.
Compatible with MySQL, Percona and MariaDB.

=head1 SYNOPSIS

    use UpRooted::Schema::MySQL;

    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., database => ... );
    my $schema = UpRooted::Schema::MySQL.new( :$connection );

Note that C<database> MUST be specified for connection.

Connection is only used during construction
and may be closed after L<UpRooted::Schema> is created.

=head1 CASE SENSITIVITY WARNINGS

Column names in C<information_schema> have different case in various MySQL implementations.
Always alias columns to have lowercased names as Hash keys.
For example:

    SELECT `sth` AS `sth` FROM `information_schema`.`sth` ...

UpRooted is always case sensitive in every aspect.
For example you can register two L<UpRooted::Table>s named C<foo> and C<Foo> in the same L<UpRooted::Schema>.
Or register two L<UpRooted::Column>s named C<bar> and C<Bar> in the same L<UpRooted::Table>.
While MySQL has always case insensitive columns, but tables case sensitivity depends on underlying system.
Always preserve cases of original names.

=end pod

method new ( :$connection! ) {
    
    state $select-schema = q{
        SELECT DATABASE( ) AS name
    };
    
    my $schema = self.bless( name => self!fetch-array-of-hashes( $connection, $select-schema )[ 0 ]{ 'name' } );
    
    state $select-tables = q{
        SELECT `table_name` AS `name`
        FROM `information_schema`.`tables`
        WHERE `table_schema` = DATABASE( )
            AND `table_type` = 'BASE TABLE'     -- exclude system tables and views
    };
    for self!fetch-array-of-hashes( $connection, $select-tables ) -> %table {
        UpRooted::Table.new(
            :$schema,
            name => %table{ 'name' }
        );
    }

    state $select-columns = qq{
        SELECT `column_name` AS `name`, `table_name` AS `table_name`,
            IF( `is_nullable` = 'YES', TRUE, FALSE ) AS `nullable`, `ordinal_position` AS `order`
        FROM `information_schema`.`columns`
        WHERE `table_schema` = DATABASE( )
            AND `table_name` IN ( $select-tables )  -- exclude columns from views
        ORDER BY `table_name`
    };
    for self!fetch-array-of-hashes( $connection, $select-columns ).classify( *{ 'table_name' } ).kv -> $table_name, @columns {

        my $table := $schema.table( $table_name );

        for @columns -> %column {

            UpRooted::Column.new(
                :$table,
                name => %column{ 'name' },
                nullable => %column{ 'nullable' }.so,   # cast because MySQL does not support true boolean values
                order => %column{ 'order' }
            );
        }
    }

    state $select-relations = q{
        SELECT `constraint_name` AS `name`,
            `referenced_table_name` AS `parent_table_name`, `referenced_column_name` AS `parent_column_name`,
            `table_name` AS `child_table_name`, `column_name` AS `child_column_name`
        FROM `information_schema`.`key_column_usage`
        WHERE `table_schema` = DATABASE( )
            AND `referenced_table_schema` = DATABASE( )         -- cross schema relations not supported here
            AND `position_in_unique_constraint` IS NOT NULL     -- skip everything that is not foreign key
        ORDER BY `constraint_name`, `position_in_unique_constraint`
    };
    for self!fetch-array-of-hashes( $connection, $select-relations ).classify( *{ 'name' } ).kv -> $relation_name, @columns {

        # it is impossible in MySQL to have foreign key of given name referencing two different Tables
        # so it is safe to take parent and child Table names from first Column set
        my $parent-table := $schema.table( @columns.first{ 'parent_table_name' } );
        my $child-table := $schema.table( @columns.first{ 'child_table_name' } );

        UpRooted::Relation.new(
            parent-columns => $parent-table.columns( @columns.map: *{ 'parent_column_name' } ),
            child-columns => $child-table.columns( @columns.map: *{ 'child_column_name' } ),
            name => $relation_name
        );

    }
    
    return $schema;
}

method !fetch-array-of-hashes ( $connection, Str:D $query, *@params ) {
    
    my $statement = $connection.execute( $query, |@params );
    my @data = $statement.allrows( :array-of-hash );
    $statement.dispose( );
    
    return @data;
}

