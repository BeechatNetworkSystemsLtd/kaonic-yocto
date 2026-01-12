#!/usr/bin/sh

systemctl stop hostapd
systemctl stop systemd-networkd.socket
systemctl stop systemd-networkd

ip link set wlan0 nomaster
ip link set wlan0 down

# Set WiFi link Up
ip link set wlan0 up

wpa_passphrase $1 $2 >> /etc/wpa_supplicant.conf
wpa_supplicant -B -iwlan0 -c /etc/wpa_supplicant.conf

iw wlan0 link

udhcpc -i wlan0

