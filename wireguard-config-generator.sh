#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only

# public network interface
# usually the same, unless using tunnel
IPV4_INTERFACE=
IPV6_INTERFACE=

# name for the wireguard interface
WG_INTERFACE=wg0

# the server's domain name or ip address
WG_SERVER_ADDRESS=

# number of client configs to generate
# must < 254
WG_CLIENT_NO=10

# DNS server for clients
DNS=1.1.1.1


# remove previously generated configs and make room for new ones
rm -vrf wgconfigs
mkdir wgconfigs

# prepare for ipv6 address generation
IPV6_ARRAY=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
gen_block () {
    echo ${IPV6_ARRAY[$RANDOM%16]}${IPV6_ARRAY[$RANDOM%16]}${IPV6_ARRAY[$RANDOM%16]}${IPV6_ARRAY[$RANDOM%16]}
}

echo generating server config
# generate the [Interface] part for the server
WG_IPV4_PREFIX=10.$(shuf -i1-254 -n1).$(shuf -i1-254 -n1).
WG_IPV6_PREFIX=fd00:$(gen_block):$(gen_block):$(gen_block)::
WG_SERVER_PORT=$(shuf -i10000-65535 -n1)

WG_SERVER_PRIVATE_KEY=$(wg genkey)
WG_SERVER_PUBLIC_KEY=$(echo "$WG_SERVER_PRIVATE_KEY" | wg pubkey)

cat > wgconfigs/${WG_INTERFACE}.conf << EOF 
[Interface]
Address = ${WG_IPV4_PREFIX}1/24
Address = ${WG_IPV6_PREFIX}1/64
SaveConfig = true
PostUp = sysctl net.ipv4.ip_forward=1 net.ipv6.conf.default.forwarding=1 net.ipv6.conf.all.forwarding=1; iptables -A FORWARD -i ${WG_INTERFACE} -j ACCEPT -w 10; iptables -t nat -A POSTROUTING -o ${IPV4_INTERFACE} -j MASQUERADE -w 10; ip6tables -A FORWARD -i ${WG_INTERFACE} -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${IPV6_INTERFACE} -j MASQUERADE -w 10
PostDown = iptables -D FORWARD -i ${WG_INTERFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${IPV4_INTERFACE} -j MASQUERADE; ip6tables -D FORWARD -i ${WG_INTERFACE} -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${IPV6_INTERFACE} -j MASQUERADE
ListenPort = ${WG_SERVER_PORT}
PrivateKey = ${WG_SERVER_PRIVATE_KEY}
EOF

# generate client configs
CLIENT_IP_SUFFIX=2
mkdir -p wgconfigs/clientconfigs
while [ $CLIENT_IP_SUFFIX -le $[$WG_CLIENT_NO+1] ]
do
echo generating client config w/ IP ${WG_IPV4_PREFIX}${CLIENT_IP_SUFFIX}, ${WG_IPV6_PREFIX}${CLIENT_IP_SUFFIX}

WG_CLIENT_PRIVATE_KEY=$(wg genkey)
WG_CLIENT_PUBLIC_KEY=$(echo "$WG_CLIENT_PRIVATE_KEY" | wg pubkey)
WG_CLIENT_PSK=$(wg genpsk)

cat > wgconfigs/clientconfigs/${WG_INTERFACE}c${CLIENT_IP_SUFFIX}.conf << EOF 
[Interface]
Address = ${WG_IPV4_PREFIX}${CLIENT_IP_SUFFIX}/32,${WG_IPV6_PREFIX}${CLIENT_IP_SUFFIX}/128
PrivateKey = ${WG_CLIENT_PRIVATE_KEY}
DNS = ${DNS}

[Peer]
PublicKey = ${WG_SERVER_PUBLIC_KEY}
PresharedKey = ${WG_CLIENT_PSK}
Endpoint = ${WG_SERVER_ADDRESS}:${WG_SERVER_PORT}
AllowedIPs = 1.0.0.0/8, 2.0.0.0/7, 4.0.0.0/6, 8.0.0.0/7, 11.0.0.0/8, 12.0.0.0/6, 16.0.0.0/4, 32.0.0.0/3, 64.0.0.0/3, 96.0.0.0/4, 112.0.0.0/5, 120.0.0.0/6, 124.0.0.0/7, 126.0.0.0/8, 128.0.0.0/3, 160.0.0.0/5, 168.0.0.0/8, 169.0.0.0/9, 169.128.0.0/10, 169.192.0.0/11, 169.224.0.0/12, 169.240.0.0/13, 169.248.0.0/14, 169.252.0.0/15, 169.255.0.0/16, 170.0.0.0/7, 172.0.0.0/12, 172.32.0.0/11, 172.64.0.0/10, 172.128.0.0/9, 173.0.0.0/8, 174.0.0.0/7, 176.0.0.0/4, 192.0.0.0/9, 192.128.0.0/11, 192.160.0.0/13, 192.169.0.0/16, 192.170.0.0/15, 192.172.0.0/14, 192.176.0.0/12, 192.192.0.0/10, 193.0.0.0/8, 194.0.0.0/7, 196.0.0.0/6, 200.0.0.0/5, 208.0.0.0/4, 224.0.0.0/4, 2000::/3
EOF

# add a peer to server config
cat >> wgconfigs/${WG_INTERFACE}.conf << EOF 

[Peer]
PublicKey = ${WG_CLIENT_PUBLIC_KEY}
PresharedKey = ${WG_CLIENT_PSK}
AllowedIPs = ${WG_IPV4_PREFIX}${CLIENT_IP_SUFFIX}/32,${WG_IPV6_PREFIX}${CLIENT_IP_SUFFIX}/128
EOF

CLIENT_IP_SUFFIX=$[$CLIENT_IP_SUFFIX+1]
done

exit 0