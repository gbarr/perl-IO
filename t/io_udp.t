#!./perl

BEGIN {
    unless(grep /blib/, @INC) {
	chdir 't' if -d 't';
	@INC = '../lib' if -d '../lib';
    }
}

use Config;

BEGIN {
    if(-d "lib" && -f "TEST") {
        if ( ($Config{'extensions'} !~ /\bSocket\b/ ||
              $Config{'extensions'} !~ /\bIO\b/	||
	      $^O eq 'os2')    &&
              !(($^O eq 'VMS') && $Config{d_socket})) {
	    print "1..0\n";
	    exit 0;
        }
    }
}

$| = 1;
print "1..4\n";

use Socket;
use IO::Socket qw(AF_INET SOCK_DGRAM INADDR_ANY);

$udpa = IO::Socket::INET->new(Proto => 'udp', LocalAddr => 'localhost')
	or die "$!";

print "ok 1\n";

$udpb = IO::Socket::INET->new(Proto => 'udp', LocalAddr => 'localhost')
	or die "$!";

print "ok 2\n";

$udpa->send("ok 3\n",0,$udpb->sockname);
$udpb->recv($buf="",5);
print $buf;

$udpb->send("ok 4\n");
$udpa->recv($buf="",5);
print $buf;
