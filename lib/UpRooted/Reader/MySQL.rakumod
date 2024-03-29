use UpRooted::Reader;
use UpRooted::Reader::Helper::DBISelect;

unit class UpRooted::Reader::MySQL does UpRooted::Reader does UpRooted::Reader::Helper::DBISelect;

=begin pod

=head1 NAME

UpRooted::Reader::MySQL

=head1 DESCRIPTION

Reads L<UpRooted::Tree> from MySQL database.

=head1 SYNOPSIS

    use UpRooted::Reader::MySQL;

    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., database => ... );
    my $reader = UpRooted::Reader::MySQL.new( :$connection, :$tree );

    for gather $reader.read( id => 1 ) {
        if $_ ~~ UpRooted::Table {
            say 'In table ' ~ .name;
        }
        else {
            say 'there is row ' ~ $_;
        }
    }

Connection must be kept open during every L<read( )> call.

=end pod
