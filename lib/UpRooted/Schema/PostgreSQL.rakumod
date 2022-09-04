use UpRooted::Schema;
use UpRooted::Table;
use UpRooted::Column;
use UpRooted::Relation;

unit class UpRooted::Schema::PostgreSQL is UpRooted::Schema;

=begin pod

=head1 NAME

UpRooted::Schema::PostgreSQL

=head1 DESCRIPTION

Discovers L<UpRooted::Schema> from PostgreSQL database connection.

=head1 SYNOPSIS

    use UpRooted::Schema::PostgreSQL;

    my $connection = DBIish.connect( 'Pg', host => ..., port => ..., database => ... );
    my $schema = UpRooted::Schema::PostgreSQL.new( :$connection );

Note that C<database> MUST be specified for connection.

Connection is only used during construction
and may be closed after L<UpRooted::Schema> is created.

=head1 CASE SENSITIVITY

UpRooted is always case sensitive in every aspect and so is PostgreSQL.
For example you can register two L<UpRooted::Table>s named C<foo> and C<Foo> in the same L<UpRooted::Schema>.
Or register two L<UpRooted::Column>s named C<bar> and C<Bar> in the same L<UpRooted::Table>.
Always preserve cases of original names.

=head1 UNIQUE INDEX VS UNIQUE CONSTRAINT

This is common trap for MySQL users who are new to PostgreSQL.
Index is NOT the same as constraint despite having very similar effect from users perspective.
Consider following examples:

    CREATE TABLE "foo" (
        "id" int,
        PRIMARY KEY ( "id" )
    );
    CREATE TABLE "bar" (
        "foo_id" int,
        FOREIGN KEY ( "foo_id" ) REFERENCES "foo" ( "id" )
    );

This is constraint that uses underlying unique index.
Relations depending on constraint will be discovered as expected.

    CREATE TABLE "foo" (
        "id" int,
        UNIQUE ( "id" )
    );
    CREATE TABLE "bar" (
        "foo_id" int,
        FOREIGN KEY ( "foo_id" ) REFERENCES "foo" ( "id" )
    );

This is also constraint that uses underlying unique index.
Relations depending on constraint will be discovered as expected.

    CREATE TABLE "foo" (
        "id" int
    );
    CREATE UNIQUE INDEX ON "foo" ( "id" );
    CREATE TABLE "bar" (
        "foo_id" int,
        FOREIGN KEY ( "foo_id" ) REFERENCES "foo" ( "id" )
    );

This is just unique index.
It will work as expected from data storage / consistency point of view
but relations depending on index will not be discovered as expected.

This is because L<UpRooted::Schema::PostgreSQL> uses on Information Schema
which contains information which unique constraint will be used during foreign key check
but does not contain information which underlying unique index will be used.

Solution 1 (best): Stay canonical, fix your database schema to use proper, explicit constraints.

Solution 2 (longest): Define L<UpRooted::Relation>s manually.

Solution 3 (partial hack): For single column relations there is hacky method where you can discover parent and child column relation by joining C<information_schema.key_column_usage> to C<information_schema.constraint_column_usage> using C<constraint_name>. However this will not work for multi column relations because you will not have information how to match order of columns in foreign key constraint to order of columns in unique constraint. You can edit query that discovers relations in your code to apply this hack if you do not use multi column relations.

Solution 4 (complete mod): This is possible when using PostgreSQL System Catalog instead of Information Schema. But System Catalog is order of magnitude more difficult to work with and its structure is not as stable as Information Schema between various PostgreSQL versions. Feel free to replace query that discovers relations in your code to one using System Catalog.

Solution 5: If you read up to this point you should really stop chasing the rabbit and apply Solution 1. Believe me, it is the easiest way out.

Worth reading: L<https://stackoverflow.com/questions/61249732/null-values-for-referential-constraints-unique-constraint-columns-in-informati>.

=end pod

method new ( :$connection! ) {
    
    state $select-schema = q{
        SELECT current_database( ) AS name
    };
    
    my $schema = self.bless( name => self!fetch-array-of-hashes( $connection, $select-schema )[ 0 ]{ 'name' } );
    
    state $select-tables = q{
        SELECT "table_name" AS "name"
        FROM "information_schema"."tables"
        WHERE "table_catalog" = CURRENT_DATABASE( )
            AND "table_schema" = CURRENT_SCHEMA( )  -- exclude system tables
            AND "table_type" = 'BASE TABLE'         -- exclude views
    };
    for self!fetch-array-of-hashes( $connection, $select-tables ) -> %table {
        UpRooted::Table.new(
            :$schema,
            name => %table{ 'name' }
        );
    }

    state $select-columns = qq{
        SELECT "column_name" AS "name", "table_name",
            CASE "is_nullable" WHEN 'YES' THEN TRUE ELSE FALSE END AS "is_nullable",
            "data_type" AS "type", "ordinal_position" AS "order"
        FROM "information_schema"."columns"
        WHERE "table_catalog" = CURRENT_DATABASE( )
            AND "table_schema" = CURRENT_SCHEMA( )
            AND "table_name" IN ( $select-tables )  -- exclude columns from views
        ORDER BY "table_name"
    };
    for self!fetch-array-of-hashes( $connection, $select-columns ).classify( *{ 'table_name' } ).kv -> $table_name, @columns {

        my $table := $schema.table( $table_name );

        for @columns -> %column {

            UpRooted::Column.new(
                :$table,
                name => %column{ 'name' },
                type => %column{ 'type' }.lc,
                is-nullable => %column{ 'is_nullable' },
                order => %column{ 'order' }
            );
        }
    }

    # we do not care if foreign key constraint is defined in catalog named differently than table catalog
    # as long as it finally matches table from current table catalog to another table from current table catalog,
    # in other words we do not enforce: "rc"."constraint_catalog" = "kcup"."table_catalog" = "kcuc"."table_catalog"
    state $select-relations = q{
        SELECT rc."constraint_name" AS name,
            "kcup"."table_name" AS "parent_table_name", "kcup"."column_name" AS "parent_column_name",
            "kcuc"."table_name" AS "child_table_name", "kcuc"."column_name" AS "child_column_name"
        FROM "information_schema"."referential_constraints" AS "rc"
        JOIN "information_schema"."key_column_usage" AS "kcup"
            ON "rc"."unique_constraint_catalog" = kcup."constraint_catalog"
            AND "rc"."unique_constraint_name" = "kcup"."constraint_name"
        JOIN "information_schema"."key_column_usage" AS "kcuc"
            ON "rc"."constraint_catalog" = "kcuc"."constraint_catalog"
            AND "rc"."constraint_name" = "kcuc"."constraint_name"
            AND "kcup"."ordinal_position" = "kcuc"."position_in_unique_constraint"
            AND "kcup"."table_catalog" = kcuc."table_catalog"
            AND kcup."table_schema" = "kcuc"."table_schema"
        WHERE
            "kcuc"."table_catalog" = CURRENT_DATABASE( )
            AND "kcuc"."table_schema" = CURRENT_SCHEMA( )
        ORDER BY "rc"."constraint_name", "kcuc"."position_in_unique_constraint"
    };
    for self!fetch-array-of-hashes( $connection, $select-relations ).classify( *{ 'name' } ).kv -> $relation_name, @columns {

        # it is impossible in PostgreSQL to have foreign key of given name referencing two different Tables
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

