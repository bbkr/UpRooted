unit class UpRooted::Table;

=begin pod

=head1 NAME

UpRooted::Table

=head1 DESCRIPTION

Represents Table level of relational database.

=head1 SYNOPSIS

    my $books = UpRooted::Table.new( schema => $library, name => 'books' );

=head1 ATTRIBUTES

=head2 schema

Which L<UpRooted::Schema> this Table belongs to.

=end pod

has $.schema is required;

=begin pod

=head2 name

Table name that will be second part of fully qualified naming convention C<schema.table.column>.

=end pod

has Str $.name is required;

has %!columns;
has %!child-relations;

submethod TWEAK {

	# register Table in Schema
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
    
    die sprintf 'Column %s is from different Table than %s.', $column.name, $.name
        unless $column.table === self;
        
	die sprintf 'Column %s has order conflict in Table %s.', $column.name, $.name, 
		if %!columns.values.grep: *.order == $column.order;
    
    die sprintf 'Column %s ia already present in Table %s.', $column.name, $.name
        if %!columns{ $column.name }:exists;
    
    %!columns{ $column.name } = $column;
}

=begin pod

=head2 column( $name )

Returns L<UpRooted::Column> of given C<$name>.

=end pod

method column ( Str:D $name! ) {
    
    die sprintf 'Column %s is not present in Table %s.', $name, $.name
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

Returns all L<UpRooted::Column>s in definition order (if given).

=end pod

multi method columns ( ) {

    return %!columns.values.sort: *.order;
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

