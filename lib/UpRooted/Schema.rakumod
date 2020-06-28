unit class UpRooted::Schema;

use UpRooted::Table;
use UpRooted::Column;
use UpRooted::Relation;

=begin pod

This schema represents relations
and cares about relations ONLY.

It is not meant to be user-friendly ORM.
Hence the reversed construction flow
(for example column is created with table and not by table object)
and tons of circular references.

User should never compose schema in any other way 
than by using *.new methods.

=end pod

has %.tables;
