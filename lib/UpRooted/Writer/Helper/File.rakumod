unit role UpRooted::Writer::Helper::File;

has Code $.file-naming;
has IO::Handle $!file-handle;

method !open-file ( $path is copy ) {
    
    $path .= IO;
    
    die sprintf 'File %s already exsists.', $path.Str if $path ~~ :e & :f;
    
    $!file-handle = IO::Handle.new( :$path ).open( :rw );
    
}

method !write-file ( $text ) {
    
    $!file-handle.print( $text );
    
}

method !close-file ( ) {
    
    $!file-handle.close( );
    $!file-handle = Nil;
    
}
