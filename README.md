# Redundant HaProxy with CARP Based Redundancy

Audience: Technical personnel with basic understanding of IPv4 concepts and routing and understanding of TCP load balancing. Basic UNIX shell knowledge.

Motivation: In a past project I needed a solution that could provide load balancing for MySQL (Percona in my case) and basic HTTP included. but at the same time redundancy and a method for dynamic fail over. Sure I can have a vendor like F5 or A10 provide the functionality out of the box. But where is the challenge on that? Why not create it possible? What is my budget does not allow for the expense on a vendor based appliance?
Open Source is there fo r a reason... Why not use it?

Solution: The solution I settled for was based on FreeBSD UNIX using CARP a method for failover an redundancy similar to Cisco HSRP or the open standard VRRP. For Load Balancing the best solution I've seen is HA Proxy, a fantastic TCP based load balancer.

Method: The following example is based on that solution. The basic setup requires two FreeBSD boxes or as VM(s). If VM(s) the recommendation is for two guests in two different hosts systems. An of course a network or set of available network and last bu not least the end systems that will ultimately handle the user's request for services.
