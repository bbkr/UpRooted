unit class UpRooted::Cartographer;

use UpRooted::Schema;
use UpRooted::Table;
use UpRooted::Column;
use UpRooted::Relation;

=begin pod

=head1 NAME

UpRooted::Cartographer

=head1 DESCRIPTION

Auto discovers L<UpRooted::Schema>.
Discovery method for specific technology must be implemented in child class.

=head1 SYNOPSIS

Please refer to specific child class for usage details.

=head1 METHODS

=head2 schema

Returns L<UpRooted::Schema> discovered from given database.

Note that L<UpRooted::Relation>s across multiple L<UpRooted::Schema>s
will be skipped and must be added manually if needed.

=end pod

method schema () { ... }
