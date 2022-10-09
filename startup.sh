cat /etc/squid/hosts_template > /etc/squid/hosts
sed -i "s/127\.0\.0\.1/$1/g" /etc/squid/hosts
/usr/sbin/squid -f /etc/squid/squid.conf -NYCd 1