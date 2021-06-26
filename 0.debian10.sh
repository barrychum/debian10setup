#!/bin/bash
echo "Please enter new IP"
read ip
export if=ens192

export timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

add_change_log_label() {
    if [ -z "$(grep -R '## Change log ##' $1)" ]
    then
        cat /etc/network/interfaces | sed -e "\$a|## Change log ##" | tr '|##' '\n##' > /tmp/outfile.tmp
        mv /tmp/outfile.tmp $1
    fi
}

################# edit network interfaces
$file=/etc/network/interfaces
if [ -z "$(grep -R 'changed interface' $file)"]
then
    sed -i -e "/iface $if inet dhcp/ a dns-nameservers 192.168.38.1" $file
    sed -i -e "/iface $if inet dhcp/ a dns-domain home.arpa" $file
    sed -i -e "/iface $if inet dhcp/ a gateway 192.168.38.1" $file
    sed -i -e "/iface $if inet dhcp/ a network 255.255.255.0" $file
    sed -i -e "/iface $if inet dhcp/ a address $ip" $file
    sed -i -e "s/iface $if inet dhcp/iface $if inet static/g" $file
fi
add_change_log_label $file
sed -i -e "/## Change log ##/ a # $timestamp changed interface" $file

##################### disable ipv6
# if grep -Fxq "ipv6" /etc/sysctl.conf
if [ -z "$(grep -R '#ipv6disabled' /etc/sysctl.conf)" ]
then
  sed -i -e "\$anet.ipv6.conf.$if.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.lo.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.default.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$anet.ipv6.conf.all.disable_ipv6=1" /etc/sysctl.conf
  sed -i -e "\$a#ipv6disabled" /etc/sysctl.conf
fi

# sed -i -e "/## Change log ##/ a # disabled ipv6" /etc/sysctl.conf

###################### enable remote ssh
if [ -z "$(grep -R '#PermitRootLoginChangedManually' /etc/ssh/sshd_config)" ]
then
  sed -i -e "/#PermitRootLogin/ a PermitRootLogin yes" /etc/ssh/sshd_config
  sed -i -e "\$a#PermitRootLoginChangedManually" /etc/ssh/sshd_config
fi

# sed -i -e "/## Change log ##/ a # changed ssh" /etc/ssh/sshd_config

# sed -i -e "/#PermitRootLogin/ a PermitRootLogin yes" /etc/ssh/sshd_config

ip addr flush $if && systemctl restart networking
ifdown $if &&  ifup $if
systemctl restart sshd

