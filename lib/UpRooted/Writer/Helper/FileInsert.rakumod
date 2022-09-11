use UpRooted::Writer::Helper::File;
use UpRooted::Helper::FQN;

unit role UpRooted::Writer::Helper::FileInsert does UpRooted::Writer::Helper::File does UpRooted::Helper::FQN;

=begin pod

=head1 NAME

UpRooted::Writer::MySQL::Helper::FileInsert

=head1 DESCRIPTION

Implements L<UpRooted::Writer>.

Converts L<UpRooted::Table> and rows provided by L<UpRooted::Reader>
to INSERT INTO .. VALUES query saved to `.sql` file.

Requires L<UpRooted::Helper::DBIConnection> to be used by class composing this role.
Only specific driver connection is required for quoting access, no connection to actual database is needed.

Requires L<UpRooted::Writer::Helper::File> to be used by class composing this role.

Each write is made on transaction.

=end pod

has %!sql-cache;

method !write-start ( $tree, %conditions ) {
    
    self!open-file( $.file-naming.( $tree, %conditions ) );
    self!write-file( "BEGIN;\n" );
}

method !write-table ( $table ) {
    
    # TODO there may be no data for given UpRooted::Table
    # this should only store current UpRooted::Table instance and be lazy
    my $query-insert = 'INSERT INTO ' ~ self!table-fqn( $table ) ~ ' ';
    my @query-insert-columns = $table.columns.map: { self!quote-name( $_ ) };
    $query-insert ~= '( ' ~ @query-insert-columns.join( ', ' ) ~ ' ) VALUES ';
    
    # cache INSERT INTO part of query for subsequent row sets
    %!sql-cache{ 'query-insert' } = $query-insert;
    
    # helps to produce most DWIM-y output
    %!sql-cache{ 'column-types' } = $table.columns.map: *.type;

}

method !write-row ( @row ) {
    
    my @query-values;
    for @row.kv -> $index, $value {
        my $type := %!sql-cache{ 'column-types' }[ $index ];
        my $is-binary = $type.defined && $type.ends-with( 'blob' );
        @query-values.push: self!quote-constant( $value, :$is-binary );
    }
    
    my $query-values = '( ' ~ @query-values.join( ', ' )  ~ ' )';
    
    # full INSERT ... VALUES statement,
    # TODO batching - https://github.com/bbkr/UpRooted/issues/12
    self!write-file( %!sql-cache{ 'query-insert' } ~ $query-values ~ ";\n" );
    
}

method !write-flush ( ) {
    
    # TODO batching should close any unfinished query here
    
    # end of data for this UpRooted::Table
    %!sql-cache = ( );
}

method !write-end ( ) {
    
    self!write-file( "COMMIT;\n" );
    self!close-file( );
}
