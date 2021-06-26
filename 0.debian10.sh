#!/bin/bash

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

add_change_log_label() {
    if [ -z "$(grep -R '## Change log ##' $1)" ]
    then
        rand=$(openssl rand -hex 4)
#        rand=$(shuf -zer -n10 {A..Z} {a..z} {0..9})
        cat $1 | sed -e "\$a|## Change log ##" | tr '|##' '\n##' > /tmp/outfile.$rand
        mv /tmp/outfile.$rand $1
    fi
}

################# edit network interfaces
file=/etc/network/interfaces
s=($(ip r | grep onlink))
ifa=${s[4]}
echo "Interface name $ifa"
read if

tempstr=*changed $if*
if [ -z "$(grep -R $tempstr $file)" ]
then
    # https://stackoverflow.com/questions/7815989/need-to-break-ip-address-stored-in-bash-variable-into-octets
    echo "Please enter new IP"
    read ip

    IFS=. read ip1 ip2 ip3 ip4 <<< "$ip"
    # if=ens192

    sed -i -e "/iface $if inet dhcp/ a dns-nameservers $ip1.$ip2.$ip3.1" $file
    sed -i -e "/iface $if inet dhcp/ a dns-domain home.arpa" $file
    sed -i -e "/iface $if inet dhcp/ a gateway $ip1.$ip2.$ip3.1" $file
    sed -i -e "/iface $if inet dhcp/ a network 255.255.255.0" $file
    sed -i -e "/iface $if inet dhcp/ a address $ip" $file
    sed -i -e "s/iface $if inet dhcp/iface $if inet static/g" $file
fi
add_change_log_label $file
sed -i -e "/## Change log ##/ a # $timestamp *changed $if*" $file

##################### disable ipv6
# if grep -Fxq "ipv6" /etc/sysctl.conf
file2=/etc/sysctl.conf
if [ -z "$(grep -R '*ipv6disabled*' $file2)" ]
then
  sed -i -e "\$anet.ipv6.conf.$if.disable_ipv6=1" $file2
  sed -i -e "\$anet.ipv6.conf.lo.disable_ipv6=1" $file2
  sed -i -e "\$anet.ipv6.conf.default.disable_ipv6=1" $file2
  sed -i -e "\$anet.ipv6.conf.all.disable_ipv6=1" $file2
  sed -i -e "\$a#ipv6disabled" $file2
fi
add_change_log_label $file2
sed -i -e "/## Change log ##/ a # $timestamp *ipv6disabled*" $file2

###################### enable remote ssh
file3=/etc/ssh/sshd_config
if [ -z "$(grep -R '*PermitRootLoginChanged*' $file3)" ]
then
  sed -i -e "/#PermitRootLogin/ a PermitRootLogin yes" $file3
fi
add_change_log_label $file3
sed -i -e "/## Change log ##/ a # $timestamp *PermitRootLoginChanged*" $file3

ip addr flush $if && systemctl restart networking
# ifdown $if &&  ifup $if
ifup $if
systemctl restart sshd

