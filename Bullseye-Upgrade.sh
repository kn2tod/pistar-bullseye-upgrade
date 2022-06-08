#!/bin/bash
# Upgrade Pi-Star Buster system to Bullseye in-place:
# 
# Basic updates/changes:
#   1) change boot device for consistency with all current Raspbian systems
#   2) remove UI option from APT packages
#   3) update APT packages to point to Bullseye archives
#   4) install PHP/FPM 7.4 (7.0 version removed in Bullseye)
#   5) repoint python to 3.9; fix selected pistar py programs
#
# Assumptions:
#   Starting from a current Raspbian/Pi-Star system: all applicable updates applied
#   Tested on a fully-wired (ethernet) system
#
# Pre/Post-Install Anomalies:
#   1) Upgrade via wifi problematic because of DNS changes during upgrade may cause disconnect(s)
#   2) /home/pi-star/.config directory deleted?
#   3) only three know Python programs fixed for 3.9.  Others may be modified
#
#rpi-rw
t1=$SECONDS
echo "===============================> Start in-place Buster -> Bullseye update process:"
sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot
#
# Change the cmdline file to be consistent with current Raspbian boots:
uuid=$(ls -la /dev/disk/by-partuuid | sed -n 's/^.* \([[:alnum:]]*-[0-9]* \).*/\1/p' | sed -n 's/\(.*\)-.*/\1/p' | head -n 1)
sudo sed -i.bak "s|\/dev\/mmcblk0p2 |PARTUUID=$uuid-02 |g" /boot/cmdline.txt
sudo sed -i.bak "s|\/dev\/mmcblk0p2 |PARTUUID=$uuid-02 |g; s| quiet | |g" /boot/cmdline.txt
sudo sed -i.bak "s|\/dev\/mmcblk0p1|PARTUUID=$uuid-01|g" /etc/fstab
sudo sed -i "s|\/dev\/mmcblk0p2|PARTUUID=$uuid-02|g" /etc/fstab
sudo sed -i.bak "s/mmcblk0p2 /\x2e\x2a /g" /etc/bash.bashrc
source /etc/bash.bashrc
echo "===============================> boot code modified"
read -p "-- press any key to continue --" ipq
#
echo "===============================> Initial OS info:"
sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot
# ref: https://ostechnix.com/upgrade-to-debian-11-bullseye-from-debian-10-buster/
cat /etc/debian_version         # display current system/version
echo "==="
hostnamectl                     # display debian codename
echo "==="
uname -mrs
echo "==="
cat /boot/cmdline.txt
echo "==="
cat /etc/fstab
echo "==="
ls -la /etc/resolv.conf
#
read -p "-- press any key to continue --" ipq
#
echo "===============================> Make it up-to-date:"
if [ ! "$(grep bullseye /etc/apt/sources.list)" ]; then   # (skip if this proc has been restarted)
sudo apt update
read -p "-- press any key to continue --" ipq
echo "==="
sudo apt upgrade --fix-missing --fix-broken -y
read -p "-- press any key to continue --" ipq
#
echo "===============================> Cleanup:"
sudo apt clean
sudo apt autoremove -y
#
echo "===============================> Preliminary updates finished"
read -p "-- press any key to continue --" ipq
fi
#
#sudo su                # make sure Pi-Star is update to date
#pistar-update
#
#mkdir ~/apt            # backup APT packages
#sudo cp /etc/apt/sources.list ~/apt
#sudo cp -rv /etc/apt/sources.list.d/ ~/apt
#
echo "===============================> Mod APT source lists for new OS:"
sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot
sudo sed -i 's/buster/bullseye/g' /etc/apt/sources.list
sudo sed -i 's/buster/bullseye/g' /etc/apt/sources.list.d/*
#
# ref: https://forums.raspberrypi.com/viewtopic.php?t=318159 UI problem:
sudo sed -i 's/main ui/main # ui/g' /etc/apt/sources.list.d/raspi.list
sudo mv /etc/apt/sources.list.d/stretch-backports.list /etc/apt/sources.list.d/buster-backports.list
#
echo "==="
cat /etc/apt/sources.list
echo "==="
cat /etc/apt/sources.list.d/raspi.list
echo "==="
cat /lib/systemd/system/dhcpcd.service
echo "==="
cat /etc/systemd/system/dhcpcd.service.d/wait.conf
echo "==="
ls -la /etc/resolv.conf
sudo cp -p /etc/resolv.conf /home/pi-star/resolv.conf.sav
#
read -p "-- press any key to continue --" ipq
echo "===============================> Start OS update"
sudo apt-mark hold dhcpcd5    # add per: https://github.com/pi-hole/pi-hole/issues/4051  ???
echo "==="
sudo apt update -y  # -q? -qq?
echo "==="
#cat /lib/systemd/system/dhcpcd.service
read -p "-- press any key to continue --" ipq
echo "===============================> Start OS upgrade"
sudo apt upgrade --without-new-pkgs -y   # reply "N" for all; -q? -qq?
echo "==="
cat /lib/systemd/system/dhcpcd.service
echo "==="
cat /etc/systemd/system/dhcpcd.service.d/wait.conf
#
echo "--Half-way there!"
read -p "--Complete upgrade? (Y/n)?" ipq
if [ "$ipq" == "Y" ]; then
#
echo "==="
ls -la /etc/resolv.conf
sudo ln -sf /var/lib/dhcpcd/resolv.conf /etc/resolv.conf
sudo mkdir /var/lib/dhcpcd
sudo cp /home/pi-star/resolv.conf.sav /var/lib/dhcpcd/resolv.conf
sudo systemctl daemon-reload
sudo systemctl restart dhcpcd.service
echo "==="
ls -la /etc/resolv.conf
#
read -p "-- press any key to continue --" ipq
# ref: https://forums.raspberrypi.com/viewtopic.php?t=320383 DHCPCD problem:
echo "===============================> Finish upgrade:"
sudo apt full-upgrade -y                 # reply "N" for all; tab-OK for all; -q? -qq?
read -p "-- press any key to continue --" ipq
#
echo "===============================> Cleanup:"
sudo apt autoremove -y
#
read -p "-- press any key to continue --" ipq
echo "===============================> Install new PHP w/FPM:"
# ref: https://www.linuxcapable.com/how-to-install-php-7-4-on-debian-11-bullseye/
sudo apt install php7.4 php7.4-fpm php7.4-cli -y
sudo sed -i "s/php7.0-/php7.4-/g" /etc/nginx/default.d/php.conf
echo "==="
cat /etc/nginx/default.d/php.conf
echo "==="
cat /lib/systemd/system/nginx.service
#echo "Checking nginx config"
if ! [ $(cat /lib/systemd/system/nginx.service | grep -o "mkdir") ]; then
  sudo sed -i '\/PIDFile=\/run\/nginx.pid/a ExecStartPre=\/bin\/mkdir -p \/var\/log\/nginx' /lib/systemd/system/nginx.service
  sudo systemctl daemon-reload
# sudo systemctl restart nginx.service
  echo "nginx config repaired"
  cat /lib/systemd/system/nginx.service
fi
echo "==="
sudo nginx -t
sudo systemctl restart nginx
echo "==="
php --version
echo "==="
pstree
read -p "-- press any key to continue --" ipq
echo "==============================> correct python issues:"
sudo ln -s /usr/bin/python3.9 /usr/bin/python    #  link python generic to 3.9
#
sudo sed -i 's/ ConfigParser/ configparser/g' /usr/local/sbin/pistar-watchdog
sudo sed -i 's/ ConfigParser/ configparser/g' /usr/local/sbin/pistar-remote
sudo sed -i 's/ ConfigParser/ configparser/g' /usr/local/sbin/pistar-keeper
#
sudo sed -i 's/^\x20\{8\}/\t/g'               /usr/local/sbin/pistar-watchdog
sudo sed -i 's/^\x20\{8\}/\t/g'               /usr/local/sbin/pistar-remote
sudo sed -i 's/^\x20\{8\}/\t/g'               /usr/local/sbin/pistar-keeper
#
sudo sed -i '20,$ s/\x20\{8\}/\t/g'           /usr/local/sbin/pistar-watchdog
sudo sed -i '20,$ s/\x20\{8\}/\t/g'           /usr/local/sbin/pistar-remote
#
sudo sed -i 's/if "not" in checkprocremote:/if b"not" in checkprocremote:/g' /usr/local/sbin/pistar-watchdog
#
echo "==============================> Final OS info:"
cat /etc/debian_version
echo "==="
hostnamectl
echo "==="
uname -mrs
echo "==="
cat /boot/cmdline.txt
#
echo "==============================> /Boot info doc info:"
sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot
cd /boot
f=$(hostname).gen.txt
m1=$(tac $(ls -1t /var/log/pi-star/MMDVM-*.log 2>/dev/null) /dev/null | grep "protocol" -m 1 | sed -n "s|.*\(v[0-9]*\x2e[0-9]*\x2e[0-9]*\).*|\1|p")
m2=$(sed -n "/\[Modem\]/{n;p;}" /etc/dstar-radio.mmdvmhost | awk -F "=" '/Hardware/ {print $2}')
m3=$(hostnamectl 2>/dev/null | sed -n "s/.* System: .* (\([a-zA-Z0-9]*\))/\u\1/p")
#
sudo echo "Modified: $(date +%Y-%m-%d" "%H:%M:%S)" > $f
sudo echo "Software: $(sed -n 's|$version = \x27\([0-9]\{4\}\)\([0-9][0-9]\)\([0-9]*\)\x27;|\1/\2/\3|p' /var/www/dashboard/config/version.php)  Ver: $(sed -n 's/Version = \(.*\)/\1/p' /etc/pistar-release)  $m3: $(cat /etc/debian_version)  Kernel: $(uname -r)" >> $f
sudo echo "Hardware: ($(sed -n 's|^Model.*: Raspberry \(.*\)|\1|p' /proc/cpuinfo | sed 's/ Model //g' | sed 's/ Plus/+/g')) - Modem: $m1 ($m2) - Disk: ("$(blkid | sed -n 's/\/dev\/\(.*2\):.*/\1/p')")" >> $f
cat $f
#
#sudo mkdir /home/pi-star/.config      # deleted during update?!?
#
#--------------------------------------------------------------------------
# -- still a problem:
#sudo apt-mark unhold dhcpcd5
#sudo apt update -y
#sudo apt upgrade -y
# -- does this directory need to be in temp stg?
#sudo sed -i 's/^tmpfs\(.*\)\/var\/lib\/dhcpcd5\(.*\)/#tmpfs\1\/var\/lib\/dhcpcd5\2/g' /etc/fstab  # ????
#sudo sed -i 's/^#tmpfs\(.*\)\/var\/lib\/dhcpcd5\(.*\)/tmpfs\1\/var\/lib\/dhcpcd5\2/g' /etc/fstab  # ????
#
echo "==============================> End of Buster-Bullseye upgrade"
t2=$SECONDS
echo "--- (time to complete upgrade: " $(($t2-$t1)) "secs)"
#
# By this point, system should be fully upgraded and operational; reboot if you want
#rpi-ro
sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot
#
fi
# reboot?
#
# Some usefull items to consider as part of base:
#sudo apt install ethtool ascii htop lsof procinfo tree ntpstat sysstat nmap lsb-release dnsutils
#
# -- misc installation notes
# log of responses:
#  1) response during "upgrade w/o new pkgs":
#  etc/sudoers
#  etc/nanorc
#  etc/logrotate.conf
#  etc/default/rcS
#
#  2) responses during "full-upgrade":
#  etc/default/useradd
#  etc/logrotate.d/rsyslog
#  etc/rsyslog.conf
#  etc/nginx/nginx.conf
#  TAB-OK: run/samba/upgrades/smb.conf
#  etc/default/dnsmasq
#  etc/dnsmasq.conf
#  etc/logrotate.d/exim4-base
#  etc/logrotate.d/exim4-paniclog
#  etc/sysctl.conf
#  TAB-OK: /tmp... --> etc/ssh/ssh.conf
#  TAB-OK: /usr/share/unattended-upgrades/50unattended-upgrades  (cmt chg only?)
#  etc/init.d/nmbd
#  etc/init.d/smbd
#
# Modified: 2022-06-05 10:35:19
# Software: 2022/05/12  Ver: 4.1.6  Bullseye: 11.3  Kernel: 5.15.32-v7l+
# Hardware: (Pi 4B Rev 1.1) - Modem:  () - Disk: (sda2)
