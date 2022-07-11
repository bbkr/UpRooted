unit class UpRooted::Column;

=begin pod

=head1 NAME

UpRooted::Column

=head1 DESCRIPTION

Represents Column level of relational database.

=head1 SYNOPSIS

    UpRooted::Column.new( table => $books, name => 'title', type => Str, :!nullable, order => 2 );

=head1 ATTRIBUTES

=head2 table

Which L<UpRooted::Table> this L<UpRooted::Column> belongs to.

=end pod

has $.table is required;

=begin pod

=head2 name

Column name that will be third part of fully qualified naming convention C<schema.table.column>.

=end pod

has Str $.name is required;

=begin pod

=head2 nullable

Tells if value can be C<NULL>.

Tech note: This information is very important for proper data extraction!

=end pod

has Bool $.nullable is required;

=begin pod

=head2 order

Used for L<UpRooted::Writer> to save L<UpRooted::Column>s in the same order as defined in database.

Optional. If not given it will be the same order in which L<UpRooted::Column>s are added.

=end pod

has Int $.order;

submethod TWEAK {

	# if order is not provided use the one in which Columns are added
    $!order //= $!table.columns.elems + 1;
    
    # register Column in Table
    $!table.add-column( self );

}
