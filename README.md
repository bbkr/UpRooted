# Extract subtrees of data from relational databases in [Raku](https://www.raku.org) language.

![Status](https://github.com/bbkr/UpRooted/actions/workflows/test.yml/badge.svg)

## DESCRIPTION

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
    
$writer.write( $reader, id => 1 );
```

Your user will be saved as `out.sql` file.

## MODULES

This section explains role of every module in `UpRooted` stack and tells which variants of each module are available.

### UpRooted::Schema

`UpRooted::Schema` describes relation between `UpRooted::Tables`.

It can be discovered automatically by plugins like:
* `UpRooted::Schema::MySQL`
* `UpRooted::Schema::PostgreSQL`

In rare cases you may need to construct or fine tune `UpRooted::Schema` manually. For example if you use MySQL MyISAM engine or MySQL partitioning. Or you use PostgreSQL foreign keys relying on unique keys instead of unique constraints. Without proper foreign keys relations between `UpRooted::Table`s cannot be auto discovered and must be defined by hand. There is [separate manual](docs/Schema.md) describing this process.

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
* `UpRooted::Reader::PostgreSQL`

Creating `UpRooted::Reader` must be done only once per `UpRooted::Tree`.

### UpRooted::Writer

`UpRooted::Writer` writes data provided by `UpRooted::Reader`.

Available variants:

* `UpRooted::Writer::MySQL` - Write directly to another MySQL database.
* `UpRooted::Writer::MySQLFile` - Write to `.sql` file compatible with MySQL.
* `UpRooted::Writer::PostgreSQL` (work in progress) - Write directly to another PostgreSQL database.
* `UpRooted::Writer::PostgreSQLFile` (work in progress) - Write to `.sql` file compatible with PostgreSQL.
* `UpRooted::Writer::JSONFiles` (work in progress) - Write to JSON files where each file is named after table and each line is single row from this table.
* `UpRooted::Writer::CSVFiles` (work in progress) - Write to CSV files where each file is named after table and each line except header is single row from this table.

Note that `UpRooted::Reader` and `UpRooted::Writer` are independent. You can read from MySQL database and write directly to PostgreSQL database if needed.

To find options accepted by each `UpRooted::Writer` call `p6doc` on chosen module.

Note that not every `UpRooted::Writer` can save every data type provided by `UpRooted::Reader`. For example CSV files cannot store binary data and you may need to provide convert function that will save it for example as Base64.

## CACHING

Creating instances of modules mentioned above are heavy operations, especially on large schemas. You can reuse all of them for great speed improvement.

For example if you need to save multiple users you need to create `UpRooted::Schema`, `UpRooted::Tree`, `UpRooted::Reader` and `UpRooted::Writer` only once.

```raku
my $schema = ...;
my $tree = ...;
my $reader = ...;
my $writer = UpRooted::Writer::MySQLFile.new(
    # name generator to avoid file name conflicts
    file-naming => sub ( $tree, %conditions ) {
        %conditions{ 'id' } ~ '.sql'
    }
);
    
$writer.write( :$reader, id => 1 );
$writer.write( :$reader, id => 2 );
$writer.write( :$reader, id => 3 );
```

It will create `1.sql`, `2.sql`, `3.sql` files without rediscovering everything every time.

## SCHEMA DESIGN ISSUES

### Data tree is not writable to another database without disabling foreign key constraints

By default `UpRooted` resolves dependencies and whole purpose of `UpRooted::Tree` is to provide data in correct order.

However it may be not possible if table is directly referencing itself.

```
    +----------+
    | users    |
    +----------+
    | id       |----------------------+
    | login    |                      |
    | password |                      |
    +----------+                      |
                                      |
              +--------------------+  |
              | albums             |  |
              +--------------------+  |
          +---| id                 |  |
          |   | user_id            |>-+
          +--<| parent_album_id    |
              | name               |
              +--------------------+
```

For example our database serves as photo management software and user has album with `id = 2` as subcategory of album with `id = 1`. Then he rearranges his collection, so that the album with `id = 2` is on top. In such scenario if database returned data tree rows in primary key order then it will not be possible to insert album with `id = 1` because it requires presence of album with `id = 2`. The fix is to have separate table that establishes hierarchy between rows:

```
    +----------+
    | users    |
    +----------+
    | id       |----------------------+
    | login    |                      |
    | password |                      |
    +----------+                      |
                                      |
              +--------------------+  |
              | albums             |  |
              +--------------------+  |
      +-+=====| id                 |  |
      | |     | user_id            |>-+
      | |     | name               |
      | |     +--------------------+
      | |
      | |    +------------------+
      | |    | album_hierarchy  |
      | |    +------------------+
      | +---<| parent_album_id  |
      +-----<| child_album_id   |
             +------------------+ 
```

### Data tree contains incomplete set of rows from some table

This happens if there are only multiple nullable relation paths to this table.

```
                  +----------+
                  | users    |
                  +----------+
    +-------------| id       |-------------+
    |             | login    |             |
    |             | password |             |
    |             +----------+             |
    |                                      |
    |  +-----------+        +-----------+  |
    |  | time      |        | distance  |  |
    |  +-----------+        +-----------+  |
    |  | id        |--+  +--| id        |  |
    +-<| user_id   |  |  |  | user_id   |>-+
       | amount    |  |  |  | amount    |
       +-----------+  |  |  +-----------+
                      |  |
                   (nullable)
                      |  |
                      |  |
             +--------+  +---------+
             |                     |
             |   +-------------+   |
             |   | parts       |   |
             |   +-------------+   |
             +--<| time_id     |   |
                 | distance_id |>--+
                 | name        |
                 +-------------+
```

This time our product is application that helps you with car maintenance schedule. Our users car has 4 tires that must be replaced after 10 years or 100000km and 4 spark plugs that must be replaced after 100000km. So 4 indistinguishable rows for tires are added to parts table (they reference both time and distance) and 4 indistinguishable rows are added for spark plugs (they reference only distance).

Now to extract to shard we have to find which rows from parts table does he own. By following relations through time table we will get 4 tires. But because this path is nullable at some point we are not sure if we found all records. And indeed, by following relations through distance table we found 4 tires and 4 spark plugs. Since this path is also nullable at some point we are not sure if we found all records. So we must combine result from time and distance paths, which gives us... 8 tires and 4 spark plugs? Well, that looks wrong. Maybe let's group it by time and distance pair, which gives us... 1 tire and 1 spark plug? So depending how you combine indistinguishable rows from many nullable paths to get final row set, you may suffer either data duplication or data loss.

To understand this issue better consider two answers to question `How many legs does the horse have?`:

* `Eight. Two front, two rear, two left and two right.` This answer is incorrect because each leg is counted multiple times from different nullable relations.
* `Four. Those attached to it.` This answer is correct because each leg is counted exactly once through not nullable relation.

The fix to horse riddle issue is to redesign schema so at least one not nullable relation leads to every table.

`UpRooted::Tree` will warn if this design error is detected (work in progress).

## CONTACT

You can find me (and many awesome people who helped me to develop this module)
on irc.freenode.net #raku channel as **bbkr**.
