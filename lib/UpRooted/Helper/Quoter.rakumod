unit role UpRooted::Helper::Quoter;

=begin pod

=head1 NAME

UpRooted::Helper::Quoter

=head1 DESCRIPTION

Provides quoting of names and values.

=end pod

has %!quote-cache;

=begin pod

=head1 METHODS

=head2 !quote-name

Quote C<name> attribute of whatever entity is passed as identifier.
Quoted name will be cached for faster subsequent calls.

=end pod

method !quote-name ( $entity! ) {
    
    return %!quote-cache{ $entity.name } //= self!quote-identifier( $entity.name );
}

=begin pod

=head2 !quote-value

Quote value as constant.

Optional type will be passed-through to quoting implementation
which allows to get more suitable quoting for target output.
For example allowing binary data to be escaped according to file format spec.

=end pod

method !quote-value ( $value!, $type ) {
    
    return self!quote-constant( $value, $type );
}

=begin pod

=head2 !quote-identifier

Raw String quoting as identifier must be provided when composing this Role.
In most cases this will be driver specific.

=end pod

method !quote-identifier ( Str:D $id! ) { !!! }

=begin pod

=head2 !quote-constant

Raw Any quoting as constant must be provided when composing this Role.
In most cases this will be driver specific.

=end pod

method !quote-constant ( $constant!, $type ) { !!! }
