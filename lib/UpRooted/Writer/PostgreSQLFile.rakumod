use UpRooted::Writer;
use UpRooted::Writer::Helper::FileInsert;
use UpRooted::Helper::Quoter;
use DBIish;
use DBDish::Pg::Native;

unit class UpRooted::Writer::PostgreSQLFile does UpRooted::Writer does UpRooted::Writer::Helper::FileInsert does UpRooted::Helper::Quoter;

=begin pod

=head1 NAME

UpRooted::Writer::PostgreSQLFile

=head1 DESCRIPTION

Writes data from L<UpRooted::Reader> as C<.sql> file compatible with PostgreSQL database.

=head1 SYNOPSIS

    use UpRooted::Writer::PostgreSQLFile;
    
    my $writer = UpRooted::Writer::PostgreSQLFile.new(
        file-naming => sub ( $tree, %conditions ) {
            %conditions{ 'id' } ~ '.sql'
        }
    );
    
    $writer.write( $reader, id => 1 );
    $writer.write( $reader, id => 2 );

=head1 ATTRIBUTES

=head2 file-naming

Optional subroutine that can generate names for subsequent reads.
Should accept L<UpRooted::Tree> and conditions passed to L<UpRooted::Reader>.

If not provided C<out.sql> file in current directory will be created.

File must not be present.

=end pod

has $!driver;

submethod TWEAK {
    
    # use 'out.sql' as default file name
    $!file-naming //= sub ( $tree, %conditions ) {
        return 'out.sql';
    };

    # connect to PostgreSQL driver to get access to PostgreSQL quoting function
    # without having actual database connection
    DBIish.new.install-driver( 'Pg' );    
    $!driver = PGconn.new( { } );
    
}

method !quote-identifier ( Str:D $id! ) {

    return $!driver.quote( $id, :as-id );
}

method !quote-constant ( $value!, $type ) {

    return 'NULL' unless $value.defined;
    
    given $value {
        when Bool {
            return $value ?? 'TRUE' !! 'FALSE';
        }
        when Int|Num|Rat {
            return $value;
        }
        when Str {
            return $!driver.quote( $value );
        }
        when Buf {
            # convert back to text Buf that was read from text field
            # (UpRooted does not support non UTF-8 encodings)
            return $!driver.quote( $value.decode( ) )
                if $type.defined && $type.ends-with( 'text' );

            # bytea format
            # (note that driver offers escapeBytea function
            # but it returns data in octal format that requires further casting
            # so unpack is used as more straightforward)
            use experimental :pack;
            return '\'\\x' ~ $value.unpack( 'H*') ~ '\'';
        }
        when Array {
            # this is a bit restricted because we do not have array type hint in information schema,
            # also it is OK to have inner ARRAY keyword:
            # ARRAY[ [ 1, 2 ], [ 3, 4 ] ] (commonly known) is the same as ARRAY[ ARRAY[ 1, 2 ], ARRAY[ 3, 4 ] ]
            return 'ARRAY[ ' ~  $value.map( { samewith( self, $_, Any:U ) } ).join( ', ' ) ~ ' ]';
        }
        default {
            # best guess for everything else is to stringify and cast to type
            my $out = $!driver.quote( $value.Str );
            $out ~= '::' ~ $type if defined $type;
        }
    }
        
}

submethod DESTROY {
    
    $!driver.PQfinish( );
    
}
