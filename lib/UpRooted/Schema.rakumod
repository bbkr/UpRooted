unit class UpRooted::Schema;

use UpRooted::Table;
use UpRooted::Column;
use UpRooted::Relation;

=begin pod

This schema represents relations between tables and cares about relations ONLY.
It is not meant to be user-friendly ORM.

Because of various cross-references and internal graph calculations
user should NEVER compose schema manually form Table / Column / Relation objects.

=end pod


has %.tables;

#| Register relation between pair of columns and check basic consistency.
method register-relation (
    Str:D :$name!,
    Str:D :$parent-table-name!, Str:D :$parent-column-name!,
    Str:D :$child-table-name!, Str:D :$child-column-name!,
    Bool:D :$is-nullable!
) {
    # register both tables if not already known
    my $parent-table := %.tables{ $parent-table-name } // UpRooted::Table.new( name => $parent-table-name );
    my $child-table := %.tables{ $child-table-name } // UpRooted::Table.new( name => $child-table-name );
    
    # register both columns if not already known
    my $parent-column := $parent-table.columns{ $parent-column-name } // UpRooted::Column.new( name => $parent-column-name );
    my $child-column := $child-table.columns{ $child-column-name } // UpRooted::Column.new( name => $child-column-name, :$is-nullable );
    
    # if column in child table was already seen then current relation must have the same nullable flag
    UpRooted::Schema::X::Consistency.new(
        message => sprintf( 'Column %s in table %s  was already defined with different is-nullable setting.', $child-column-name, $child-table-name )
    ).throw( ) if $child-column.is-nullable xor $is-nullable;
    
    # relation is already known, additional pair of columns must be appended to it
    with %tables.values.parent-relations{ $name } -> $relation {
        
        # if relation of given name was already seen then current relation must point to the same parent table
        # TODO this should check constraint name uniqueness globally.
        UpRooted::Schema::X::Consistency.new(
            message => sprintf( 'Relation %s in table %s was already defined with different parent table.', $name, $child-table-name )
        ).throw( ) if $relation.parent-table ne $parent-table-name;
        
        # append next pair of columns to current relation
        $relation.parent-columns.push: $parent-column;
        $relation.child-columns.push: $child-column;
    }
    

}

class UpRooted::Schema::X is Exception { };

class UpRooted::Schema::X::Consistency is UpRooted::Schema::X { };

class UpRooted::Schema::X::SelfLoop is UpRooted::Schema::X { };