use UpRooted::Writer;
use UpRooted::Writer::Helper::File;
use DBIish;
use DBDish::mysql::Native;

unit class UpRooted::Writer::MySQLFile does UpRooted::Writer does UpRooted::Writer::Helper::File;

=begin pod

=head1 NAME

UpRooted::Writer::MySQLFile

=head1 DESCRIPTION

Writes data from L<UpRooted::Reader> as C<.sql> file compatible with MySQL database.

=head1 SYNOPSIS

    use UpRooted::Writer::MySQLFile;
    
    my $writer = UpRooted::Writer::MySQLFile.new(
        file-naming => sub ( $tree, %conditions ) {
            %conditions{ 'id' } ~ '.sql'
        }
    );
    
    $writer.write( $reader, id => 1 );
    $writer.write( $reader, id => 2 );

=head1 ATTRIBUTES

=head2 use-schema-name

Controls if Schema name should be used in Fully Qualified Names in C<*-fqn> methods.
Disabling may be useful for example when UpRooted should read / write using whatever Schema is currently used in connection.

Default to C<True> (enabled).

=end pod

has $.use-schema-name = True;

=begin pod

=head2 file-naming

Optional subroutine that can generate names for subsequent reads.
Should accept L<UpRooted::Tree> and conditions passed to L<UpRooted::Reader>.

If not provided C<out.sql> file in current directory will be created.

File must not be present.

=end pod

has $!mysql-driver;
has %!sql-cache;

submethod TWEAK {
    
    # get access to diver quoting function without having connection
    DBIish.new.install-driver( 'mysql' );
    $!mysql-driver = DBDish::mysql::Native::MYSQL.mysql_init;
    
    # use 'out.sql' name unless custom file naming is specified
    $!file-naming //= sub ( $tree, %conditions ) {
        return 'out.sql';
    };

}

method !write-start ( $tree, %conditions ) {
    
    self!open-file( $!file-naming( $tree, %conditions ) );
    
}

method !write-table ( $table ) {
    
    # TODO there may be no data for given Table
    # this should only store current UpRooted::Table instance and be lazy
    my $query-insert = 'INSERT INTO ';
    $query-insert ~= self!quote-label( $table.schema.name ) ~ '.' if $.use-schema-name;
    $query-insert ~= self!quote-label( $table.name ) ~ ' ';
    my @query-insert-columns = $table.columns.map: { self!quote-label( $_.name ) };
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
        @query-values.push: self!quote-value( $value, :$is-binary );
    }
    
    my $query-values = '( ' ~ @query-values.join( ', ' )  ~ ' )';
    
    # full INSERT ... VALUES statement,
    # TODO batching - https://github.com/bbkr/UpRooted/issues/12
    self!write-file( %!sql-cache{ 'query-insert' } ~ $query-values ~ ";\n" );
    
}

method !write-flush ( ) {
    
    # TODO batching should close any unfinished query here
    
    # end of data for this Table
    %!sql-cache = ( );
}

method !write-end ( ) {
    
    self!close-file( );
}

method !quote-label ( Str:D $name ) {
    
    return '`' ~ $!mysql-driver.escape( $name ) ~ '`';
}

method !quote-value ( $value, Bool :$is-binary = False ) {

    if $value.defined {
        
        if $is-binary {
            
            # emulate mysqldump --hex-blob flag,
            # this is so far the safest way to store and load binary in MySQL
            return 'UNHEX( \'' ~ $!mysql-driver.escape( $value, :bin ) ~ '\' )';
        }
        else {
            
            given $value {
                when Buf {
                    return '\'' ~ $!mysql-driver.escape( $value.decode( ) ) ~ '\'';
                }
                when Str {
                    return '\'' ~ $!mysql-driver.escape( $value ) ~ '\'';
                }
                default {
                    return '\'' ~ $!mysql-driver.escape( $value.Str ) ~ '\'';
                }
            }
            
        }
    }
    else {
        
        return 'NULL';
    }
}

