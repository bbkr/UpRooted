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
            say 'In table ' ~ .name;
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
Rows are in form of Array of values in the same order as L<UpRooted::Column>s in each L<UpRooted::Table>.

Accepts conditions for root L<UpRooted::Table>.
Conditions must have defined values and C<=> operator will be used to evaluate them.

This sequence can be C<gather>ed by L<UpRooted::Writer>.

=end pod

method read ( *%conditions ) {
    
    # conditions must match UpRooted::Columns in root UpRooted::Table
    sink $.tree.root-table.column( $_ ) for %conditions.keys;
    
    # all UpRooted::Paths will be returned in order that satisfies parent-child UpRooted::Tables dependencies
    for $.tree.paths -> $path {
        
        # take UpRooted::Table so that UpRooted::Writer will know how to handle rows that will follow
        take $path.leaf-table;
        
        # pass UpRooted::Path to specific implementation, it should take each row
        self!read-path( $path, %conditions );
    }

}

=begin pod

=head2 !read-path

Specific L<UpRooted::Reader> must implement this method.
It must convert L<UpRooted::Path> starting at root L<UpRooted::Table> with given C<%conditions>
to data rows that can be collected by C<gather>.

=end pod

method !read-path ( $path, %conditions ) { !!! };
