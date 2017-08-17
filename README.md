# Redundant HaProxy with CARP Based Dynamic Fail Over

Audience: Network and/ or System Administrators

Pre-requisites: Basic understanding of IPv4 concepts and routing and understanding of TCP load balancing. Basic UNIX shell knowledge. Familiarity with HAProxy or similar load balancing configurations.

Motivation: 
A solution that could provide:
1. Load balancing for MySQL (Percona in my case) and basic HTTP and HTTPS if needed
2. Redundancy and a method for dynamic fail over. 

Sure I can have a vendor like F5 or A10 provide the functionality out of the box. But where is the challenge on that? Why not create it possible? What is my budget does not allow for the expense on a vendor based appliance?
Open Source is there fo r a reason... Why not use it?

Solution: The solution I settled for was based on FreeBSD UNIX using CARP a method for failover an redundancy similar to Cisco HSRP or the open standard VRRP. For Load Balancing the best solution I've seen is HA Proxy, a fantastic TCP based load balancer.

Method: The following example is based on that solution. The basic setup requires two FreeBSD boxes or as VM(s). If VM(s) the recommendation is for two guests in two different hosts systems. An of course a network or set of available network and last bu not least the end systems that will ultimately handle the user's request for services.

Steps (See Files):

```
1. First enable IP routing and CARP on the HAProxy Systems
/etc/sysctl.conf - Both Systems #

2. Configure the IP's and CARP Groups. If you're familiar with VRRP or HSRP this part will look 
very familiar as the basics are covered with a redundancy group with an ID as a number and a 
Virtual IP attached to that group.
/etc/rc.conf (2 files included for Primary and Secondary)
2a.
File rc.conf-primary to /etc/rc.conf on primary
2b.
File rc.conf-secondary to /etc/rc.conf on secondary

3(a). Configure the HAProxy Daemon
/usr/local/etc/haproxy.conf - Primary #

3 (b). Configure the HAProxy Daemon
/usr/local/etc/haproxy.conf - Secondary #

4. This setup requires a separate probe for Health checks at the destination server(s). 
In this case MySQL.
/var/lib/mysql-check/mysqlchk.mysq.bash

5. Configure the Service for Port 9200 TCP
 -- Xinetd Service for TCP 9200 -- 
/etc/xinetd.d/mysqlcheck

```

'The probe file can be adapted to monitor other services using either standard or non-standard TCP ports'

## Management Scripts
> HaSync

A Bash script to edit the haproxy.conf file in sections. The script will gather the sections into a single haproxy.conf file to then sync the configuration from the primary HAProxy to the Secondary (Requires the etckeeper and diffcolor packages). A second hasync file named hasync_from_primary is installed on the standby for proper synchronization.

The script assumes following directory structure:

```sh
#/usr/local/etc/haproxy/conf.d/

#├── global.cfg
#├── stats.cfg
#├── pcl.cfg
#├── http.cfg
#├── httpd.cfg
#├── others.cfg

```

Every site has it's own file, so you can disable site by changing it's file extension, or appending .disabled. You can add ad many files as needed to create as many sections you require in your haproxy.conf file.

> HaConf

Makes a Backup of the current haproxy.conf file. Then the current haproxy file is opened in ee (FreeBSD Easy Editor) for editing.

The editor can be changed from ee to vi or any other editor. (Line 13 in haconf: from ee $Original to vi $Original)
The script is intended as a standalone editing routing but does not provide for synchronization with the standby. If synchronization is needed the better alternative is hasync. Haconf is intended mainly for initial configurations, test or standalone HAProxy setups.
