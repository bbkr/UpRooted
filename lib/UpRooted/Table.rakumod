unit class UpRooted::Table;

=begin pod

=head1 NAME

UpRooted::Table

=head1 DESCRIPTION

Represents table level of relational database.

=head1 SYNOPSIS

    my $books = UpRooted::Table.new( schema => $library, name => 'books' );

=head1 ATTRIBUTES

=head2 schema

Which L<UpRooted::Schema> this L<UpRooted::Table> belongs to.

=end pod

has $.schema is required;

=begin pod

=head2 name

Table name that will be second part of Fully Qualified Naming convention C<schema.table.column>.

=end pod

has Str $.name is required;

has %!columns;
has %!children-relations;

submethod TWEAK {

	# register UpRooted::Table in UpRooted::Schema
    $!schema.add-table( self );

}

=begin pod

=head1 METHODS

=head2 add-column

Ties L<UpRooted::Column> to L<UpRooted::Table>.

This is done automatically when L<UpRooted::Column> is constructed
and you should NEVER call this method manually.

=end pod

method add-column ( $column! ) {
    
    die sprintf 'UpRooted::Column %s is from different UpRooted::Table than %s.', $column.name, $.name
        unless $column.table === self;
        
	die sprintf 'UpRooted::Column %s has order conflict in UpRooted::Table %s.', $column.name, $.name, 
		if %!columns.values.grep: *.order == $column.order;
    
    die sprintf 'UpRooted::Column %s ia already present in UpRooted::Table %s.', $column.name, $.name
        if %!columns{ $column.name }:exists;
    
    %!columns{ $column.name } = $column;
}

=begin pod

=head2 column( $name )

Returns L<UpRooted::Column> of given C<$name>.

=end pod

method column ( Str:D $name! ) {
    
    die sprintf 'UpRooted::Column %s is not present in UpRooted::Table %s.', $name, $.name
        unless %!columns{ $name }:exists;
    
    return %!columns{ $name };
}

=begin pod

=head2 columns( $name1, $name2, ... )

Returns L<UpRooted::Column>s of given C<$name>s in requested order.

=end pod

multi method columns ( *@names ) {

    return @names.map( { self.column( $_ ) } );
}

=begin pod

=head2 columns

Returns all L<UpRooted::Column>s in database definition order (if given).

=end pod

multi method columns ( ) {

    return %!columns.values.sort: *.order;
}

=begin pod

=head2 add-child-relation

Ties L<UpRooted::Relation> to L<UpRooted::Table>.

This is done automatically when L<UpRooted::Relation> is constructed
and you should NEVER call this method manually.

=end pod

method add-child-relation( $relation! ) {

    # UpRooted::Relation already checks if all UpRooted::Columns are from the same UpRooted::Table,
    # no need to check consistency for individual UpRooted::Columns
    die sprintf 'UpRooted::Relation %s is from different parent UpRooted::Table than %s.', $relation.name, $.name
        unless $relation.parent-table === self;
    
    die sprintf 'UpRooted::Relation %s ia already present in parent UpRooted::Table %s.', $relation.name, $.name
        if %!children-relations{ $relation.name }:exists;

    %!children-relations{ $relation.name } = $relation;

}

=begin pod

=head2 child-relation( $name )

Returns L<UpRooted::Relation> to child L<UpRooted::Table> of given C<$name>.

=end pod

method child-relation ( Str:D $name! ) {
    
    die sprintf 'UpRooted::Relation %s is not present in UpRooted::Table %s.', $name, $.name
        unless %!children-relations{ $name }:exists;
    
    return %!children-relations{ $name };
}

=begin pod

=head2 children-relations

Returns all L<UpRooted::Relation>s to child L<UpRooted::Table>s in L<UpRooted::Relation> name order.

=end pod

method children-relations ( ) {
    
    %!children-relations.values.sort( *.name );
}
