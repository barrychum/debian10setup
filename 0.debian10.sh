#!/bin/bash
echo "Please enter new IP"
read ip
export if=ens192

################# edit network interfaces
sed -i -e "/iface $if inet dhcp/ a dns-nameservers 192.168.38.1" /etc/network/interfaces
sed -i -e "/iface $if inet dhcp/ a dns-domain home.arpa" /etc/network/interfaces
sed -i -e "/iface $if inet dhcp/ a gateway 192.168.38.1" /etc/network/interfaces
sed -i -e "/iface $if inet dhcp/ a network 255.255.255.0" /etc/network/interfaces
sed -i -e "/iface $if inet dhcp/ a address $ip" /etc/network/interfaces
sed -i -e "s/iface $if inet dhcp/iface $if inet static/g" /etc/network/interfaces

if grep -R "## Change log ## " /etc/network/interfaces
then
  echo "found"
else
  sed -i -e "\$a## Change log ##" /etc/network/interfaces
fi
sed -i -e "/## Change log ##/ a # changed network settings" /etc/network/interfaces

##################### disable ipv6
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

if grep -R "## Change log ## " /etc/sysctl.conf
then
  echo "found"
else
  sed -i -e "\$a## Change log ##" /etc/sysctl.conf
fi
sed -i -e "/## Change log ##/ a # disabled ipv6" /etc/sysctl.conf

###################### enable remote ssh
if grep -R "#PermitRootLoginChangedManually" /etc/ssh/sshd_config
then
  echo "found"
else
  sed -i -e "/#PermitRootLogin/ a PermitRootLogin yes" /etc/ssh/sshd_config
  sed -i -e "\$a#PermitRootLoginChangedManually" /etc/ssh/sshd_config
fi

if grep -R "## Change log ## " /etc/ssh/sshd_config
then
  echo "found"
else
  sed -i -e "\$a## Change log ##" /etc/ssh/sshd_config
fi
sed -i -e "/## Change log ##/ a # changed ssh" /etc/ssh/sshd_config

# sed -i -e "/#PermitRootLogin/ a PermitRootLogin yes" /etc/ssh/sshd_config

ip addr flush $if && systemctl restart networking
ifdown $if &&  ifup $if
systemctl restart sshd

