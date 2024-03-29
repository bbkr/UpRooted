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

Add `UpRooted::Column`s to `UpRooted::Table`s:

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
* You may provide original database type to help `UpRooted::Writer` make decision how to store data.

Connect `UpRooted::Table`s with `UpRooted::Relation`s:

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

## Multi column relations

Just select multiple `UpRooted::Column`s from the same `UpRooted::Table` when defining `UpRooted::Relation`.

```raku
UpRooted::Relation.new(
    name => 'compatibility',
    parent-columns => $library.table( 'cars' ).columns( 'model', 'year' ),
    child-columns => $library.table( 'parts' ).columns( 'car_model', 'car_year' )
);
```

Arity must be the same.

## Blocking relations

Sometimes one `UpRooted::Relation` between two `UpRooted::Table`s
is less efficient to join these tables than another `UpRooted::Relation`.
To block single `UpRooted::Relation` between two `UpRooted::Table`s set `is-blocked` attribute:

```raku
$parent-table.child-relation( 'some-relation-name' ).is-blocked = True;
```

Sometimes there is `UpRooted::Table` that should not be included in `UpRooted::Tree`,
for example referral connections causing jailbreak or not important large logs.
To exclude `UpRooted::Table` from `UpRooted::Tree` block all `UpRooted::Relation`s leading to this table:

```raku
for $schema.tables -> $table {
    for table.children-relations -> $relation {
        $relation.is-blocked = True if $relation.child-columns.first.table.name eq 'some-table-name';
    }
}
```

Blocking must be applied **before** `UpRooted::Tree` is derived.

## Cross schema relations

Just define two `UpRooted::Schema`s with `UpRooted::Table`s and `UpRooted::Column`s in them.
Then connect `UpRooted::Table`s from different `UpRooted::Schema`s using `UpRooted::Relation`s.
