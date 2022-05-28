unit class UpRooted::Column;

has $.table is required;
has Str $.name is required;
has Bool $.nullable is required;

submethod TWEAK {

	# register Column in Table
    $!table.add-column( self );

}
