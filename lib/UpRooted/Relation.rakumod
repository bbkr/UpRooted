unit class UpRooted::Relation;

has Str $.name is required;

has @.parent-columns is required;
has @.child-columns is required;

method parent-table {
    # every column belongs to the same table
    @.parent-columns.first.table;
}

method child-table {
    # every column belongs to the same table
    @.child-columns.first.table;
}
