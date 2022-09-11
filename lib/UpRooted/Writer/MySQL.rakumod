use UpRooted::Writer;
use UpRooted::Writer::Helper::DBIInsert;

unit class UpRooted::Writer::MySQL does UpRooted::Writer does UpRooted::Writer::Helper::DBIInsert;

=begin pod

=head1 NAME

UpRooted::Writer::MySQL

=head1 DESCRIPTION

Writes data from L<UpRooted::Reader> to MySQL database connection.

=head1 SYNOPSIS

    use UpRooted::Writer::MySQL;
    
    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., database => ... );
    my $writer = UpRooted::Writer::MySQL.new(
        :$connection
    );
    
    $writer.write( $reader, id => 1 );
    $writer.write( $reader, id => 2 );

Each write is made on transaction.

If connection uses another schema name than in L<UpRooted::Reader>
then original L<UpRooted::Schema> name can be skipped
from Fully Qualified Names in statements by using C<use-schema-name> flag:

    my $writer = UpRooted::Writer::MySQL.new(
        :$connection,
        :!use-schema-name
    );

=end pod
