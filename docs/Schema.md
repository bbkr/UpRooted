# UpRooted::Schema

Guide for:

* People who want to write `UpRooted::Schema` auto-discovery plugins for various database technologies.
* Cases when auto discovery failed and `UpRooted::Schema` must be manually tuned.

# SYNOPSIS

Load required modules:

```raku
use UpRooted::Schema;
use UpRooted::Table;
use UpRooted::Column;
use UpRooted::Relation;
```

Define `UpRooted::Schema`:

```raku
my $library = UpRooted::Schema.new( name => 'library' );
```

Add `UpRooted::Table`s to `UpRooted::Schema`:

```raku
UpRooted::Table.new( :$schema, name => 'authors' );
UpRooted::Table.new( :$schema, name => 'books' );
```

Add `UpRooted::Columns` to `UpRooted::Tables`:

```raku
with $library.table( 'authors' ) -> $table {
    UpRooted::Column.new( :$table, name => 'id', type => 'bigint', :!is-nullable );
    UpRooted::Column.new( :$table, name => 'first_name', :is-nullable );
    UpRooted::Column.new( :$table, name => 'last_name', :!is-nullable );
}

with $library.table( 'books' ) -> $table {
    UpRooted::Column.new( :$table, name => 'id', type => 'bigint', :!is-nullable );
    UpRooted::Column.new( :$table, name => 'author_id', type => 'bigint', :!is-nullable );
    UpRooted::Column.new( :$table, name => 'title', :is-nullable );
}
```

Note that for `UpRooted::Column`:
* Nullability is super important for proper `UpRooted::Tree` construction later.
* You may provide original database type to help `Uprooted::Writer` make decision how to store data.

Connect `UpRooted::Tables` with `UpRooted::Relations`:

```raku
UpRooted::Relation.new(
    name => 'who-wrote-what',
    parent-columns => $library.table( 'authors' ).columns( 'id' ),
    child-columns => $library.table( 'books' ).columns( 'author_id' )
);
```

# RULES

It is **not** meant to be user-friendly ORM.
Limited interface is specifically designed to define and analyze database layout for further data extraction.

Bottom-up composition logic is used.
For example you do not tell `UpRooted::Schema` that it has some `UpRooted::Table`
but instead you define `UpRooted::Table` that claims to be in `UpRooted::Schema`.
This makes it easier to bulk-load data from denormalized `information_schema`s in various databases.

Top-down breacrumb trails like `$schema.table( 'x' ).column( 'y' )` will become automatically available and you can use them during further composition. Call `p6doc UpRooted::Table` for example to find out all available attributes.

**Never** add to `UpRooted::Schema` any virtual objects, such as views or materialized columns.

Composition will die on slightest sign of inconsistency, for example requesting unknown `UpRooted::Column` name from `UpRooted::Table`.

# ADVANCED

## Multi Column Relations

Just select multiple `UpRooted::Column`s from the same `UpRooted::Table` when defining `UpRooted::Relation`.

```raku
UpRooted::Relation.new(
    name => 'compatibility',
    parent-columns => $library.table( 'cars' ).columns( 'model', 'year' ),
    child-columns => $library.table( 'parts' ).columns( 'car_model', 'car_year' )
);
```

Arity must be the same.

## Cross Schema Relations

Just define two `UpRooted::Schema`s with `UpRooted::Table`s and `Uprooted::Column`s in them.
Then connect `Uprooted::Table`s from different `UpRooted::Schema`s using `UpRooted::Relation`s.

=head2 Differences between Schema and Tree

Schema represents entities in your database and relations between them.

Tree is subset of Schema with one Table being root.
You can derive many Trees from single Schema, depending which root Table is used.

Tree knows how and in which order reach data in all child Tables.

=head2 Caching

Once Schema is composed it can be reused for deriving multiple Trees.
Once Tree is derived it can be reused for reading data
for different Columns conditions in root Table.
