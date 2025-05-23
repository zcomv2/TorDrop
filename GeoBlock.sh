#!/bin/bash

# === GeoBlock.sh ===
# Bloquea TODO el tráfico por defecto, excepto los países permitidos.
# Países permitidos: EU + MX, AR, BR, US, JP
# Descarga listas desde ipdeny.com y configura ipset + iptables

LOG_FILE="/var/log/geoblock.log"
IPSET_NAME="geoallow"
ALLOW_COUNTRIES=(at be bg hr cy cz dk ee fi fr de gr hu ie it lv lt lu mt nl pl pt ro sk si es se mx ar br us jp)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting GeoBlock.sh" >> "$LOG_FILE"

# Verificar dependencias
if ! command -v ipset >/dev/null; then
    echo "ipset not found. Install it first."
    exit 1
fi
if ! command -v curl >/dev/null; then
    echo "curl not found. Install it first."
    exit 1
fi

# Crear el set si no existe
if ! ipset list -n | grep -q "^$IPSET_NAME$"; then
    ipset create $IPSET_NAME hash:net
else
    ipset flush $IPSET_NAME
fi

# Descargar y cargar rangos IP por país
for cc in "${ALLOW_COUNTRIES[@]}"; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Loading IPs for country: $cc" >> "$LOG_FILE"
    curl -s "https://www.ipdeny.com/ipblocks/data/countries/${cc}.zone" | while read -r net; do
        ipset add $IPSET_NAME "$net" 2>/dev/null
    done
done

# Añadir regla iptables si no existe
if ! iptables -C INPUT -m set --match-set $IPSET_NAME src -j ACCEPT 2>/dev/null; then
    iptables -I INPUT -m set --match-set $IPSET_NAME src -j ACCEPT
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Added iptables ACCEPT rule for geoallow" >> "$LOG_FILE"
fi

# Regla para rechazar el resto (después de permitir conexiones existentes)
if ! iptables -C INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null; then
    iptables -I INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
fi
if ! iptables -C INPUT -s 127.0.0.0/8 -j ACCEPT 2>/dev/null; then
    iptables -I INPUT -s 127.0.0.0/8 -j ACCEPT
fi
if ! iptables -C INPUT -j DROP 2>/dev/null; then
    iptables -A INPUT -j DROP
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Added iptables DROP rule (default deny)" >> "$LOG_FILE"
fi

# Guardar ipset
mkdir -p /etc/iptables
echo "flush $IPSET_NAME" > /etc/iptables/GeoBlock.ipset
ipset save $IPSET_NAME | grep -v '^create ' >> /etc/iptables/GeoBlock.ipset

echo "[$(date '+%Y-%m-%d %H:%M:%S')] GeoBlock execution completed." >> "$LOG_FILE"
