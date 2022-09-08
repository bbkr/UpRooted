use UpRooted::Table;

unit role UpRooted::Writer;

=begin pod

=head1 NAME

UpRooted::Writer

=head1 DESCRIPTION

Writes data from L<UpRooted::Reader>.

Requires specific implementation for given output type.

=head1 SYNOPSIS

    my $writer = UpRooted::Writer.new( );
    $writer.write( :$reader, id => 1 );

If you need to write to schema of different name
you can skip original L<UpRooted::Schema> name in Fully Qualified Names by setting:

    my $writer = UpRooted::Writer.new( :!use-schema-name );
    
=head1 METHODS

=head2 write

Passes through conditions to L<UpRooted::Reader>
and forwards results to specific L<UpRooted::Writer> implementation.

Specific L<UpRooted::Writer> must implement following private methods:

Method C<write-start( UpRooted::Tree, %conditions )> is called first.
Allows to prepare general environment for writing,
for example creating directory "user-id=1" for future files.
For context L<UpRooted::Tree> and read conditions are passed.

Method C<write-table( UpRooted::Table )> is called when new L<UpRooted::Table> is read.
Allows to prepare things needed to save future rows of this L<UpRooted::Table>,
for example preparing query templates.
This method is always called for each L<UpRooted::Table> even if no rows will be returned.
It is up to specific L<UpRooted::Writer> implementation to decide what to do with empty L<UpRooted::Table>s.

Method C<write-data( @columns )> is called when new row is read.
Order of columns is the same as L<UpRooted::Column>s in L<UpRooted::Table>.

Method C<write-flush( )> is called when there will be no more data for current L<UpRooted::Table>
and allows to clean up things needed to save rows of this L<UpRooted::Table>.
Like for example freeing statements or writing all buffers to files.

Method C<write-end( )> is called last
and allows to summarize process and clean up general environment.
Like for example compressing files and announcing that data is ready.

=end pod

method write ( $reader, *%conditions ) {
    
    self!write-start( $reader.tree, %conditions );
    
    my $had-table = False;
    for gather $reader.read( |%conditions ) {

        if $_ ~~ UpRooted::Table {
            
            # flush only when next UpRooted::Table is gathered
            self!write-flush( ) if $had-table;
            $had-table = True;
            
            self!write-table( $_ );
        }
        else {
            self!write-row( $_ );
        }
        
        LAST self!write-flush( );
    }
    
    self!write-end();

}
