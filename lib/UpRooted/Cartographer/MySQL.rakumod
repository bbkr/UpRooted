use UpRooted::Cartographer;
use UpRooted::Cartographer::Source::DBIish;

unit class UpRooted::Cartographer::MySQL
is UpRooted::Cartographer
does UpRooted::Cartographer::Source::DBIish;

=begin pod

=head1 NAME

UpRooted::Cartographer::MySQL

=head1 DESCRIPTION

Discovers L<UpRooted::Schema> from MySQL database.
Compatible with MySQL, Percona and MariaDB.

=head1 SYNOPSIS

    use UpRooted::Cartographer::MySQL;

    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., database => ... );
    my $schema = UpRooted::Cartographer::MySQL.new( :$connection ).schema( );

Note that C<database> MUST be specified for connection.

=end pod

method schema ( ) {
    my $schema;
    
    state $select-schema = q{
        SELECT DATABASE( ) AS name
    };
    $schema = UpRooted::Schema.new(
        name => self!fetch-array-of-hashes( $select-schema )[ 0 ]{ 'name' }
    );
    
    state $select-tables = q{
        SELECT `table_name` AS `name`
        FROM `information_schema`.`tables`
        WHERE `table_schema` = DATABASE( )
            AND `table_type` = 'BASE TABLE'     -- exclude system tables and views
    };
    for self!fetch-array-of-hashes( $select-tables ) -> %table {
        UpRooted::Table.new( :$schema, name => %table{ 'name' } );
    }

    state $select-columns = qq{
        SELECT `column_name` AS `name`, `table_name`,
            IF( `is_nullable` = 'YES', TRUE, FALSE ) AS `nullable`,
            LOWER( `data_type` ) AS `type`, `ordinal_position` AS `order`
        FROM `information_schema`.`columns`
        WHERE `table_schema` = DATABASE( )
            AND `table_name` IN ( $select-tables )  -- exclude columns from views
        ORDER BY `table_name`
    };
    for self!fetch-array-of-hashes( $select-columns ).classify( *{ 'table_name' } ).kv -> $table_name, @columns {

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

            UpRooted::Column.new( :$table, name => %column{ 'name' }, :$type, nullable => %column{ 'nullable' }.so, order => %column{ 'order' } );
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
    for self!fetch-array-of-hashes( $select-relations ).classify( *{ 'name' } ).kv -> $relation_name, @columns {
        
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
