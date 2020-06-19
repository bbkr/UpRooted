unit class UpRooted::Column;

has Str $.name is required;
has Bool $.is-nullable is required;

has $.table is required;
