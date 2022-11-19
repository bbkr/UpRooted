unit class UpRooted::Relation;

=begin pod

=head1 NAME

UpRooted::Relation

=head1 DESCRIPTION

Represents relation (constraint) between tables in relational database.

=head1 SYNOPSIS

    UpRooted::Relation.new(
        parent-columns => $library.table( 'authors' ).columns( 'id' ),
        child-columns => $library.table( 'books' ).columns( 'author_id' ),
        name => 'who-wrote-what'
    );

Amount of parent and child L<UpRooted::Column>s must be the same.

=head1 ATTRIBUTES

=head2 name

Unique name by which L<UpRooted::Relation> is identified.
Usually this is unique across whole database,
but only uniqueness per L<UpRooted::Table> is required here.

=end pod

has Str $.name is required;

=begin pod

=head2 is-blocked

Sometimes one L<UpRooted::Relation> between two L<UpRooted::Table>s
is less efficient to join these tables than another L<UpRooted::Relation>.

Sometimes there are L<UpRooted::Table>s that should not be included in L<UpRooted::Tree>,
for example referral connection causing jailbreak or not important large logs.

Blocking allows to not use specific L<UpRooted::Relation>
and if all L<UpRooted::Relation>s leading to L<UpRooted::Table> are skipped
to skip whole L<UpRooted::Table> as well.

Blocking must be applied before L<UpRooted::Tree> is derived.

=end pod

has Bool $.is-blocked is rw;

has @!parent-columns;
has @!child-columns;

submethod BUILD (
	:@!parent-columns! where { .elems },
	:@!child-columns! where { .elems },
	Str:D :$!name!,
    Bool:D :$!is-blocked = False
) {

	die sprintf 'Parent and child UpRooted::Columns count different in UpRooted::Relation %s.', $!name
		unless @!parent-columns.elems == @!child-columns.elems;

	die sprintf 'Parent UpRooted::Columns must be from the same UpRooted::Table in UpRooted::Relation %s.', $!name
		unless [===]( @!parent-columns.map: *.table );
	
	die sprintf 'Child UpRooted::Columns must be from the same UpRooted::Table in UpRooted::Relation %s.', $!name 
		unless [===]( @!child-columns.map: *.table );

}

submethod TWEAK {

	# register UpRooted::Relation in UpRooted::Table
    self.parent-table.add-child-relation( self );
}

=begin pod

=head2 parent-table

Returns L<UpRooted::Table> that is parent.

=end pod

method parent-table ( ) {
    
    return @!parent-columns.first.table;
}

=begin pod

=head2 child-table

Returns L<UpRooted::Table> that is child.

=end pod

method child-table ( ) {
    
    return @!child-columns.first.table;
}

=begin pod

=head2 parent-columns

Returns L<UpRooted::Column>s from parent L<UpRooted::Table> in database definition order.

=end pod

method parent-columns ( ) {
    
    return @!parent-columns;
}

=begin pod

=head2 child-columns

Returns L<UpRooted::Column>s from child L<UpRooted::Table> in database definition order.

=end pod

method child-columns ( ) {
    
    return @!child-columns;
}

=begin pod

=head2 is-nullable

L<UpRooted::Relation> is nullable if any L<UpRooted::Column>
from child L<UpRooted::Table> used in this L<UpRooted::Relation> is nullable.

Tech note: Not nullable L<UpRooted::Relation>s are extremely important for data extraction
because it is guaranteed to discover all rows in child L<UpRooted::Table> in given L<UpRooted::Tree>
by following this L<UpRooted::Relation> from all rows in parent L<UpRooted::Table>.

=end pod

method is-nullable ( ) {

    return [or]( @!child-columns>>.is-nullable )
}
