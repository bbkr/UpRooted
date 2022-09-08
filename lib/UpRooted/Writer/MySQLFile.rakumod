use UpRooted::Writer;
use UpRooted::Writer::Helper::File;
use UpRooted::Writer::Helper::FileInsert;
use UpRooted::Helper::DBIConnection;
use DBIish;
use DBDish::mysql::Native;

unit class UpRooted::Writer::MySQLFile does UpRooted::Writer does UpRooted::Writer::Helper::File does UpRooted::Writer::Helper::FileInsert does UpRooted::Helper::DBIConnection;

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

submethod BUILD ( :$use-schema-name, :$file-naming ) {

    $!use-schema-name = $use-schema-name // True;
    $!file-naming = $file-naming // sub ( $tree, %conditions ) {
        return 'out.sql';
    };
    
    # connect to MySQL driver to get access to MySQL quoting function
    # without having actual database connection
    DBIish.new.install-driver( 'mysql' );
    class Connection {
        has $.driver;

        submethod BUILD { $!driver = DBDish::mysql::Native::MYSQL.mysql_init( ) }

        submethod DESTROY {  $!driver.mysql_close( ) }

        method quote( Str $x, :$as-id ) {
            if $as-id {
                return q[`] ~ $.driver.escape( $x ) ~ q[`]
            } else {
                return q['] ~ $.driver.escape( $x ) ~ q[']
            }
        }
        
    }
    $!connection = Connection.new;
    
}

method !quote-value ( $value, Bool :$is-binary = False ) {

    if $value.defined {
        
        if $is-binary {
            
            # emulate mysqldump --hex-blob flag,
            # this is so far the safest way to store and load binary in MySQL
            return 'UNHEX( \'' ~ $.connection.driver.escape( $value, :bin ) ~ '\' )';
        }
        else {
            
            given $value {
                when Buf {
                    return $.connection.quote( $value.decode( ) );
                }
                when Str {
                    return $.connection.quote( $value );
                }
                default {
                    return $.connection.quote( $value.Str );
                }
            }
            
        }
    }
    else {
        
        return 'NULL';
    }
}
