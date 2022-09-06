use UpRooted::Schema;
use UpRooted::Schema::Helper::Information;

unit class UpRooted::Schema::MySQL does UpRooted::Schema does UpRooted::Schema::Helper::Information;

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

=head1 CASE SENSITIVITY

Column names in C<information_schema> have different case in various MySQL implementations.
Always alias columns to have lowercased names in queries results.
For example:

    SELECT `sth` AS `sth` FROM `information_schema`.`sth` ...

UpRooted is always case sensitive in every aspect.
For example you can register two L<UpRooted::Table>s named C<foo> and C<Foo> in the same L<UpRooted::Schema>.
Or register two L<UpRooted::Column>s named C<bar> and C<Bar> in the same L<UpRooted::Table>.
While MySQL has always case insensitive columns, but tables case sensitivity depends on underlying system.
Always preserve cases of original names.

=end pod

submethod BUILD ( :$connection! ) {
    
    state $query-schemata = q{
        SELECT SCHEMA( ) AS name
    };
    
    state $query-tables = q{
        SELECT `table_name` AS `name`
        FROM `information_schema`.`tables`
        WHERE `table_schema` = DATABASE( )
            AND `table_type` = 'BASE TABLE'     -- exclude system tables and views
    };
    
    state $query-columns = qq{
        SELECT `column_name` AS `name`, `table_name` AS `table_name`,
            IF( `is_nullable` = 'YES', TRUE, FALSE ) AS `is_nullable`,
            `data_type` AS `type`, `ordinal_position` AS `order`
        FROM `information_schema`.`columns`
        WHERE `table_schema` = DATABASE( )
            AND `table_name` IN ( $query-tables )  -- exclude columns from views
        ORDER BY `table_name`
    };
    
    state $query-relations = q{
        SELECT `constraint_name` AS `name`,
            `referenced_table_name` AS `parent_table_name`, `referenced_column_name` AS `parent_column_name`,
            `table_name` AS `child_table_name`, `column_name` AS `child_column_name`
        FROM `information_schema`.`key_column_usage`
        WHERE `table_schema` = DATABASE( )
            AND `referenced_table_schema` = DATABASE( )         -- cross schema relations not supported here
            AND `position_in_unique_constraint` IS NOT NULL     -- skip everything that is not foreign key
        ORDER BY `constraint_name`, `position_in_unique_constraint`
    };
    
    $!name = self!discover( :$connection, :$query-schemata, :$query-tables, :$query-columns, :$query-relations );

}
