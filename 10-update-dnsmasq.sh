#!/bin/sh
if [ "$2" = "dhcp4-change" ] || [ "$2" = "dhcp4" ]; then
    resolv_conf="/etc/dnsmasq-resolv.conf"
    echo "# DHCP-provided DNS servers" > "$resolv_conf"
    for dns in $(nmcli -t -f IP4.DNS device show "$1" | cut -d: -f2); do
        echo "server=$dns" >> "$resolv_conf"
    done
fi
