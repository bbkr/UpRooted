unit module DBITest;

use Test;

=begin pod

=head3 connect

Provide database connection for given driver, currently supported are C<mysql> and C<postgresql>.

It requires C<UPROOTED_DRIVER_HOST>, C<UPROOTED_DRIVER_PORT>, C<UPROOTED_DRIVER_USER>, C<UPROOTED_DRIVER_PASSWORD>
and C<UPROOTED_DRIVER_DATABASE> environment variables to be set. Where DRIVER is uppercased name of requested driver.

=end pod

sub connect ( $driver ) is export {

    sub env-name ( $which ) {
        return ( 'UPROOTED', $driver.uc, $which.uc ).join( '_' );
    }
    
    for 'host', 'port', 'user', 'password', 'database' {
        plan skip-all => env-name( $_ ) ~ ' environment variable not set' unless defined %*ENV{ env-name( $_ ) };
    }

    try { require ::( 'DBIish' ) }
    plan skip-all => 'DBIish module not installed.' if $!;
    use DBIish;

    my $connection = try {
        DBIish.connect(
            # postgres is weirdly named, remap it
            $driver eq 'postgresql' ?? 'Pg' !! $driver,
            host => %*ENV{ env-name( 'host' ) },
            port => %*ENV{ env-name( 'port' ) },
            user => %*ENV{ env-name( 'user' ) },
            password => %*ENV{ env-name( 'password' ) },
            database => %*ENV{ env-name( 'database' ) }
        )
    };
    plan skip-all => 'Connection not established.' if $!;

    # set of specific driver configurations
    $connection.execute( 'SET NAMES utf8mb4' ) if $driver eq 'mysql';

    return $connection;
}

sub load ( $connection, $directory, $file ) is export {

    for $*PROGRAM.parent.add( $directory.lc ).add( $file ).lines -> $line {
        state $query = '';

        # skip empty lines
        next unless $line.chars;

        # skip comments,
        # block comments are NOT supported
        next if $line ~~ / \s* '--' /;

        # accumulate statement lines
        $query ~= $line ~ "\n";

        # statement is complete
        if $line.ends-with( ';' ) {
            $connection.execute( $query );
            $query = '';
        }

    }

}