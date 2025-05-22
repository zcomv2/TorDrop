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

[ CodeName : #Aracne ]

