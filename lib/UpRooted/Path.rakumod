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

has Int $!order = 0;

method order ( ) {
    
    # verify if Relations are established
    sink self.relations;
    
    return $!order;
}

=begin pod

=head2 is-looped

Looped L<UpRooted::Path> means that leaf L<UpRooted::Table>
occured in L<UpRooted::Relation>s chain as parent L<UpRooted::Table>.

Such data can be safely reached by L<UpRooted::Reader>
but there is no guarantee that it can be saved by all L<UpRooted::Writer>s.
For example there may be foreign keys issues when feeding it directly to other database
despite correct overall data consistency.

Sample looped L<UpRooted::Path>s following root to leaf:

    A -------> A

    A -------> B
    A <------- B

    A -------> B
         B -------> B

Loops should not be processed further by L<UpRooted::Tree> to avoid... infinite loop :)
In case of loop being detected C<False> must be returned by L<UpRooted::Path::analyze-relations> as circuit breaker.

Tech note: Only leaf L<UpRooted::Table> is important, those are NOT looped paths from A to C:

    A -------> B -------> C
    A <------- B

    A -------> B -------> C
          B -------> B

And they should never be analyzed. If they are encountered during analysis
it means L<UpRooted::Tree> did not stop properly.

=end pod

has Bool $!is-looped = False;

method is-looped ( --> Bool ) {
    
    # if for any reason looped UpRooted::Relations chain was analyzed first
    # then UpRooted::Path is known to be looped
    # without UpRooted::Relations between root and leaf UpRooted::Tables established
    return $!is-looped if $!is-looped;
    
    # verify if UpRooted::Relations are established
    sink self.relations;
    
    return $!is-looped;
}

=begin pod

=head2 is-ambiguous

Ambiguous L<UpRooted::Path> means that leaf L<UpRooted::Table>
can be reached by more than one nullable L<UpRooted::Relation>s chain
and can not be reached through not nullable L<UpRooted::Relation>s chain.

Example of ambiguous L<UpRooted::Path> with nullable L<UpRooted::Relation>s
between the same pair of L<UpRooted::Table>s.

    A ------------> X --nullable--> B
    A ------------> Y --nullable--> B

Example of ambiguous L<UpRooted::Path> with nullable L<UpRooted::Relation>s
between different L<UpRooted::Table>s.

    A --nullable--> X ------------> B
    A ------------> Y --nullable--> B

In this case most likely L<UpRooted::Reader> will not find every row in leaf L<UpRooted::Table>.

=end pod

has Bool $!is-ambiguous = False;

method is-ambiguous ( --> Bool ) {
    
    # verify if UpRooted::Relations are established
    sink self.relations;
    
    return $!is-ambiguous;
}

=begin pod

=head2 relations

Describes how to reach leaf L<UpRooted::Table> from root L<UpRooted::Table>.
Will die if L<UpRooted::Relation>s chain was not established.

This is equal to shortest chain of not nullable L<UpRooted::Relation>s
from root L<UpRooted::Table> to leaf L<UpRooted::Table>.
It is guaranteed that by following those L<UpRooted::Relation>s from row in root L<UpRooted::Table>
all data will be reached.

If chain of not nullable L<UpRooted::Relation>s is not available
then shortest chain of nullable L<UpRooted::Relation>s also guarantee that all data will be reached.
Except for cases described in L<is-ambiguous> flag.

=end pod

has @!relations;

method relations ( ) {
    
    die sprintf 'No UpRooted::Relations in UpRooted::Path between UpRooted::Table %s and UpRooted::Table %s.', $.root-table.name, $.leaf-table.name
        unless $.root-table === $.leaf-table or @!relations;
    
    return @!relations;
}

=begin pod

=head2 is-nullable

Path is nullable if any L<UpRooted::Relation> in it is nullable.
Can be called only after any L<UpRooted::Relation>s chain is established.

=end pod

method is-nullable ( --> Bool ) {
    
    return so self.relations.first: *.is-nullable;
}

=begin pod

=head1 METHODS

=head2 analyze-relations

Check if new chain of L<UpRooted::Relation>s gives additional insight
how and in which order to reach leaf L<UpRooted::Table>.

Will return C<True> if L<UpRooted::Tree> can proceed.
Or C<False> to indicate that loop occured
and this L<UpRooted::Relation>s chain should not be analyzed further.

=end pod

method analyze-relations ( *@relations where { .elems } --> Bool ) {
    
    die sprintf 'UpRooted::Relations root UpRooted::Table is different than %s.', $.root-table.name
        unless @relations.head.parent-table === $.root-table;
    
    for @relations.rotor( 2 => -1 ) -> ( $a, $b ) {
        die sprintf 'Parent UpRooted::Relation %s and child UpRooted::Relation %s are not referring to the same UpRooted::Table.', $a.name, $b.name
            unless $a.child-table === $b.parent-table;
    }
    
    for @relations[ ^( @relations.elems - 1 ) ] {
        state %parents;
        %parents{ .parent-table.name } = True;
        die sprintf 'UpRooted::Table %s seen twice before reaching leaf UpRooted::Table.', .child-table.name
            if %parents{ .child-table.name }:exists;
    }
        
    die sprintf 'UpRooted::Relations leaf UpRooted::Table is different than %s.', $.leaf-table.name
        unless @relations.tail.child-table === $.leaf-table;
    
    if @relations.first: *.parent-table === $.leaf-table {
        $!is-looped = True;
        return False;
    }
    
    # bump order to longest analyzed UpRooted::Relations chain
    $!order max= @relations.elems;
    
    if @!relations.elems.not {

        # any UpRooted::Relations chain is better than none
        @!relations = @relations;
        
    }
    elsif self.is-nullable {
        
        if so @relations.first: *.is-nullable {
        
            # more than one nullable UpRooted::Relations chain encountered
            $!is-ambiguous = True;
            
            # shorter nullable UpRooted::Relations chain is better than longer nullable one
            @!relations = @relations if @relations.elems < @!relations.elems;

        }
        else {

            # not nullable UpRooted::Relations chain is always better than nullable one, regardless of length
            @!relations = @relations;
            
            # not nullable UpRooted::Relations chain is never ambiguous
            $!is-ambiguous = False;
        
        }
    
    }
    else {
    
        if so @relations.first: *.is-nullable {
        
            # do nothing,
            # nullable UpRooted::Relations chain is worse than not nullable one, regardless of length

        }
        else {

            # shorter not nullable UpRooted::Relations chain is better than longer not nullable one
            @!relations = @relations if @relations.elems < @!relations.elems;
        
        }
    
    }
    
    return True;    
}