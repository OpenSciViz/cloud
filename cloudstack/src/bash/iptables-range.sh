#/bin/sh
# http://www.thegeekstuff.com/scripts/iptables-rules
iptables -A INPUT -m iprange --src-range 10.101.11.75-10.101.11.254 -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -m iprange --src-range 10.101.11.75-10.101.11.254 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -m iprange --dst-range 10.101.11.75-10.101.11.254 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -m iprange --dst-range 10.101.11.75-10.101.11.254 -p icmp --icmp-type echo-reply -j ACCEPT
