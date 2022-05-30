unit class UpRooted::Relation;

=begin pod

=head1 NAME

UpRooted::Relation

=head1 DESCRIPTION

Represents Relation (constraint) between Tables in relational database.

=head1 SYNOPSIS

    UpRooted::Relation.new(
        name => 'who-wrote-what',
        parent-columns => $library.table( 'authors' ).column( 'id' ),
        child-columns => $library.table( 'books' ).column( 'author_id' )
    );

=head1 ATTRIBUTES

=head2 name

Unique name by which Relation is identified.

=end pod

has Str $.name is required;

=begin pod

=head2 parent-columns

List of Columns from parent Table that are referenced by from child Table.

=end pod

has @.parent-columns is required;

=begin pod

=head2 child-columns

List of Columns from Child Table reference Columns from parent Table.

=end pod

has @.child-columns is required;

submethod TWEAK {

    # die sprintf 'Parent and child Columns count must be positive in Relation %s.', $!name
    #     unless @!parent-columns.elems == @!child-columns.elems;
    
	die sprintf 'Parent and child Columns count different in Relation %s.', $!name
		unless @!parent-columns.elems == @!child-columns.elems;

	die sprintf 'Parent Columns must be from the same Table in Relation %s.', $!name
		unless [===]( @!parent-columns.map: *.table );
	
	die sprintf 'Child columns must be from the same Table in Relation %s.', $!name 
		unless [===]( @!child-columns.map: *.table );
        
	# register Relation in Table
    self.parent-table.add-relation( self );
}

method parent-table {
    @!parent-columns.first.table;
}

method child-table {
    @!child-columns.first.table;
}
