# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.8 1996/03/28 08:03:48 gbarr Exp $

require 5.002;
use ExtUtils::MakeMaker;

#--- MY package

sub MY::libscan
{
 my($self,$path) = @_;

 return '' 
	if($path =~ m:/(RCS|CVS|SCCS)/: ||
	   $path =~ m:[~%]$: ||
	   $path =~ m:\.(orig|rej)$:
	  );
 
 $path;
}

#--- Installation check

sub chk_version
{
 my($pkg,$wanted,$msg) = @_;

 $| = 1;
 print "Checking for $pkg...";

 eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

 my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
				 : "not found";
 my $vnum = ${"${pkg}::VERSION"} || 0;

 print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

 $vnum >= $wanted;
}

#--- Check for Socket

chk_version(Socket => '1.30') or
    warn  "\n"
	. "*** For IO::Socket to work you require version 1.30, or later, of\n"
	. "    Socket.pm from CPAN/modules/by-module/Socket/Socket-x.x.tar.gz\n\n";

#--- Write the Makefile

WriteMakefile(
	VERSION_FROM	=> "IO/Handle.pm",
	NAME      	=> "IO",
 
	'linkext' 	=> {LINKTYPE => 'dynamic' },
	'dist'    	=> {COMPRESS => 'gzip -9f',
			    SUFFIX   => 'gz', 
			    DIST_DEFAULT => 'all tardist',
			   },
 
	'clean'   	=> {FILES => join(" ",
					map { "$_ */$_ */*/$_" }
					qw(*% *.html *.b[ac]k *.old *.orig))
			   },
	'macro'		=> { INSTALLDIRS => 'perl' },
);
