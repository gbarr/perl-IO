# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.8 1996/03/28 08:03:48 gbarr Exp $

#--- Configuration section ---

%install_pgm = ();

#--- End User Configuration - You should not have to change anything below this line

BEGIN { $^W = 1; }

$NAME     = 'IO';
$RELTYPE  = "";
$VFROM    = "IO::Handle";
$LINKTYPE = "dynamic";

$lib_only = 0;

#--- End Configuration

use ExtUtils::MakeMaker;
use ExtUtils::Manifest qw(maniread);
use FileHandle;

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

#--- End MY package

sub doIt
{
 my $manifest = maniread();
 
 my %PL_FILES = ();
 my %EXE_FILES = ();
 my %macro = ();

 #--- Install what ?
 
 foreach (keys %$manifest) {
  $PL_FILES{$_} = $1 if(/(.*)\.PL\Z/ && !/^Makefile.PL$/);
 
  if(m#\bbin/# && !m#demo#) {
   my $f = $_;
 
   $f =~ s#\.PL$##;
 
   if(defined $install_pgm{$f} && $install_pgm{$f}) {
    $EXE_FILES{$f} = 1 if(-x $f || -f "$f.PL");
   }
  }
 }
 
 %EXE_FILES = () if($lib_only);
 
 #--- Dist. VERSION
 
 unless(defined $VERSION)
  {
   my($pm,$rcs);
   my $fh = new FileHandle;
  
   my $PM = $VFROM || $NAME;
   ($pm = $PM . ".pm") =~ s,.*::,,;
   ($pm = $PM . ".pm") =~ s,::,/,g unless(-f $pm);
   $pm = "lib/" . $pm unless(-f $pm);
  
   if($fh->open($pm))
    {
     while (<$fh>)
      {
       chomp;
       next unless /\$([\w:]*\bVERSION)\b.*=/;
       my $module_version_variable = $1;
       my($eval) = "$_;";
       eval $eval;
       die "Could not eval '$eval': $@" if $@;
       $VERSION = $ {$module_version_variable};
       last;
      }
     close $fh;
    }
   else
    {
$VERSION = "0.05";
    }
  
   ($rcs = $pm) =~ s:([^/]+\.pm):RCS/$1,v:;
  
   # update VERSION when checked in
   $macro{CONFIGDEP} = $rcs
     if(-f $rcs);
  }
 
 $VERSION .= $RELTYPE
 	if(defined $RELTYPE);
 
 #--- Write the Makefile
 
 %hash = (
	VERSION   => $VERSION,
	NAME      => $NAME,
	PL_FILES  => \%PL_FILES,
	EXE_FILES => [ keys %EXE_FILES ],
 
	'linkext' => {LINKTYPE => $LINKTYPE || '' },
	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => 'gz', 
		      DIST_DEFAULT => 'all tardist',
		     },
 
	'clean'   => {FILES => join(" ", qw(*% *.html *.bak *.old lib/*% lib/*/*%),values %PL_FILES)},
 );

 $hash{macro} = \%macro
 	if(%macro);
 
 $hash{DISTNAME} = $DISTNAME
 	if(defined $DISTNAME);
 
 WriteMakefile( %hash ) ;
 
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

doIt();

