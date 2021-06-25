#!/bin/bash
echo "Please enter new IP"
read ip

sed -i -e '/iface ens32 inet dhcp/ a dns-nameservers 192.168.8.1' /etc/network/interfaces
sed -i -e '/iface ens32 inet dhcp/ a dns-domain home.local' /etc/network/interfaces
sed -i -e '/iface ens32 inet dhcp/ a gateway 192.168.8.1' /etc/network/interfaces
sed -i -e '/iface ens32 inet dhcp/ a network 255.255.255.0' /etc/network/interfaces
sed -i -e "/iface ens32 inet dhcp/ a address $ip" /etc/network/interfaces
sed -i -e 's/iface ens32 inet dhcp/iface ens32 inet static/g' /etc/network/interfaces

# if grep -Fxq "ipv6" /etc/sysctl.conf
if grep -R "#ipv6disabled" /etc/sysctl.conf
then
  echo "found"
else
  sed -i -e "\$anet.ipv6.conf.ens32.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.lo.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.default.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.all.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$a#ipv6disabled" /etc/sysctl.conf
fi

# sed -i -e '/#PermitRootLogin/ a PermitRootLogin yes' /etc/ssh/sshd_config
