unit role UpRooted::Reader;

=begin pod

=head1 NAME

UpRooted::Reader

=head1 DESCRIPTION

Reads data from L<UpRooted::Table>s for given L<UpRooted::Tree>.

Requires specific implementation for given database type.

=head1 SYNOPSIS

    my $reader = UpRooted::Reader.new( :$tree );
    for gather $reader.read( id => 1 ) {
        if $_ ~~ UpRooted::Table {
            say 'In Table ' ~ .name;
        }
        else {
            say 'there is row ' ~ $_;
        }
    }
    
=head1 ATTRIBUTES

=head2 tree

Which L<UpRooted::Tree> is data extracted from.

=end pod

has $.tree is required;

=begin pod

=head1 METHODS

=head2 read

Returns lazy list of L<UpRooted::Table>s, each one is followed by rows selected from it.
Accepts conditions for root L<UpRooted::Table>.

This list can be C<gather>ed by L<UpRooted::Writer>.

=end pod

method read ( *%conditions ) {
    
    # all Paths will be returned in order that satisfies parent-child Tables dependencies
    for $.tree.paths -> $path {
        
        # take Table so that Writer will know how to handle rows that will follow
        take $path.leaf-table;
        
        # pass Path to specific implementation, it should take each row
        self!read( $path, %conditions );
    }

}