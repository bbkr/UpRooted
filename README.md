# Extract subtrees of data from relational databases.

[![Build Status](https://travis-ci.org/bbkr/UpRooted.svg?branch=master)](https://travis-ci.org/bbkr/UpRooted)

## DESCRIPTION

WORK IN PROGRESS...
NOT USABLE YET...

This module allows to extract tree of data from relational database and process it.
Tree of data may be for example some user account and all records in related tables that belong to him.
Useful for cases like:

* Transferring users between database shards for better load balancing.
* Cloning user data from production environment to devel to debug some issues in isolated manner.
* Saving user state for backup or legal purposes.

This module is NOT continuous replication tool (like for example Debezium).

## SYNOPSIS

First you need to discover database `Schema`:

```raku
    use UpRooted::Schema::MySQL;

    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., ... );
    my $schema = UpRooted::Schema::MySQL.new( :$connection );
```

Then `Tree` must be constructed to determine how to reach data in leaf Tables from given root Table:

```raku
    use UpRooted::Tree;

    my $tree = UpRooted::Tree.new( root-table => $schema.table( 'users' ) );
```
( both `Schema` and `Tree` creation are expensive, you can cache and reuse them )

Actual data is obtained by `Reader` and stored by `Writer`.

```raku
    use UpRooted::Reader::MySQL;
    use UpRooted::Writer::CSV;

    my $reader = UpRooted::Reader::MySQL.new( :$connection, :$tree );
    my $writer = UpRooted::Writer::CSV.new( :!schema-prefix );
    
    $writer.write( $reader.read( id => 1 ) );
```

Your user from `users` `Table` with `id = 1` along with all his data from child `Tables` will be stored as set of CSV files:

```
0001-users.csv
0002-orders.csv
0003-payments.csv
...
```

Keep reading to find out which variants of each module are available, and maybe even how to implement your own.


## METHODS

## CONTACT

You can find me (and many awesome people who helped me to develop this module)
on irc.freenode.net #raku channel as **bbkr**.
