# version=RHEL7

# Install OS instead of upgrade
install

# Accept EULA
eula --agreed

# System authorization information
auth --enableshadow --passalgo=sha512

firewall --disabled

services --enabled=network,sshd
reboot

# Run the Setup Agent on first boot
firstboot --disabled

# Keyboard layouts
keyboard --vckeymap=pt-latin1 --xlayouts='pt'

# System language
lang en_US.UTF-8

selinux --disabled

# Network information
network --noipv6 --onboot=yes --bootproto=dhcp --hostname=$hostname

# Root password
rootpw --iscrypted $default_password_crypted

# User for monitoring installation
# sshpw --iscrypted --username=macc secret

# System timezone
timezone Europe/Lisbon --ntpservers=pool.ntp.org

# System bootloader configuration
bootloader --location=mbr --boot-drive=sda --append="biosdevname=0 net.ifnames=0 console=tty1 console=ttyS1,115200n8 spectre_v2=off nopti norhgb text"

# Partition clearing
clearpart --all --drives=sda
ignoredisk --only-use=sda

# Use network installation
url --url="http://mirror.fccn.pt/repos/pub/CentOS/7/os/x86_64/"
repo --name=updates

# create user
user --name=macc --uid=1000000 --password=$default_password_crypted --iscrypted --groups=wheel

# Don't install X
skipx

# Disk partitioning information
part /boot --fstype=ext4 --ondisk=sda --size=1024
part pv.01 --fstype=lvmpv --ondisk=sda --size=1 --grow
volgroup $name pv.01
logvol / --fstype=xfs --name=root --vgname=$name --size=16384
logvol /home --fstype=xfs --name=home --vgname=$name --size=8192
logvol /var --fstype=xfs --name=var --vgname=$name --size=8192
logvol /tmp --fstype=xfs --name=tmp --vgname=$name --size=8192
logvol swap --fstype=swap --name=swap --vgname=$name --size=2048

%packages --nobase --excludedocs
@Infiniband Support
sudo
vim-enhanced
iptables-services
ipset
yum-utils
edac-utils
libselinux-python
authconfig
sssd-ldap
libselinux-python
-setroubleshoot             # CIS 1.4.4
-mcstrans                   # CIS 1.4.5
-telnet                     # CIS 2.1.2
-rsh-server                 # CIS 2.1.3
-rsh                        # CIS 2.1.4
-ypbind                     # CIS 2.1.5
-ypserv                     # CIS 2.1.6
-tftp                       # CIS 2.1.7
-tftp-server                # CIS 2.1.8
-talk                       # CIS 2.1.9
-talk-server                # CIS 2.1.10
-xinetd                     # CIS 2.1.11
-xorg-x11-server-common     # CIS 3.2
-avahi-daemon               # CIS 3.3
-cups                       # CIS 3.4
-dhcp                       # CIS 3.5
# -openldap                 # CIS 3.7 (system dep)
-NetworkManager*
-firewalld
-firewalld-filesystem
-plymouth*
-abrt*
-avahi*               # ibutils dep 
-aic94xx-firmware
-alsa-firmware
-alsa-tools-firmware
-ivtv-firmware
-iwl*

%end

%post --log=/root/postinstall.log

systemctl enable rdma
systemctl enable sssd

sed -i 's/inet_protocols = all/inet_protocols = ipv4/' /etc/postfix/main.cf

echo 'ip_resolve=ipv4' >> /etc/yum.conf
echo 'installonly_limit=3' >> /etc/yum.conf

sed -i 's/quiet//g' /etc/default/grub
sed -i 's/rhgb/norhgb/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

echo "NETWORKING_IPV6=no" >> /etc/sysconfig/network
echo "IPV6INIT=no" >> /etc/sysconfig/network
echo "options ipv6 disable=1" >> /etc/modprobe.d/ipv6.conf
echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.d/ipv6.conf

# echo "ALL:ALL" >> /etc/hosts.deny  # CIS 3.4.3
# chown root:root /etc/hosts.deny     # CIS 3.4.5
# chmod 644 /etc/hosts.deny           # CIS 3.4.5
# echo "sshd:ALL" >> /etc/hosts.allow
# chown root:root /etc/hosts.allow
# chmod 644 /etc/hosts.allow

# CIS 5.1.8
[[ -w /etc/cron.deny ]] && rm /etc/cron.deny
touch /etc/cron.allow
chown root:root /etc/cron.allow
chmod 600 /etc/cron.allow

perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/bashrc
perl -npe 's/umask\s+0\d2/umask 077/g' -i /etc/csh.cshrc

echo "NOZEROCONF=yes" >> /etc/sysconfig/network

mkdir /home/macc/.ssh
touch /home/macc/.ssh/authorized_keys
chmod 700 /home/macc/.ssh
chmod 600 /home/macc/.ssh/authorized_keys
chown -R macc: /home/macc/.ssh
echo $sshpk >> /home/macc/.ssh/authorized_keys

cat <<EOT > /etc/sysconfig/network-scripts/ifcfg-ib0
NAME=ib0
DEVICE=ib0
CONNECTED_MODE=yes
ONBOOT=yes
IPV6INIT=no
BOOTPROTO=static
DEFROUTE=no
IPADDR=$ip_address_ib0
PREFIX=16
IPV4_FAILURE_FATAL=no
TYPE=InfiniBand
EOT

%end

