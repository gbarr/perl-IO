#!./perl

$| = 1;
print "1..3\n";

use IO::Socket qw(AF_INET SOCK_DGRAM INADDR_ANY);

$udpa = IO::Socket::INET->new(Proto => 'udp', Addr => 'localhost');
$udpb = IO::Socket::INET->new(Proto => 'udp', Addr => 'localhost');

print "ok 1\n";

$udpa->send("ok 2\n",0,$udpb->sockname);
$udpb->recv($buf="",5);
print $buf;
$udpb->send("ok 3\n");
$udpa->recv($buf="",5);
print $buf;







