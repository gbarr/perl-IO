#!./perl
$| = 1;

use IO::File;
use IO::Seekable;

print "1..2\n";
use IO::File;
$x = new_tmpfile IO::File or print "not ";
print "ok 1\n";
print $x "ok 2\n";
$x->seek(0,SEEK_SET);
print <$x>;
