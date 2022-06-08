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

There are 4 actors involved.

First you need to discover database Schema by calling `Cartographer`:

```raku
    use UpRooted::Cartographer::MySQL;

    my $connection = DBIish.connect( 'mysql', host => ..., port => ..., ... );
    my $schema = UpRooted::Cartographer::MySQL.new( :$connection ).schema( );
```

Then `Navigator` must analyze Schema to find out how to reach data in related Tables from given root Table:

```raku
    use UpRooted::Navigator;

    my $tree = UpRooted::Navigator.new( :$schema ).tree( 'users' );
```

Actual data is obtained by `Extractor` and stored by `Recorder`.

```raku
    use UpRooted::Extractor::MySQL;
    use UpRooted::Recorder::CSV;

    my $extractor = UpRooted::Extractor::MySQL.new( connection => $dbh, :$tree );
    
    UpRooted::Recorder::CSV.new.store( $extractor.dig( id => 1 ) );
```

Your user from `users` `Table` with `id = 1` along with all his data from child `Tables` will be stored as set of CSV files:

```
0001-users.csv
0002-orders.csv
0003-payments.csv
...
```

Keep reading to find out which variants of each actor are available and how to implement your own.

## METHODS

## CONTACT

You can find me (and many awesome people who helped me to develop this module)
on irc.freenode.net #raku channel as **bbkr**.
