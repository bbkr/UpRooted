unit class UpRooted::Relation;

has Str $.name is required;

has @.parent-columns is required;
has @.child-columns is required;

submethod BUILD (
	:@!parent-columns! where { .elems },
	:@!child-columns! where { .elems },
	Str:D :$!name!
) {

	die 'Parent columns must be from the same table!' 
		unless [===]( @!parent-columns );
	
	die 'Child columns must be from the same table!' 
		unless [===]( @!child-columns );
	
	die 'Parent and child columns count different!'
		unless @!parent-columns.elems == @!child-columns.elems;
	
	die 'Parent and child columns count different!'
		unless @!parent-columns.elems == @!child-columns.elems;
	
	die 'Relation already present in parent table!'
		if $!table.columns{ $!name }:exists;
	
	$!table.parent-relations{ $!name } = self;
}
