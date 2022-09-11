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

method !quote-name ( $entity ) {
    
    return %!quote-cache{ $entity.name } //= self!quote-identifier( $entity.name );
}

=begin pod

=head2 !quote-identifier

Raw String quoting as identifier must be provided when composing this Role.
In most cases this will be driver specific.

=end pod

method !quote-identifier ( Str:D $id! ) { !!! }
