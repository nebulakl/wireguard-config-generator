# wireguard-config-generator
A simple shell script to generate Wireguard configs only

## What it does
Generate working server and client configuration files. The server config only works on Linux but client configs should work on any OS.

The script requires prior knowledge of the server's network interface and IP address and/or domain name to work.

**Note: each time the script is run, all previously generated configs under `wgconfigs` will be removed.**

## What it does not
Set up a Wireguard server from scratch. For that purpose please check out other people's excellent work.
Some examples are:
* https://github.com/angristan/wireguard-install
* https://github.com/alvistack/ansible-role-wireguard
* https://github.com/burghardt/easy-wg-quick

## Features
* Randomly generated IPv4 and IPv6 addresses
* Randomly generated port number
* Randomly generated pre-shared key, unique to each client

## Prerequisites
* Relatively new `bash`
* `shuf`
* `wireguard-tools`

## Getting started
1. modify the variables at the beginning of the script accordingly
2. run the script
3. Copy the generated server config (`wgconfigs/${WG_INTERFACE}.conf`) to the server and bring it up with `wg-quick`
4. Copy the generated client configs (`wgconfigs/clientconfigs/*.conf`) to the clients