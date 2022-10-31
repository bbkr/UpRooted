use UpRooted::Writer;
use UpRooted::Writer::Helper::FileInsert;
use UpRooted::Helper::Quoter;
use DBIish;
use DBDish::mysql::Native;

unit class UpRooted::Writer::MySQLFile does UpRooted::Writer does UpRooted::Writer::Helper::FileInsert does UpRooted::Helper::Quoter;

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

    # connect to MySQL driver to get access to MySQL quoting function
    # without having actual database connection
    DBIish.new.install-driver( 'mysql' );
    $!driver = DBDish::mysql::Native::MYSQL.mysql_init( );
    
}

method !quote-identifier ( Str:D $id! --> Str ) {

    return '`' ~ $!driver.escape( $id ) ~ '`';
}

method !quote-constant ( $value!, $type ) {

    return 'NULL' unless $value.defined;
    
    given $value {
        when Buf {
            # convert back to text Buf that was read from text field
            # (UpRooted does not support non UTF-8 encodings)
            return '\'' ~ $!driver.escape( $value.decode( ) ) ~ '\''
                if $type.defined && $type.ends-with( 'text' );
            
            # emulate mysqldump --hex-blob flag,
            # this is so far the safest way to store and load binary in MySQL
            return 'UNHEX( \'' ~ $!driver.escape( $value, :bin ) ~ '\' )';
        }
        when Str {
            return '\'' ~ $!driver.escape( $value ) ~ '\'';
        }
        default {
            # BTW: this will also stringify nicely PostgreSQL array type
            # Array[Int].new( 1, 2, 3 ) will be saved as '1 2 3'
            return '\'' ~ $!driver.escape( $value.Str ) ~ '\'';
        }
    }
        
}

submethod DESTROY {
    
    $!driver.mysql_close( );
    
}
