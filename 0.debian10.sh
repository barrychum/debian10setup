#!/bin/bash

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

add_change_log_label() {
    if [ -z "$(grep -R '## Change log ##' $1)" ]
    then
        cat /etc/network/interfaces | sed -e "\$a|## Change log ##" | tr '|##' '\n##' > /tmp/outfile.tmp
        mv /tmp/outfile.tmp $1
    fi
}

################# edit network interfaces
$file=/etc/network/interfaces
if [ -z "$(grep -R '*changed interface*' $file)"]
then
    # https://stackoverflow.com/questions/7815989/need-to-break-ip-address-stored-in-bash-variable-into-octets
    echo "Please enter new IP"
    read ip

    IFS=. read ip1 ip2 ip3 ip4 <<< "$ip"
    if=ens192

    sed -i -e "/iface $if inet dhcp/ a dns-nameservers $ip1.$ip2.$ip3.1" $file
    sed -i -e "/iface $if inet dhcp/ a dns-domain home.arpa" $file
    sed -i -e "/iface $if inet dhcp/ a gateway $ip1.$ip2.$ip3.1" $file
    sed -i -e "/iface $if inet dhcp/ a network 255.255.255.0" $file
    sed -i -e "/iface $if inet dhcp/ a address $ip" $file
    sed -i -e "s/iface $if inet dhcp/iface $if inet static/g" $file
fi
add_change_log_label $file
sed -i -e "/## Change log ##/ a # $timestamp *changed interface*" $file

##################### disable ipv6
# if grep -Fxq "ipv6" /etc/sysctl.conf
$file=/etc/sysctl.conf
if [ -z "$(grep -R '*ipv6disabled*' $file)" ]
then
  sed -i -e "\$anet.ipv6.conf.$if.disable_ipv6=1" $file
  sed -i -e "\$anet.ipv6.conf.lo.disable_ipv6=1" $file
  sed -i -e "\$anet.ipv6.conf.default.disable_ipv6=1" $file
  sed -i -e "\$anet.ipv6.conf.all.disable_ipv6=1" $file
  sed -i -e "\$a#ipv6disabled" $file
fi
add_change_log_label $file
sed -i -e "/## Change log ##/ a # $timestamp *ipv6disabled*" $file

###################### enable remote ssh
$file=/etc/ssh/sshd_config
if [ -z "$(grep -R '*PermitRootLoginChanged*' $file)" ]
then
  sed -i -e "/#PermitRootLogin/ a PermitRootLogin yes" $file
fi
add_change_log_label $file
sed -i -e "/## Change log ##/ a # $timestamp *PermitRootLoginChanged*" $file

ip addr flush $if && systemctl restart networking
ifdown $if &&  ifup $if
systemctl restart sshd

