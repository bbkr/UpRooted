unit role UpRooted::Helper::DBIConnection;

=begin pod

=head1 NAME

UpRooted::Helper::DBIConnection

=head1 DESCRIPTION

Common role for every class that requires C<DBIish> compatible connection.

=head1 ATTRIBUTES

=head2 connection

Connection handle.
It cannot have any opened transaction when class composing this role is initialized.

=end pod

has $.connection is required;

=begin pod

=head2 use-schema-name

Controls if Schema name should be used in Fully Qualified Names in C<*-fqn> methods.
Disabling may be useful for example when UpRooted should read from / write to whatever Schema is currently used in connection.

Default to C<True> (enabled).

=end pod

has $.use-schema-name = True;

# cache for quoted Fully Qualified Names,
# greatly speeds up subsequent requests
has %!fqns;

=begin pod

=head1 METHODS

=head2 schema-fqn

Returns Fully Qualified Name of L<UpRooted::Schema> quoted by current connection driver.
Nothing is returned if L<use-schema-name> is set to C<False>.

=end pod

method !schema-fqn ( $schema ){
    
    return ( ) unless $.use-schema-name;
    return %!fqns{ $schema.WHICH } //= $.connection.quote( $schema.name, :as-id );
}

=begin pod

=head2 table-fqn

Returns Fully Qualified Name of L<UpRooted::Table> quoted by current connection driver.

=end pod

method !table-fqn ( $table ) {
    
    return %!fqns{ $table.WHICH } //= join( '.', self!schema-fqn( $table.schema ), $.connection.quote( $table.name, :as-id ) );
}

=begin pod

=head2 column-fqn

Returns Fully Qualified Name of L<UpRooted::Column> quoted by current connection driver.

=end pod

method !column-fqn ( $column ) {
    
    return %!fqns{ $column.WHICH } //= join( '.', self!table-fqn( $column.table ), $.connection.quote( $column.name, :as-id ) );
}
