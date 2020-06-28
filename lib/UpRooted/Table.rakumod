unit class UpRooted::Table;

has $.schema is required;
has Str $.name is required;
has %.columns;
has @.parent-relations;


submethod BUILD ( :$!schema, Str:D :$!name! ) {

	die 'Table already present!'
		if $!schema.tables{ $!name }:exists;
	
	$!schema.tables{ $!name } = self;
}
