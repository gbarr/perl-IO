#

$^W = 1;

use ExtUtils::MakeMaker;

sub MY::libscan {
    my($self,$path) = @_;

    return '' 
	if($path =~ m:/(RCS|CVS|SCCS)/: ||
	   $path =~ m:[~%]$: ||
	   $path =~ m:\.(orig|rej)$: ||
	   $path =~ m:FileHandle.pm:
	  );
 
    $path;
}

WriteMakefile(	NAME	 => 'IO',
		VERSION_FROM => 'IO/Handle.pm',
		'clean'	 => {FILES => q[*/*% *% *.bak *.old]},
		'dist'   => {COMPRESS => 'gzip -9f',
			     SUFFIX   => 'gz', 
			     DIST_DEFAULT => 'all tardist',
			    },
	     );
