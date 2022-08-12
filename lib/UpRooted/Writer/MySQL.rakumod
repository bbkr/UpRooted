use UpRooted::Writer;

unit class UpRooted::Writer::MySQL does UpRooted::Writer;

=begin pod

=head1 NAME

UpRooted::Writer::MySQL

=head1 DESCRIPTION

Writes data from L<UpRooted::Reader> as C<.sql> file compatible with MySQL database.

=head1 SYNOPSIS

    use UpRooted::Writer::MySQL;
    
    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., database => ... );
    my $writer = UpRooted::Writer::MySQL.new(
        :$connection
    );
    
    $writer.write( $reader, id => 1 );
    $writer.write( $reader, id => 2 );

Each write is made on transaction.

=head1 ATTRIBUTES

=head2 connection

MySQL DBIish connection.
It cannot have any opened transaction.

=end pod

has $.connection is required;
has $!statement;

method !write-start ( $tree, %conditions ) {
    
    $.connection.execute( 'BEGIN' );
    
}

method !write-table ( $table ) {
    
    my $query-insert = 'INSERT INTO ';
    $query-insert ~= $.connection.quote( $table.schema.name, :as-id ) ~ '.' if $.use-schema-name;
    $query-insert ~= $.connection.quote( $table.name, :as-id ) ~ ' ';
    my @query-insert-columns = $table.columns.map: { $.connection.quote( $_.name, :as-id ) };
    $query-insert ~= '( ' ~ @query-insert-columns.join( ', ' ) ~ ' ) VALUES ';
    my @query-insert-values = '?' xx @query-insert-columns;
    $query-insert ~= '( ' ~  @query-insert-values.join( ', ' ) ~ ' )';
    
    $!statement = $.connection.prepare( $query-insert );

}

method !write-row ( @row ) {
    
    $!statement.execute( @row );
    
}

method !write-flush ( ) {
    
    $!statement.finish( );
    
}

method !write-end ( ) {
    
    $.connection.execute( 'COMMIT' );
    
}
