#!/usr/bin/env bash

function start {
  # sysctls are documented at https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt

  # forwarding - BOOLEAN
  # 	Enable IP forwarding on this interface.  This controls whether packets
  # 	received _on_ this interface can be forwarded.
  /usr/bin/env ip netns exec haproxy sysctl -w net.ipv4.conf.mv0.forwarding=1

  # arp_notify - BOOLEAN
  # 	Define mode for notification of address and device changes.
  # 	0 - (default): do nothing
  # 	1 - Generate gratuitous arp requests when device is brought up
  # 	    or hardware address changes.
  /usr/bin/env ip netns exec haproxy sysctl -w net.ipv4.conf.mv0.arp_notify=1

  # arp_announce - INTEGER
  # 	Define different restriction levels for announcing the local
  # 	source IP address from IP packets in ARP requests sent on
  # 	interface:
  # 	0 - (default) Use any local address, configured on any interface
  # 	1 - Try to avoid local addresses that are not in the target's
  # 	subnet for this interface. This mode is useful when target
  # 	hosts reachable via this interface require the source IP
  # 	address in ARP requests to be part of their logical network
  # 	configured on the receiving interface. When we generate the
  # 	request we will check all our subnets that include the
  # 	target IP and will preserve the source address if it is from
  # 	such subnet. If there is no such subnet we select source
  # 	address according to the rules for level 2.
  # 	2 - Always use the best local address for this target.
  # 	In this mode we ignore the source address in the IP packet
  # 	and try to select local address that we prefer for talks with
  # 	the target host. Such local address is selected by looking
  # 	for primary IP addresses on all our subnets on the outgoing
  # 	interface that include the target IP address. If no suitable
  # 	local address is found we select the first local address
  # 	we have on the outgoing interface or on all other interfaces,
  # 	with the hope we will receive reply for our request and
  # 	even sometimes no matter the source IP address we announce.

  # 	The max value from conf/{all,interface}/arp_announce is used.

  # 	Increasing the restriction level gives more chance for
  # 	receiving answer from the resolved target while decreasing
  # 	the level announces more valid sender's information.
  /usr/bin/env ip netns exec haproxy sysctl -w net.ipv4.conf.mv0.arp_announce=2

  # use_tempaddr - INTEGER
  # 	Preference for Privacy Extensions (RFC3041).
  # 	  <= 0 : disable Privacy Extensions
  # 	  == 1 : enable Privacy Extensions, but prefer public
  # 	         addresses over temporary addresses.
  # 	  >  1 : enable Privacy Extensions and prefer temporary
  # 	         addresses over public addresses.
  # 	Default:  0 (for most devices)
  # 		 -1 (for point-to-point devices and loopback devices)
  /usr/bin/env ip netns exec haproxy sysctl -w net.ipv4.conf.mv0.use_tempaddr=0

  /usr/bin/env ip netns exec haproxy ip address add 172.16.26.1/22 dev mv0
  /usr/bin/env ip netns exec haproxy ip address add 172.16.26.2/22 dev mv0

  # Add a route in the main routing table which allows the host to route packets
  # to IPs assigned to this interface.
  #
  # From 'man (8) ip-route':
  # Route types:
  #   local - the destinations are assigned to this host.
  #   The packets are looped back and delivered locally.
  /usr/bin/env ip route add 172.16.26.1/32 dev mv-int metric 100 table local
  /usr/bin/env ip route add 172.16.26.2/32 dev mv-int metric 100 table local
}

function stop {
  /usr/bin/env ip route del 172.16.26.1/32 dev mv-int metric 100 table local
  /usr/bin/env ip route del 172.16.26.2/32 dev mv-int metric 100 table local
}

case "$1" in
  start)
    start
  ;;
  stop)
    stop
  ;;
  restart)
    stop
    start
  ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
esac
