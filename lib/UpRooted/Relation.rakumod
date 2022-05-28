unit class UpRooted::Relation;

has Str $.name is required;
has @.parent-columns is required;
has @.child-columns is required;

submethod BUILD (
	Str:D :$!name!,
	:@!parent-columns! where { .elems },
	:@!child-columns! where { .elems }
) {
    
	die sprintf 'Parent Columns must be from the same Table in Relation %s.', $!name
		unless [===]( @!parent-columns.map: *.table );
	
	die sprintf 'Child columns must be from the same Table in Relation %s.', $!name 
		unless [===]( @!child-columns.map: *.table );
	
	die sprintf 'Parent and child Columns count different in Relation %s.', $!name
		unless @!parent-columns.elems == @!child-columns.elems;

}

submethod TWEAK {

	# register Relation in Table
    self.parent-table.add-relation( self );
}

method parent-table {
    @!parent-columns.first.table;
}

method child-table {
    @!child-columns.first.table;
}
