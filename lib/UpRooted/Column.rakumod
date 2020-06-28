unit class UpRooted::Column;

has $.table is required;
has Str $.name is required;

submethod BUILD ( :$!table, Str:D :$!name!, Bool:D :$is-nullable! ) {

	die 'Column already present!'
		if $!table.columns{ $!name }:exists;
	
	$!table.columns{ $!name } = self;
}
