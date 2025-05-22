#!/bin/bash

# Script para bloquear IPs de salida Tor con iptables
# Fuente: https://check.torproject.org/exit-addresses

# Obtener lista de IPs de salida Tor
TOR_LIST=$(curl -s https://check.torproject.org/exit-addresses | grep ExitAddress | awk '{print $2}')

# Evitar duplicados cargando IPs ya bloqueadas
EXISTING=$(iptables -L INPUT -n | grep DROP | awk '{print $4}')

# Iterar sobre IPs y bloquear si no están ya bloqueadas
for ip in $TOR_LIST; do
    if ! echo "$EXISTING" | grep -q "^$ip$"; then
        iptables -A INPUT -s $ip -j DROP
        echo "Bloqueada IP Tor: $ip"
    fi
done
