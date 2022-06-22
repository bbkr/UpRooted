use UpRooted::Path;

unit class UpRooted::Tree;

=begin pod

=head1 NAME

UpRooted::Tree

=head1 DESCRIPTION

Describes how to reach all leaf L<UpRooted::Table>s from given root L<UpRooted::Table>.

Tech note 1: Technically L<UpRooted::Tree> is minimum spanning tree of directed graph,
where graph is represented as L<UpRooted::Schema>, nodes are represented as L<UpRooted::Table>s
and edges are represented as L<UpRooted::Relations>.
This spanning tree is saved as set of paths from root node to every other reachable node.

=head1 SYNOPSIS

    my $tree = UpRooted::Tree.new( root-table => $books );
    
    # how and in which order to reach each Table
    for my $tree.paths -> $path {
        say join '->', $path.root-table.name, $path.relations.map: *.child-table.name;
    }
    
=head1 ATTRIBUTES

=head2 root-table

Which L<UpRooted::Table> is tree root.

=end pod

has $.root-table is required;

has %!paths;

submethod BUILD ( :$!root-table ) {

    sub dfs ( *@relations ) {
    
        my $table;
        if @relations {
            # which Table is at the end of Relations chain
            $table = @relations.tail.child-table;
        }
        else {
            # if there are no Relations we are in Tree root
            $table = $!root-table;
        }
        
        # start new Path to leaf Table
        # or take existing one if leaf Table was already reached in the past
        my $path := %!paths{ $table.name } //= UpRooted::Path.new( root-table => $!root-table, leaf-table => $table );
        
        if @relations {
            # present new chain of Relations to Path for analysis
            my $continue = $path.analyze-relations( @relations );
            
            # circuit breaker when Path detects loop
            return unless $continue;
        }
        
        # DFS descent to child Tables
        for $table.children-relations -> $relation  {
            samewith( |@relations, $relation );
        }
        
    };
    
    dfs( );

}

=begin pod

=head2 paths

Returns L<UpRooted::Path>s from root L<UpRooted::Table> to all leaf L<UpRooted::Table>s
reachable by parent-child relation.

L<UpRooted::Path>s are sorted in a way that ensured every leaf L<UpRooted::Table>
will have its dependencies met.

This set of L<UpRooted::Path>s acts as instructions for L<UpRooted::Reader>.

=end pod

method paths ( ) {
    
    return %!paths.values.sort: { .order, .leaf-table.name };
}
