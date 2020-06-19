unit class UpRooted::Table;

has Str $name is required;

has %.columns;
has %.parent-relations;
has %.child-relations;

