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

Let's say you have MySQL database and want to save user of `id = 1` from `users` table with all his data from other tables to `.sql` file. 

```raku
my $connection = DBIish.connect( 'mysql', host => ..., port => ..., ... );

use UpRooted::Schema::MySQL;
my $schema = UpRooted::Schema::MySQL.new( :$connection );

use UpRooted::Tree;
my $tree = UpRooted::Tree.new( root-table => $schema.table( 'users' ) );

use UpRooted::Reader::MySQL;
my $reader = UpRooted::Reader::MySQL.new( :$connection, :$tree );

use UpRooted::Writer::MySQLFile;
my $writer = UpRooted::Writer::MySQLFile.new( :!use-schema-name );
    
$writer.write( :$reader, id => 1 );
```

Your user will be saved as `out.sql` file.

## MODULES

This section explains role of every module in `UpRooted` stack and tells which variants of each module are available.

### UpRooted::Schema

`UpRooted::Schema` describes relation between `UpRooted::Tables`.

It can be discovered automatically by plugins like:
* `UpRooted::Schema::MySQL`

In rare cases you may need to construct or fine tune `UpRooted::Schema` manually. For example if you use MySQL MyISAM engine or MySQL partitioning. Without foreign keys relations between `UpRooted::Table`s cannot be discovered and must be defined manually. There is [separate manual](docs/Schema.md) describing this process.

Creating `UpRooted::Schema` must be done only once per database.

### UpRooted::Tree

`UpRooted::Tree` knows how to reach each leaf `UpRooted::Table` from chosen root `UpRooted::Table`.
It also resolves `UpRooted::Table`s order correctly to satisfy foreign key constraints, which is important for example when writing data tree to online database.

You can derive many `UpRooted::Tree`s from single `UpRooted::Schema`, depending on which root `UpRooted::Table` is used.

Creating `UpRooted::Tree` must be done only once per root `UpRooted::Table`.

### UpRooted::Reader

`UpRooted::Reader` transforms `UpRooted::Tree` to series of queries allowing to extract data that belong to given row in root `UpRooted::Table`. This is always database specific.

Available variants:
* `UpRooted::Reader::MySQL`

Creating `UpRooted::Reader` must be done only once per `Uprooted::Tree`.

## CACHING

Creating instances of modules mentioned above are hevay operations, especially on large schemas. You can reuse all of them for great speed improvement.

For example if you need to save multiple users you need to create `UpRooted::Schema`, `UpRooted::Tree`, `UpRooted::Reader` and `UpRooted::Writer` only once.

```raku
my $schema = ...;
my $tree = ...;
my $reader = ...;
my $writer = UpRooted::Writer::MySQLFile.new(
    # name generator to avoid file name conflicts
    name => sub ( %conditions ) {
        %conditions{ 'id' } ~ '.sql'
    }
);
    
$writer.write( :$reader, id => 1 );
$writer.write( :$reader, id => 2 );
$writer.write( :$reader, id => 3 );
```

It will create `1.sql`, `2.sql`, `3.sql` files without rediscovering everything every time.

## CONTACT

You can find me (and many awesome people who helped me to develop this module)
on irc.freenode.net #raku channel as **bbkr**.
