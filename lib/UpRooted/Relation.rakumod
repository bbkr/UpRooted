unit class UpRooted::Relation;

=begin pod

=head1 NAME

UpRooted::Relation

=head1 DESCRIPTION

Represents Relation (constraint) between Tables in relational database.

=head1 SYNOPSIS

    UpRooted::Relation.new(
        parent-columns => $library.table( 'authors' ).columns( 'id' ),
        child-columns => $library.table( 'books' ).columns( 'author_id' ),
        name => 'who-wrote-what'
    );

Amount of parent and child Columns must be the same.

=head1 ATTRIBUTES

=head2 name

Unique name by which Relation is identified.
Usually this is unique across whole Schema,
but only uniqueness per Table is required. 

=end pod

has Str $.name is required;

has @!parent-columns;
has @!child-columns;

submethod BUILD (
	:@!parent-columns! where { .elems },
	:@!child-columns! where { .elems },
	Str:D :$!name!
) {

	die sprintf 'Parent and child Columns count different in Relation %s.', $!name
		unless @!parent-columns.elems == @!child-columns.elems;

	die sprintf 'Parent Columns must be from the same Table in Relation %s.', $!name
		unless [===]( @!parent-columns.map: *.table );
	
	die sprintf 'Child Columns must be from the same Table in Relation %s.', $!name 
		unless [===]( @!child-columns.map: *.table );

}

submethod TWEAK {

	# register Relation in Table
    self.parent-table.add-child-relation( self );
}

=begin pod

=head2 parent-table

Returns L<UpRooted::Table> that is parent.

=end pod

method parent-table ( ) {
    
    return @!parent-columns.first.table;
}

=begin pod

=head2 child-table

Returns L<UpRooted::Table> that is child.

=end pod

method child-table ( ) {
    
    return @!child-columns.first.table;
}

=begin pod

=head2 parent-columns

Returns L<UpRooted::Column>s from parent Table in Relation order.

=end pod

method parent-columns ( ) {
    
    return @!parent-columns;
}

=begin pod

=head2 child-columns

Returns L<UpRooted::Column>s from child Table in Relation order.

=end pod

method child-columns ( ) {
    
    return @!child-columns;
}

=begin pod

=head2 nullable

Relation is nullable if any Column from child Table used in this Relation is nullable.

Not nullable relations are extremely important for data extraction
because it is guaranteed to discover all rows in child Table in given Tree
by following this Relation from all rows in parent Table.

=end pod

method nullable ( ) {

    return [or]( @!child-columns>>.nullable )
}
