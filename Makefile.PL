# This -*- perl -*- script makes the Makefile

BEGIN { require 5.006_001 };
use ExtUtils::MakeMaker;
use Config qw(%Config);

#--- Attempt to find <poll.h>

my $define = "";

unless (exists $Config{'i_poll'}) {
  my @inc = split(/\s+/, join(" ", $Config{'usrinc'}, $Config{'incpth'}, $Config{'locincpth'}));
  foreach $path (@inc) {
    if (-f $path . "/poll.h") {
      $define .= "-DI_POLL ";
      last;
    }
  }
}

#--- Write the Makefile

WriteMakefile(
  VERSION_FROM => "IO.pm",
  NAME         => "IO",
  OBJECT       => '$(O_FILES)',
  INSTALLDIRS  => 'perl',
  ($define ? (DEFINE => $define) : ()),
);

sub MY::post_constants {
  return '' if $] >= 5.008;

  return <<'POST_CONST' if $^O eq 'MSWin32';

XSUBPPARGS = $(XSUBPPARGS) -typemap mytypemap

POST_CONST

  return <<'POST_CONST';

XSUBPPARGS +=  -typemap mytypemap

POST_CONST

}


