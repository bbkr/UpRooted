unit role UpRooted::Helper::DBIConnection;

=begin pod

=head1 NAME

UpRooted::Helper::DBIConnection

=head1 DESCRIPTION

Provides C<DBIish> compatible connection.

Implements L<UpRooted::Helper::Quoter> by exposing driver quoting.

=head1 ATTRIBUTES

=head2 connection

Connection handle.
It cannot have any opened transaction when Class composing this Role is initialized.

=end pod

has $.connection is required;

=begin pod

=head1 METHODS

=head2 !quote-identifier

Provides quotinq of database identifiers by current database driver.

=end pod

method !quote-identifier ( Str:D $id! ) {
    
    return $.connection.quote( $id, :as-id );
}

=begin pod

=head2 !quote-constant

Provides quotinq of database constants by current database driver.

Optional type is ignored at this level.

=end pod

method !quote-constant ( $constant!, $type ) {
    
    return $.connection.quote( $constant );
}
