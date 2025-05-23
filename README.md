# TorDrop
TorDrop.sh is an automated security script designed to protect your server (in this case, a WordPress-based online store) by blocking all incoming connections from Tor exit nodes.

📌 What Does It Do? (Step by Step)
Fetches the Official Tor Exit Node List

The script downloads the latest exit node IPs from the official Tor Project URL:
https://check.torproject.org/exit-addresses

It extracts all IP addresses listed as ExitAddress, which are currently used to send traffic from the Tor network to external destinations (like your server).

Parses and Filters IPs

It isolates all lines starting with ExitAddress and pulls out the IP addresses.

Avoids Redundant Blocking

Before adding a new block, it checks if the IP is already in the iptables rules to avoid duplicates.

Adds iptables DROP Rules

For each new Tor IP, the script appends a rule to drop all incoming traffic:

iptables -A INPUT -s <TOR_IP> -j DROP

Saves the iptables Rules

A daily cronjob executes the script and saves the updated rules:

iptables-save > /etc/iptables/Tor-Drop.v1

This ensures that the blocking rules are persistent across system reboots.

✅ What’s the Purpose?
Blocks potential attackers hiding behind Tor anonymity.

Reduces noise and risk in server logs and protects public-facing services like WordPress.

Automates your server’s defense with minimal maintenance.

🧠 Real-world Use Case Example

An anonymous attacker tries to scan or exploit your e-commerce site using a Tor exit node.

Because TorDrop.sh has already blocked their IP:

Their connection is immediately dropped.

The server never processes the request.

Nothing reaches your WordPress backend or logs.

# PrivacyDrop-IPSet.sh

Advanced threat mitigation for Linux servers — evolved from TorDrop.sh
Efficiently blocks thousands of malicious IPs from Tor, VPNs, proxies, and suspicious sources using ipset.

📌 Overview
PrivacyDrop-IPSet.sh is a hardened evolution of the original TorDrop.sh script, developed for server environments that should not accept anonymous traffic, especially for production systems like e-commerce platforms (e.g. WordPress + WooCommerce).

While TorDrop.sh focused only on Tor exit nodes, PrivacyDrop-IPSet.sh expands into a full-spectrum IP reputation defense layer, blocking malicious IPs from multiple threat intelligence feeds — all managed efficiently via ipset.

✅ Key Features
⚡ Massively scalable — handles 30,000+ IPs using a single iptables rule via ipset

🌐 Multi-source blocking — includes Tor, VPNs, proxies, and suspicious IPs from FireHOL and public blocklists

🔁 Daily update support — can be scheduled via cron

🔐 Persistent — IP sets are restored at boot via a dedicated systemd service

📈 Logging — IPs added and actions performed are logged with timestamps

🧼 Auto-clean — flushes and reloads IPs daily to stay fresh and accurate

⚙️ How It Works
Downloads threat lists from various open IP reputation sources:

check.torproject.org

FireHOL Level 1/2/3

Proxy IP sets

Tor exit nodes (IPSet format)

Parses all IP addresses using strict regex validation

Deduplicates and filters invalid or malformed entries

Loads valid IPs into an ipset named privacynet

Applies a single iptables rule:


iptables -I INPUT -m set --match-set privacynet src -j DROP
Saves the ipset to disk for automatic restoration after reboot:


/etc/iptables/PrivacyDrop.ipset
Logs all activity to:


/var/log/privacydrop.log
🧩 Dependencies
ipset

iptables

curl

bash

Optional: systemd (for persistence on reboot)

Install required packages (Debian/Ubuntu):


apt update
apt install ipset iptables curl
🔁 Recommended Cronjob
Add this line to /etc/crontab for daily updates at 03:00:


0 3 * * * root /usr/local/bin/PrivacyDrop-IPSet.sh
🔄 Persistence with systemd
Create a systemd service file /etc/systemd/system/privacydrop-ipset.service:


[Unit]
Description=Restore ipset for PrivacyDrop blocked IPs
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/sbin/ipset flush privacynet && /sbin/ipset restore < /etc/iptables/PrivacyDrop.ipset'

[Install]
WantedBy=multi-user.target
Enable the service:


systemctl daemon-reload
systemctl enable privacydrop-ipset
📊 Logging Example

[2025-05-22 03:00:12] Downloading: https://check.torproject.org/exit-addresses
[2025-05-22 03:00:14] IP added to ipset: 185.220.101.20
[2025-05-22 03:00:21] Total IPs added to ipset: 32877
[2025-05-22 03:00:21] ipset saved successfully.
🚫 Why block anonymous networks?
This tool is ideal for services where no legitimate traffic should originate from Tor, VPNs, or proxies — such as:

Online stores

Admin panels

REST APIs

Payment processors

Webmail

📦 Roadmap / Extensions
 Systemd boot-time restore

 Logging per IP + timestamp

 GeoIP-based whitelist/blacklist (coming soon)

 Telegram / email alerts on large-scale block activity

 Real-time dashboard or stats collector

🙌 Credits
Inspired by the original TorDrop.sh and enhanced for broader threat coverage and high performance environments.

# 🌍 GeoBlock.sh

Country-based firewall for Linux using ipset + iptables
Allow only selected countries, block the rest. Simple. Powerful. Efficient.

✅ Purpose
GeoBlock.sh is a country-level traffic control script for Linux servers.
It creates a whitelist of countries using ipset and blocks all other traffic by default via iptables.

This is perfect for:

E-commerce platforms (like WordPress + WooCommerce)

APIs and admin panels restricted to specific regions

Servers exposed to the internet but meant for regional access only

🌐 How It Works
Defines a list of allowed countries, e.g.:

European Union (EU)

Mexico 🇲🇽, Argentina 🇦🇷, Brazil 🇧🇷

United States 🇺🇸, Japan 🇯🇵

Fetches country IP blocks from ipdeny.com

Builds an ipset set (geoallow) with all allowed IP ranges

Applies iptables rules:

Accept all traffic from the allowed countries

Drop everything else

Logs all actions to /var/log/geoblock.log

Saves the ipset set to /etc/iptables/GeoBlock.ipset for persistent reloading after reboot

⚙️ Features
✅ Block-by-default policy

🌎 Easily configurable list of allowed countries

⚡ Fast and efficient thanks to ipset

🛠 Integrates with existing firewalls

📝 Full logging for traceability

🔁 Persistence-ready (via systemd)

🧩 Dependencies
ipset

iptables

curl

Bash shell

Install them with:


apt update
apt install ipset iptables curl
🚀 Usage

chmod +x GeoBlock.sh
./GeoBlock.sh
This will:

Create the geoallow ipset set

Load country IP blocks

Add the iptables rules

Save the rules to a persistent file

🔄 Persistence with systemd
To reload after reboot, use this service:

/etc/systemd/system/geoblock.service


[Unit]
Description=Restore GeoBlock ipset rules
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '/sbin/ipset flush geoallow && /sbin/ipset restore < /etc/iptables/GeoBlock.ipset'

[Install]
WantedBy=multi-user.target
Then:


systemctl daemon-reload
systemctl enable geoblock
📋 Logging
All events are logged to:

/var/log/geoblock.log

Example:

[2025-05-23 01:09:07] Loading IPs for country: br
[2025-05-23 01:10:59] Added iptables ACCEPT rule for geoallow
[2025-05-23 01:10:59] Added iptables DROP rule (default deny)
[2025-05-23 01:10:59] GeoBlock execution completed.
🔐 Default Allowed Countries
By default, the script includes:

EU member states (AT, BE, DE, FR, etc.)

🇲🇽 Mexico

🇦🇷 Argentina

🇧🇷 Brazil

🇺🇸 United States

🇯🇵 Japan

You can edit the list in the script by modifying:

ALLOW_COUNTRIES=(at be bg hr cy cz dk ee fi fr de gr hu ie it lv lt lu mt nl pl pt ro sk si es se mx ar br us jp)
📦 Future Ideas
Interactive country selector

Integration with GeoIP databases (MaxMind)

Logging by rejected country

Scheduled updates via cron







[ CodeName : #Aracne ]

