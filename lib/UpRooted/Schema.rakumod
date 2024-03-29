unit role UpRooted::Schema;

=begin pod

=head1 NAME

UpRooted::Schema

=head1 DESCRIPTION

Represents schema level of relational database.

=head1 SYNOPSIS

    my $library = UpRooted::Schema.new( name => 'library' );

=head1 ATTRIBUTES

=head2 name

Schema name that will be first part of Fully Qualified Naming convention C<schema.table.column>.

=end pod

has Str $.name is required;

has %!tables;

=begin pod

=head1 METHODS

=head2 add-table

Ties L<UpRooted::Table> to L<UpRooted::Schema>.

This is done automatically when L<UpRooted::Table> is constructed
and you should NEVER call this method manually.

=end pod

method add-table ( $table! ) {
    
    die sprintf 'UpRooted::Table %s is from different UpRooted::Schema than %s.', $table.name, $.name
        unless $table.schema === self;
    
    die sprintf 'UpRooted::Table %s ia already present in UpRooted::Schema %s.', $table.name, $.name
        if %!tables{ $table.name }:exists;
    
    %!tables{ $table.name } = $table;
}

=begin pod

=head2 table( $name )

Returns L<UpRooted::Table> of given C<$name>.

=end pod

method table ( Str:D $name! ) {
    
    die sprintf 'UpRooted::Table %s is not present in UpRooted::Schema %s.', $name, $.name
        unless %!tables{ $name }:exists;
    
    return %!tables{ $name };
}

=begin pod

=head2 tables

Returns all L<UpRooted::Table>s in alphabetical order.

=end pod

method tables ( ) {
    
    return %!tables.values.sort( *.name );
}
