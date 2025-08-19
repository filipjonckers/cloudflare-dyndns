#!/bin/bash
# This script updates the dynamic DNS record for a domain using the DynDNS service Cloudflare API.
CF_API_KEY="your_cloudflare_api_key_here"
# CF_API_KEY="don-8P9cnf1_Ydzd2A5T_8wmvMXbEvVsA0WQ9Wi0"
# Zone ID: In Cloudflare Dashboard, select your domain → Overview → right sidebar under API
ZONE_ID="your_zone_id_here"
# DNS record ID: In Cloudflare Dashboard, select your domain → DNS → click on the record you want to update → right sidebar under API
# You can also use the API to list all DNS records and find the ID (see below)
DNS_RECORD_ID="your_dns_record_id_here"
HOSTNAME="test-hostname"
TTL=300  # Time to live in seconds

TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%SZ)
echo "Starting DNS update at $TIMESTAMP"

# determine external IP address
IP=$(curl -s http://api.ipify.org)
if [ -z "$IP" ]; then
  echo "Failed to retrieve IP address."
  exit 1
fi

# check IP4 format correctness
if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid IP address format: $IP"
  exit 1
fi


# List all DNS records to find the DNS_RECORD_ID
# curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
#      -H "Authorization: Bearer $CF_API_KEY" \
#      -H "Content-Type: application/json"


echo "Update cloudflare DNS record for $HOSTNAME with IP $IP"

curl https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID \
    -X PUT \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $CF_API_KEY" \
    --data @- <<EOF
{
    "name": "$HOSTNAME",
    "ttl": $TTL,
    "type": "A",
    "comment": "updated $TIMESTAMP",
    "content": "$IP",
    "proxied": false
}
EOF


if [ $? -eq 0 ]; then
  echo "DNS record updated successfully."
  logger "Cloudflare DNS record for $HOSTNAME updated to $IP at $TIMESTAMP"
else
  echo "Failed to update DNS record."
  logger "Failed to update Cloudflare DNS record for $HOSTNAME at $TIMESTAMP"
  exit 1
fi
