#!/bin/bash

# This script generates a random SSID and password for the guest network
# and updates the wireless configuration accordingly. It also creates an
# HTML file with the guest network credentials and a QR code SVG file for
# easy sharing. The guest network SSID is matched based on a pattern.

# Usage:
# save into /root
# set to executable - chmod +x ./newguestpass.sh
# add cronjob to change credentials 1st of the month at 0300
# 0 3 1 * * /root/newguestpass.sh


# Configuration variables
HTML_PATH="/www/luci-static/guest.html" # bookmark e.g. http://192.168.1.1/luci-static/guest.html
SVG_PATH="/www/luci-static/wifi.svg"
GUEST_SSID="*guest*" # SSID pattern to match guest network
PASSWORD_LENGTH=8

# Check for required dependencies
if ! command -v qrencode &> /dev/null; then
    echo "qrencode is not installed. Please install it to proceed."
    exit 1
fi


# Generate random SSID and password
password=$(cat /dev/urandom | env LC_CTYPE=C tr -dc _ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjklmnpqrstuvwxyz23456789 | head -c $PASSWORD_LENGTH)
datec=$(date +%Y-%m-%dT%H:%M:%SZ)

# Generate random 3-digit number and append to SSID
random_digits=$(printf "%03d" $((RANDOM % 1000)))
ssid="guest-${random_digits}"

# Update wireless configuration
i=0
while uci get wireless.@wifi-iface[$i].ssid &> /dev/null; do
    if [[ $(uci get wireless.@wifi-iface[$i].ssid) == $GUEST_SSID ]]; then
        echo "Updating SSID and password for interface wireless.@wifi-iface[$i]"
        uci set wireless.@wifi-iface[$i].ssid=$ssid
        uci set wireless.@wifi-iface[$i].key=$password
        uci commit wireless
        wifi
    fi
    i=$((i + 1))
done


# Create HTML file
cat <<EOF > $HTML_PATH
<!DOCTYPE html>
<html lang="en-US">
<head>
    <title>Guest Password</title>
    <meta name="viewport" content="width=device-width, height=device-height, initial-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="refresh" content="360">
</head>
<body bgcolor="#000">
    <div style="text-align:center;color:#fff;font-family:UnitRoundedOT,Helvetica Neue,Helvetica,Arial,sans-serif;font-size:28px;font-weight:500;">
        <h1>Guest WiFi</h1>
        <p>Network: <b>$ssid</b></p>
        <p>Password: <b>$password</b></p>
        <img src="wifi.svg" style="width:50%"><br>
        <p>Open the camera app and scan to connect</p>
    </div>
</body>
</html>
EOF

# Create QR code SVG file
security="WPA2"  # Assuming WPA security type, adjust if needed
qrencode -t SVG -o $SVG_PATH "WIFI:S:$ssid;T:$security;P:$password;;"
