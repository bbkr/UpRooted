use UpRooted::Helper::Quoter;

unit role UpRooted::Helper::FQN does UpRooted::Helper::Quoter;

=begin pod

=head1 NAME

UpRooted::Helper::FQN

=head1 DESCRIPTION

Creates Fully Qualified Names for database labels.

=head1 ATTRIBUTES

=head2 use-schema-name

Controls if L<UpRooted::Schema> name should be used in Fully Qualified Names in C<*-fqn> methods.
Disabling may be useful for example when UpRooted should read from / write to whatever schema is currently used in connection.

Default to C<True> (enabled).

=end pod

has Bool $.use-schema-name = True;

=begin pod

=head1 METHODS

=head2 schema-fqn

Returns Fully Qualified Name of L<UpRooted::Schema>.
Nothing is returned if L<use-schema-name> is set to C<False>.

=end pod

method !schema-fqn ( $schema ){
    
    return ( ) unless $.use-schema-name;
    return self!quote-name( $schema );
}

=begin pod

=head2 table-fqn

Returns Fully Qualified Name of L<UpRooted::Table>.

=end pod

method !table-fqn ( $table --> Str ) {
    
    return join( '.', self!schema-fqn( $table.schema ), self!quote-name( $table ) );
}

=begin pod

=head2 column-fqn

Returns Fully Qualified Name of L<UpRooted::Column>.

=end pod

method !column-fqn ( $column --> Str ) {
    
    return join( '.', self!table-fqn( $column.table ), self!quote-name( $column ) );
}
