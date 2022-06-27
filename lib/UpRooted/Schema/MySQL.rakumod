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

=head1 WARNING

When modyfying this implementation remember that:

Column names in C<information_schema> have different case in various MySQL implementations.
Always alias columns to have lowercased names as Hash keys.

MySQL has case insensitive C<information_schema> lookups while L<UpRooted::*> is case sensitive.
Always convert values to lowercae variants to avoid weird errors.

=end pod

method new ( :$connection! ) {
    
    state $select-schema = q{
        SELECT LOWER( DATABASE( ) ) AS name
    };
    
    my $schema = self.bless( name => self!fetch-array-of-hashes( $connection, $select-schema )[ 0 ]{ 'name' } );
    
    state $select-tables = q{
        SELECT LOWER( `table_name` ) AS `name`
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
        SELECT LOWER( `column_name` ) AS `name`, LOWER( `table_name` ) AS `table_name`,
            IF( `is_nullable` = 'YES', TRUE, FALSE ) AS `nullable`,
            LOWER( `data_type` ) AS `type`, `ordinal_position` AS `order`
        FROM `information_schema`.`columns`
        WHERE `table_schema` = DATABASE( )
            AND `table_name` IN ( $select-tables )  -- exclude columns from views
        ORDER BY `table_name`
    };
    for self!fetch-array-of-hashes( $connection, $select-columns ).classify( *{ 'table_name' } ).kv -> $table_name, @columns {

        my $table := $schema.table( $table_name );

        for @columns -> %column {

            state %column-types = (
                'tinyint'       => Int,
                'smallint'      => Int,
                'mediumint'     => Int,
                'bigint'        => Int,
                'int'           => Int,
                'decimal'       => Rat,
                'float'         => Num,
                'double'        => Num,
                'tinyblob'      => Buf,
                'blob'          => Buf,
                'mediumblob'    => Buf,
                'longblob'      => Buf,
            );
            my $type = %column-types{ %column{ 'type' } }:exists ?? %column-types{ %column{ 'type' } } !! Str;

            UpRooted::Column.new(
                :$table,
                name => %column{ 'name' },
                :$type,
                nullable => %column{ 'nullable' }.so,   # cast because MySQL does not support true boolean values
                order => %column{ 'order' }
            );
        }
    }

    state $select-relations = q{
        SELECT LOWER( `constraint_name` ) AS `name`,
            LOWER( `referenced_table_name` ) AS `parent_table_name`, LOWER( `referenced_column_name` ) AS `parent_column_name`,
            LOWER( `table_name` ) AS `child_table_name`, LOWER( `column_name` ) AS `child_column_name`
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

