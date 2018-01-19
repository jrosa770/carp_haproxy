## CARP & HAProxy Implementation HowTo
#### Audience: Network and/ or System Administrators

#### Pre-requisites: 
Basic understanding of IPv4 concepts and routing and understanding of TCP load balancing. Basic UNIX shell knowledge and HAProxy configuration syntax

#### Motivation: 
In a past project I needed a solution that could provide:
1. Load balancing for MySQL (Percona with XtraDB in my case) and basic HTTP included (later moved to HTTS. 
2.  Redundancy and a method for dynamic fail over. 
Sure I can have a vendor like F5 or A10 provide the functionality out of the box. But where is the challenge on that? 
Why not create it possible? 
What is my budget does not allow for the expense on a vendor based appliance?
Open Source is there fo r a reason... Why not use it?

#### Solution: 
The solution I settled for was based on FreeBSD UNIX using CARP a method for failover an redundancy similar to Cisco HSRP or the open standard VRRP. 
For Load Balancing the best solution I've seen is HA Proxy, a fantastic TCP based load balancer.

Method: The following example is based on that solution. The basic setup requires two FreeBSD boxes or as VM(s). 
If VM(s) the recommendation is for two guests in two different hosts systems. 
An of course a network or set of available network and last bu not least the end systems that will ultimately handle the user's request for services.
"

#### Example Networks:
- 10.1.1.0/24 - Management 
- 10.2.2.0/24 - User Facing Load Balancing VIP Segment
- 10.3.3.0/24 - Systems Facing Segment for load balanced Hosts
- 10.4.4.0/23 - MySQL Servers Segment. Spplited in two "/24's" (10.4.4.0/24 and 10.4.5.0/24)
- 10.6.6.0/24 - HTTP Server Segment

### Process: 
1. First enable IP routing and CARP on the HAProxy Systems
```bash
# /etc/sysctl.conf - Both Systems #
# Packet Forwarding
net.inet.ip.forwarding=1
# Enable CARP preemt in /etc/sysctl.conf - Both Systems #
net.inet.carp.preempt=1
```

### CARP Notes

```
#
# CARP - failover all carp interfaces as a group. The preempt option means when
# one of the carp enabled physical interfaces goes down, advskew is changed to
# 100 on all carp interfaces. CARP demoted by 100 stops this machine from
# accepting traffic and allows another CARP enabled machine to accept the
# traffic.
# This is similar in functionality to VRRP and HSRP. But one key difference
# For example the difference from HSRP (Cisco) is that in CARP the host with the highest "advkew" is the secondary.
# While on protocols with HSRP the host with the highst priority is the primary (See example below)
# Cisco Example (HSRP)
# Primary:
# standby 4 ip 10.2.2.4
# standby 4 priority 110
# standby 4 preempt delay minimum 60
# standby 4 track 1 decrement 11 < When tracking fails the priority is decremented to 99, thus allowing the secondary to take over
#
# Secondary:
# standby 4 ip 10.2.2.4
# standby 4 priority 100
# standby 4 preempt
#
# VRRP works with a similar mechanism.
```

2. Configure the IP's and CARP Groups. If you're familiar with VRRP or HSRP this part will 
look very familiar as the basics are covered: 
A redundancy group with an ID as a number and a Virtual IP attached to that group.
```
# /etc/rc.conf #
# -- Primary Host -- #
hostname="carp_host-0.example.com"	# Hostname
ifconfig_hn0="inet 10.1.1.241 netmask 255.255.255.0 broadcast 10.1.1.255" # NIC1 IP Address - MGMT
ifconfig_hn1="inet 10.2.2.241 netmask 255.255.255.0 broadcast 10.2.2.255" # NIC2 IP Address - LB Setup
ifconfig_hn2="inet 10.3.3.241 netmask 255.255.255.0 broadcast 10.3.3.255" # NIC3 IP Address - 10.3.3.0/24 Access
ifconfig_hn1_alias4="vhid 4 pass passwd4 10.2.2.4/24 up"			# CARP Group 4 with password and Group Virtual IP
ifconfig_hn1_alias44="vhid 44 pass passwd44 10.2.2.44/24 up"			# CARP Group 44 with password and Group Virtual IP
ifconfig_hn1_alias5="vhid 5 pass passwd4 10.2.2.5/24 up"			# CARP Group 5 with password and Group Virtual IP
ifconfig_hn1_alias55="vhid 55 pass passwd44 10.2.2.55/24 up"			# CARP Group 55 with password and Group Virtual IP
#
gateway_enable="YES" # Set to YES if this host will be a gateway, in order for the system to forward packets between interfaces
# Static Routes
static_routes="mgmtnet usernet mysqlnet httpnet"
route_mgmtnet="-net 10.1.0.0/23 10.1.1.254"
route_usernet="-net 10.0.0.0/16 10.2.2.254"
route_mysqlnet="-net 10.4.4.0/23 10.2.2.254"
route_httpnet="-net 10.6.6.0/23 10.3.3.254"
#

# -- Secondary Host -- #
hostname="carp_host-0_b.example.com"
ifconfig_hn0="inet 10.1.1.242 netmask 255.255.255.0 broadcast 10.1.1.255" # NIC1 IP Address - MGMT
ifconfig_hn1="inet 10.2.2.242 netmask 255.255.255.0 broadcast 10.2.2.255" # NIC2 IP Address - LB Setup
ifconfig_hn2="inet 10.3.3.242 netmask 255.255.255.0 broadcast 10.3.3.255" # NIC3 IP Address - 10.3.3.0/24 Access
ifconfig_hn1_alias4="vhid 4 advskew 100 pass passwd4 10.2.2.4/24 up"	 # CARP Group 4 with password and Group Virtual IP
ifconfig_hn1_alias44="vhid 44 advskew 100 pass passwd44 10.2.2.44/24 up" # CARP Group 44 with password and Group Virtual IP
ifconfig_hn1_alias5="vhid 5 advskew 100 pass passwd4 10.2.2.5/24 up"	 # CARP Group 4 with password and Group Virtual IP
ifconfig_hn1_alias55="vhid 55 advskew 100 pass passwd44 10.2.2.55/24 up" # CARP Group 44 with password and Group Virtual IP
#
gateway_enable="YES" # Set to YES if this host will be a gateway, in order for the system to forward packets between interfaces
# Static Routes
static_routes="mgmtnet usernet mysqlnet httpnet"
route_mgmtnet="-net 10.1.0.0/23 10.1.1.254"
route_usernet="-net 10.0.0.0/16 10.2.2.254"
route_mysqlnet="-net 10.4.4.0/23 10.3.3.254"
route_httpnet="-net 10.6.6.0/24 10.3.3.254"
#
```
3. Configure the HAProxy Daemon

```
# /usr/local/etc/haproxy.conf - Primary #
# -- MYSQL --#
listen  haproxy_10.2.2.4_3306
        bind 10.2.2.4:3306
        mode tcp
        option socket-stats
        timeout client  10800s
        timeout server  10800s
        balance leastconn
        option tcp-check
        tcp-check expect string is\ running.
        option allbackups
        default-server port 9200 inter 2s downinter 5s rise 3 fall 2 slowstart 60s maxconn 300 maxqueue 128 weight 100
# This setup is to prevent locks in the database(s)
        server percona_mysql-1 10.4.4.2:3306 check
        server percona_mysql-2 10.4.4.3:3306 check backup
        server percona_mysql-3 10.4.4.4:3306 check backup
#
listen  haproxy_10.2.2.44_3306
        bind 10.2.2.44:3306
        mode tcp
        option socket-stats
        timeout client  10800s
        timeout server  10800s
        balance leastconn
        option tcp-check
        tcp-check expect string is\ running.
        option allbackups
# See Sections 4. and 5. for the probe on TCP 9200 
        default-server port 9200 inter 2s downinter 5s rise 3 fall 2 slowstart 60s maxconn 300 maxqueue 128 weight 100
# This setup is to prevent locks in the database(s)
        server percona_mysql-4 10.4.5.2:3306 check backup
        server percona_mysql-5 10.4.5.3:3306 check backup
        server percona_mysql-6 10.4.5.4:3306 check
#
# -- HTTP -- #
listen haproxy_10.2.2.5_80
        bind 10.2.2.5:80
		mode http
		balance source
        server http_srv-1 10.6.6.1:80 check
        server http_srv-2 10.6.6.2:80 check
		#
listen haproxy_10.2.2.55_80
        bind 10.2.2.55:80
		mode http
		balance source
        server http_srv-3 10.6.6.3:80 check
        server http_srv-4 10.6.6.4:80 check
#
#stats.cfg
userlist stats-auth
        group admin    users admin
        user  admin    insecure-password AdminPasswd
        group readonly users lbuser
        user  lbuser insecure-password lbuser

listen stats
        bind 10.1.1.241:9000 #Management IP listening on port 9000
        mode http
        balance
        timeout client 5000
        timeout connect 4000
        timeout server 30000
        stats refresh 10s
        stats show-node
        stats uri /haproxy_stats
        acl AUTH       http_auth(stats-auth)
        acl AUTH_ADMIN http_auth_group(stats-auth) admin
        stats http-request auth unless AUTH
        stats admin if AUTH_ADMIN
```

```
# /usr/local/etc/haproxy.conf - Secondary #
# -- MYSQL --#
listen  haproxy_10.2.2.4_3306
        bind 10.2.2.4:3306
        mode tcp
        option socket-stats
        timeout client  10800s
        timeout server  10800s
        balance leastconn
        option tcp-check
        tcp-check expect string is\ running.
        option allbackups
        default-server port 9200 inter 2s downinter 5s rise 3 fall 2 slowstart 60s maxconn 300 maxqueue 128 weight 100
# This setup is to prevent locks in the database(s)
        server percona_mysql-1 10.4.4.2:3306 check
        server percona_mysql-2 10.4.4.3:3306 check backup
        server percona_mysql-3 10.4.4.4:3306 check backup
#
listen  haproxy_10.2.2.44_3306
        bind 10.2.2.44:3306
        mode tcp
        option socket-stats
        timeout client  10800s
        timeout server  10800s
        balance leastconn
        option tcp-check
        tcp-check expect string is\ running.
        option allbackups
# See Sections 4. and 5. for the probe on TCP 9200 
        default-server port 9200 inter 2s downinter 5s rise 3 fall 2 slowstart 60s maxconn 300 maxqueue 128 weight 100
# This setup is to prevent locks in the database(s)
        server percona_mysql-4 10.4.5.2:3306 check backup
        server percona_mysql-5 10.4.5.3:3306 check backup
        server percona_mysql-6 10.4.5.4:3306 check
#
# -- HTTP -- #
listen haproxy_10.2.2.5_80
        bind 10.2.2.5:80
		mode http
		balance source
        server http_srv-1 10.6.6.1:80 check
        server http_srv-2 10.6.6.2:80 check
		#
listen haproxy_10.2.2.55_80
        bind 10.2.2.55:80
		mode http
		balance source
        server http_srv-3 10.6.6.3:80 check
        server http_srv-4 10.6.6.4:80 check
#
#stats.cfg
userlist stats-auth
        group admin    users admin
        user  admin    insecure-password AdminPasswd
        group readonly users lbuser
        user  lbuser insecure-password lbuser

listen stats
        bind 10.1.1.242:9000 #Management IP listening on port 9000
        mode http
        balance
        timeout client 5000
        timeout connect 4000
        timeout server 30000
        stats refresh 10s
        stats show-node
        stats uri /haproxy_stats
        acl AUTH       http_auth(stats-auth)
        acl AUTH_ADMIN http_auth_group(stats-auth) admin
        stats http-request auth unless AUTH
        stats admin if AUTH_ADMIN
#
```

4. This setup requires a separate probe for Health checks.

```
#
# MYSQL Health Probe #
# -- All Servers --#

# -- PROBE FILE -- #
#!/bin/bash
#
# This script checks if a mysql server is healthy running on localhost. It will
# return:
# "HTTP/1.x 200 OK\r" (if mysql is running smoothly)
# - OR -
# "HTTP/1.x 500 Internal Server Error\r" (else)
#
# The purpose of this script is make haproxy capable of monitoring mysql properly
#

MYSQL_HOST="THIS_HOST_IP"
MYSQL_PORT="3306"
MYSQL_USERNAME="mysqladmin"
MYSQL_PASSWORD="mysqladmin_passwd"
MYSQL_OPTS="-N -q -A"
TMP_FILE="/dev/shm/mysqlchk.$$.out"
ERR_FILE="/dev/shm/mysqlchk.$$.err"
FORCE_FAIL="/dev/shm/proxyoff"
MYSQL_BIN="/usr/bin/mysql"
CHECK_QUERY="show global status where variable_name='wsrep_local_state'"
preflight_check()
{
    for I in "$TMP_FILE" "$ERR_FILE"; do
        if [ -f "$I" ]; then
            if [ ! -w $I ]; then
                echo -e "HTTP/1.1 503 Service Unavailable\r\n"
                echo -e "Content-Type: Content-Type: text/plain\r\n"
                echo -e "\r\n"
                echo -e "Cannot write to $I\r\n"
                echo -e "\r\n"
                exit 1
            fi
        fi
    done
}
return_ok()
{
    echo -e "HTTP/1.1 200 OK\r\n"
    echo -e "Content-Type: text/html\r\n"
    echo -e "Content-Length: 43\r\n"
    echo -e "\r\n"
    echo -e "<html><body>MySQL is running.</body></html>\r\n"
    echo -e "\r\n"
    rm $ERR_FILE $TMP_FILE
    exit 0
}
return_fail()
{
    echo -e "HTTP/1.1 503 Service Unavailable\r\n"
    echo -e "Content-Type: text/html\r\n"
    echo -e "Content-Length: 42\r\n"
    echo -e "\r\n"
    echo -e "<html><body>MySQL is *down*.</body></html>\r\n"
    sed -e 's/\n$/\r\n/' $ERR_FILE
    echo -e "\r\n"
    rm $ERR_FILE $TMP_FILE
    exit 1
}
preflight_check
if [ -f "$FORCE_FAIL" ]; then
        echo "$FORCE_FAIL found" > $ERR_FILE
        return_fail;
fi
$MYSQL_BIN $MYSQL_OPTS --host=$MYSQL_HOST --port=$MYSQL_PORT --user=$MYSQL_USERNAME --password=$MYSQL_PASSWORD -e "$CHECK_QUERY" > $TMP_FILE 2> $ERR_FILE
if [ $? -ne 0 ]; then
        return_fail;
fi
status=`cat  $TMP_FILE | awk '{print $2;}'`

if [ $status -ne 4 ]; then
   return_fail;
fi

return_ok;
```

5. Configure the Service for Port 9200 TCP

```
# -- Xinetd Service for TCP 9200 -- #
# /etc/xinetd.d/mysqlcheck

service mysqlcheck
{
   flags        = REUSE
   disable      = no
   socket_type  = stream
   protocol     = tcp
   port         = 9200
   wait         = no
   user         = root
  server        = /var/lib/mysql-check/mysqlchk.mysql.bash
 }
```
 
 #### -- Dynamic Routing Options (Only if needed)-- 
 
 ##### -- Routing Option for OSPF -- 
```
 # /usr/local/etc/ospfd.conf
#
router-id 10.255.255.24[1 - 2]
 area 0.0.0.0 { 
	interface hn1 
	interface hn0 { 
		passive 
	} 
	interface hn2 { 
		metric 10
	} 
}

 # -- Routing Option for BGP -- #
 # /usr/local/etc/bgpd.conf
#
AS 65000
router-id 10.255.255.24[1 - 2]
#
neighbor 10.2.2.1 {
	remote-as 65001
	announce all
#
	descr "ebgp1"
	local-address   10.2.2.24[1-2]
	tcp md5sig password secret
#
	set med 10
	set localpref 80
	set community 65000:180
}
```