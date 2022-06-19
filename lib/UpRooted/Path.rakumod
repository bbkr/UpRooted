unit class UpRooted::Path;

=begin pod

=head1 NAME

UpRooted::Path

=head1 DESCRIPTION

Represents how to reach one L<UpRooted::Table> from another L<UpRooted::Table>
through chain of L<UpRooted::Relation>s.

=head1 SYNOPSIS

    my $path = UpRooted::Path.new( :$root-table, :$leaf-table );
    $path.analyze-relations( :@relations1 );
    $path.analyze-relations( :@relations2 );
    $path.analyze-relations( :@relations3 );

    say $path.nullable;
    say $path.order;
    say $path.relations;

Proper way of constructing L<UpRooted::Path> is to analyze all L<UpRooted::Relation>s chains
from root L<UpRooted::Table> to leaf L<UpRooted::Table>.

Only then L<UpRooted::Path> will get full context and will be able to determine
such things as dump order and best way to reach data in leaf L<UpRooted::Table>.

=head1 ATTRIBUTES

=head2 root-table

Which L<UpRooted::Table> starts the minimum spanning tree.

=end pod

has $.root-table is required;

=begin pod

=head2 leaf-table

From which L<UpRooted::Table> data should be extracted.
Can be the same as root.

=end pod

has $.leaf-table is required;

=begin pod

=head2 order

In which order leaf L<UpRooted::Table> should be dumped
to have all dependencies in parent L<UpRooted::Table>s met.

Many L<UpRooted::Path>s can have the same order,
which means L<UpRooted::Table> with order 0 (root) should be dumped first,
then all L<UpRooted::Table>s with order 1, all L<UpRooted::Table>s with order 2, and so on.

Tech note: This is equal to longest L<UpRooted::Relation>s chain
from root L<UpRooted::Table> to leaf L<UpRooted::Table>.

=end pod

has $.order = 0;


=begin pod

=head2 relations

Describes how to reach leaf L<UpRooted::Table> from root L<UpRooted::Table>.
Will die if L<UpRooted::Relation>s chain was not established.

Tech note 1: This is equal to shortest chain of not nullable L<UpRooted::Relation>s
from root L<UpRooted::Table> to leaf L<UpRooted::Table>.
It is guaranteed that by following those L<UpRooted::Relation>s from row in root L<UpRooted::Table>
all data will be reached.

Tech note 2: If chain of not nullable L<UpRooted::Relation>s is not available
then shortest chain of nullable L<UpRooted::Relation>s also guarantee that all data will be reached.
Except "horse riddle" situation: L<https://github.com/bbkr/exodus#opaque-uniqueness-aka-horse-riddle>.

Tech note 3: Horse riddle occurs when there are two chains of L<UpRooted::Relation>s.
They fork at some L<UpRooted::Table>,
then each chain contains nullable L<UpRooted::Relation> somewhere along the way
and finally they join at other L<UpRooted::Table>. For example following root to leaf:

    A ------------> X --nullable--> B
    A ------------> Y --nullable--> B

    A --nullable--> X ------------> B
    A ------------> Y --nullable--> B

In both cases two L<UpRooted::Path>s fork at L<UpRooted::Table> C<A>,
then each L<UpRooted::Path> has at least one nullable L<UpRooted::Relation>
before they join at L<UpRooted::Table> C<B>.

=end pod

has @!relations;

method relations {
    
    die sprintf 'No Relations in Path between Table %s and Table %s.', $.root-table.name, $.leaf-table.name
        unless $.root-table === $.leaf-table or @!relations;
    
    return @!relations;
}

=begin pod

=head1 METHODS

=head2 analyze-relations

Check if new chain of L<UpRooted::Relation>s gives additional insight
how and in which order to reach leaf L<UpRooted::Table>.

=end pod

method analyze-relations ( :@relations where { .elems } ) {
    
    die sprintf 'Relations root Table is different than %s.', $.root-table.name
        unless @relations.first.parent-table === $.root-table;
    
    for @relations.rotor( 2 => -1 ) -> ( $a, $b ) {
        die sprintf 'Relations are not consistent.'
            unless $a.child-table === $b.parent-table;
    }
    
    die sprintf 'Relations leaf Table is different than %s.', $.leaf-table.name
        unless @relations.last.child-table === $.leaf-table;
    
}