# IO::Socket::INET.pm
#
# Copyright (c) 1996 Graham Barr <gbarr@pobox.com>. All rights
# reserved. This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package IO::Socket::INET;

use strict;
use vars qw(@ISA $VERSION);
use IO::Socket;
use Socket;
use Carp;
use Exporter;

@ISA = qw(IO::Socket);
$VERSION = "1.20";

IO::Socket::INET->register_domain( AF_INET );

my %socket_type = ( tcp  => SOCK_STREAM,
		    udp  => SOCK_DGRAM,
		    icmp => SOCK_RAW
		  );

sub new {
    my $class = shift;
    unshift(@_, "PeerAddr") if @_ == 1;
    return $class->SUPER::new(@_);
}

sub _sock_info {
  my($addr,$port,$proto) = @_;
  my @proto = ();
  my @serv = ();

  $port = $1
	if(defined $addr && $addr =~ s,:([\w\(\)/]+)$,,);

  if(defined $proto) {
    @proto = $proto =~ m,\D, ? getprotobyname($proto)
			     : getprotobynumber($proto);

    $proto = $proto[2] || undef;
  }

  if(defined $port) {
    $port =~ s,\((\d+)\)$,,;

    my $defport = $1 || undef;
    my $pnum = ($port =~ m,^(\d+)$,)[0];

    @serv= getservbyname($port, $proto[0] || "")
	if($port =~ m,\D,);

    $port = $pnum || $serv[2] || $defport || undef;

    $proto = (getprotobyname($serv[3]))[2] || undef
	if @serv && !$proto;
  }

 return ($addr || undef,
	 $port || undef,
	 $proto || undef
	);
}

sub _error {
    my $sock = shift;
    $@ = join("",ref($sock),": ",@_);
    carp $@ if $^W;
    close($sock)
	if(defined fileno($sock));
    return undef;
}

sub configure {
    my($sock,$arg) = @_;
    my($lport,$rport,$laddr,$raddr,$proto,$type);


    ($laddr,$lport,$proto) = _sock_info($arg->{LocalAddr},
					$arg->{LocalPort},
					$arg->{Proto});

    $laddr = defined $laddr ? inet_aton($laddr)
			    : INADDR_ANY;

    return _error($sock,"Bad hostname '",$arg->{LocalAddr},"'")
	unless(defined $laddr);

    unless(exists $arg->{Listen}) {
	($raddr,$rport,$proto) = _sock_info($arg->{PeerAddr},
					    $arg->{PeerPort},
					    $proto);
    }

    if(defined $raddr) {
	$raddr = inet_aton($raddr);
	return _error($sock,"Bad hostname '",$arg->{PeerAddr},"'")
		unless(defined $raddr);
    }

    $proto ||= 'tcp';

    my $pname = (getprotobynumber($proto))[0];
    $type = $arg->{Type} || $socket_type{$pname};

    $sock->socket(AF_INET, $type, $proto) or
	return _error($sock,"$!");

    if ($arg->{Reuse}) {
	$sock->sockopt(SO_REUSEADDR,1) or
		return _error($sock);
    }

    if($lport || ($laddr ne INADDR_ANY) || exists $arg->{Listen}) {
	$sock->bind($lport || 0, $laddr) or
		return _error($sock,"$!");
    }

    if(exists $arg->{Listen}) {
	$sock->listen($arg->{Listen} || 5) or
	    return _error($sock,"$!");
    }
    else {
	return _error($sock,'Cannot determine remote port')
		unless($rport || $type == SOCK_DGRAM || $type == SOCK_RAW);

	if($type == SOCK_STREAM || defined $raddr) {
	    return _error($sock,'Bad peer address')
	    	unless(defined $raddr);

	    $sock->connect($rport,$raddr) or
		return _error($sock,"$!");
	}
    }

    $sock;
}

sub sockaddr {
    @_ == 1 or croak 'usage: $sock->sockaddr()';
    my($sock) = @_;
    (sockaddr_in($sock->sockname))[1];
}

sub sockport {
    @_ == 1 or croak 'usage: $sock->sockport()';
    my($sock) = @_;
    (sockaddr_in($sock->sockname))[0];
}

sub sockhost {
    @_ == 1 or croak 'usage: $sock->sockhost()';
    my($sock) = @_;
    inet_ntoa($sock->sockaddr);
}

sub peeraddr {
    @_ == 1 or croak 'usage: $sock->peeraddr()';
    my($sock) = @_;
    (sockaddr_in($sock->peername))[1];
}

sub peerport {
    @_ == 1 or croak 'usage: $sock->peerport()';
    my($sock) = @_;
    (sockaddr_in($sock->peername))[0];
}

sub peerhost {
    @_ == 1 or croak 'usage: $sock->peerhost()';
    my($sock) = @_;
    inet_ntoa($sock->peeraddr);
}

1;

__END__

=head1 NAME

IO::Socket::INET - Object interface for AF_INET domain sockets

=head1 SYNOPSIS

    use IO::Socket::INET;

=head1 DESCRIPTION

C<IO::Socket::INET> provides an object interface to creating and using sockets
in the AF_INET domain. It is built upon the L<IO::Socket> interface and
inherits all the methods defined by L<IO::Socket>.

=head1 CONSTRUCTOR

=over 4

=item new ( [ARGS] )

Creates an C<IO::Socket::INET> object, which is a reference to a
newly created symbol (see the C<Symbol> package). C<new>
optionally takes arguments, these arguments are in key-value pairs.

In addition to the key-value pairs accepted by L<IO::Socket>,
C<IO::Socket::INET> provides.


    PeerAddr	Remote host address          <hostname>[:<port>]
    PeerPort	Remote port or service       <service>[(<no>)] | <no>
    LocalAddr	Local host bind	address      hostname[:port]
    LocalPort	Local host bind	port         <service>[(<no>)] | <no>
    Proto	Protocol name (or number)    "tcp" | "udp" | ...
    Type	Socket type                  SOCK_STREAM | SOCK_DGRAM | ...
    Listen	Queue size for listen
    Reuse	Set SO_REUSEADDR before binding
    Timeout	Timeout	value for various operations


If C<Listen> is defined then a listen socket is created, else if the
socket type, which is derived from the protocol, is SOCK_STREAM then
connect() is called.

The C<PeerAddr> can be a hostname or the IP-address on the
"xx.xx.xx.xx" form.  The C<PeerPort> can be a number or a symbolic
service name.  The service name might be followed by a number in
parenthesis which is used if the service is not known by the system.
The C<PeerPort> specification can also be embedded in the C<PeerAddr>
by preceding it with a ":".

If C<Proto> is not given and you specify a symbolic C<PeerPort> port,
then the constructor will try to derive C<Proto> from the service
name.  As a last resort C<Proto> "tcp" is assumed.  The C<Type>
parameter will be deduced from C<Proto> if not specified.

If the constructor is only passed a single argument, it is assumed to
be a C<PeerAddr> specification.

Examples:

   $sock = IO::Socket::INET->new(PeerAddr => 'www.perl.org',
                                 PeerPort => 'http(80)',
                                 Proto    => 'tcp');

   $sock = IO::Socket::INET->new(PeerAddr => 'localhost:smtp(25)');

   $sock = IO::Socket::INET->new(Listen    => 5,
                                 LocalAddr => 'localhost',
                                 LocalPort => 9000,
                                 Proto     => 'tcp');

   $sock = IO::Socket::INET->new('127.0.0.1:25');


 NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
 
As of VERSION 1.18 all IO::Socket objects have autoflush turned on
by default. This was not the case with earlier releases.

 NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE

=head2 METHODS

=over 4

=item sockaddr ()

Return the address part of the sockaddr structure for the socket

=item sockport ()

Return the port number that the socket is using on the local host

=item sockhost ()

Return the address part of the sockaddr structure for the socket in a
text form xx.xx.xx.xx

=item peeraddr ()

Return the address part of the sockaddr structure for the socket on
the peer host

=item peerport ()

Return the port number for the socket on the peer host.

=item peerhost ()

Return the address part of the sockaddr structure for the socket on the
peer host in a text form xx.xx.xx.xx

=back

=cut
