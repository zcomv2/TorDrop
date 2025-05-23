#!/bin/bash

# === PrivacyDrop-IPSet.sh ===
# Versión optimizada con ipset para bloquear tráfico sospechoso (Tor, VPN, Proxies, centros de datos)
# Ideal para tiendas web con usuarios domésticos legítimos
# Más rápido, más eficiente, más limpio

# === Configuración ===
LOG_FILE="/var/log/privacydrop.log"
BLOCKED_IP_LIST="/tmp/privacydrop_ipset_ips.txt"
IPSET_NAME="privacynet"
IPSET_SAVE_FILE="/etc/iptables/PrivacyDrop.ipset"

# === Fuentes de IPs sospechosas ===
SOURCES=(
    "https://check.torproject.org/exit-addresses"
    "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset"
    "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
    "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level3.netset"
    "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/proxy-list.ipset"
    "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/tor-exit-nodes.ipset"
)

# === Inicio ===
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting PrivacyDrop-IPSet execution." >> "$LOG_FILE"
> "$BLOCKED_IP_LIST"

# === Descargar listas ===
for url in "${SOURCES[@]}"; do
    curl -s "$url" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' >> "$BLOCKED_IP_LIST"
done

sort -u "$BLOCKED_IP_LIST" -o "$BLOCKED_IP_LIST"

# === Crear ipset si no existe ===
if ! ipset list -n | grep -q "^$IPSET_NAME$"; then
    ipset create $IPSET_NAME hash:ip timeout 0
fi

# === Vaciar ipset antes de recargar ===
ipset flush $IPSET_NAME

# === Cargar IPs en el set ===
while read -r ip; do
    ipset add $IPSET_NAME "$ip"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Blocked IP via ipset: $ip" >> "$LOG_FILE"
done < "$BLOCKED_IP_LIST"

# === Añadir regla de iptables si no existe ===
if ! iptables -C INPUT -m set --match-set $IPSET_NAME src -j DROP 2>/dev/null; then
    iptables -I INPUT -m set --match-set $IPSET_NAME src -j DROP
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] iptables rule added for ipset $IPSET_NAME" >> "$LOG_FILE"
fi

# === Guardar ipset persistente ===
ipset save $IPSET_NAME > "$IPSET_SAVE_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Saved ipset to $IPSET_SAVE_FILE" >> "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] PrivacyDrop-IPSet execution completed." >> "$LOG_FILE"
