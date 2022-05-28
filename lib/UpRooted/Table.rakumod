unit class UpRooted::Table;

has $.schema is required;
has Str $.name is required;
has %!columns;
has %!child-relations;

submethod TWEAK {

	# register Table in Schema
    $!schema.add-table( self );

}

method add-column ( $column! ) {
    
    die sprintf 'Column %s ia already present in Table %s in Schema %s.', $column.name, $.name, $.schema.name
        if %!columns{ $column.name }:exists;
    
    %!columns{ $column.name } = $column;
}

method column ( Str:D $name! ) {
    
    die sprintf 'Column %s is not present in Table %s in Schema %s.', $name, $.name, $.schema.name
        unless %!columns{ $name }:exists;
    
    return %!columns{ $name };
}

method columns ( *@names ) {

    return @names.map: self.column( $_ );
}

# method add-relation( $relation! ) {
#
#     die 'Unexpected ', $column.name, $.name, $.schema.name
#         if %!columns{ $column.name }:exists;
#
#     die sprintf 'Relation %s ia already present in Table %s in Schema %s.', $column.name, $.name, $.schema.name
#         if %!columns{ $column.name }:exists;
#
# }
