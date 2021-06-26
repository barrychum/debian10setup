#!/bin/bash
echo "Please enter new IP"
read ip
export if=ens192

sed -i -e "/iface $if inet dhcp/ a dns-nameservers 192.168.38.1" /etc/network/interfaces
sed -i -e "/iface $if inet dhcp/ a dns-domain home.arpa" /etc/network/interfaces
sed -i -e "/iface $if inet dhcp/ a gateway 192.168.38.1" /etc/network/interfaces
sed -i -e "/iface $if inet dhcp/ a network 255.255.255.0" /etc/network/interfaces
sed -i -e "/iface $if inet dhcp/ a address $ip" /etc/network/interfaces
sed -i -e "s/iface $if inet dhcp/iface $if inet static/g" /etc/network/interfaces

# if grep -Fxq "ipv6" /etc/sysctl.conf
if grep -R "#ipv6disabled" /etc/sysctl.conf
then
  echo "found"
else
  sed -i -e "\$anet.ipv6.conf.$if.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.lo.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.default.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.all.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$a#ipv6disabled" /etc/sysctl.conf
fi

# sed -i -e "/#PermitRootLogin/ a PermitRootLogin yes" /etc/ssh/sshd_config

ifdown $if &&  ifup $if
systemctl restart sshd

