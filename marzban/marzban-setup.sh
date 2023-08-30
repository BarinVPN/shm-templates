#!/usr/bin/env bash
set -e

[ -z "$SERVER_HOST" ] && echo "Error: SERVER_HOST not defined" && exit 1
[ -z "$TOKEN" ] && echo "Error: TOKEN not defined" && exit 1

echo "Configure Marzban server host..."
PAYLOAD="$(cat <<-EOF
{
  "VMess TCP": [
    {
      "remark": "🚀 Marz ({USERNAME}) [{PROTOCOL} - {TRANSPORT}]",
      "address": "$SERVER_HOST",
      "port": null,
      "sni": null,
      "host": null,
      "security": "inbound_default",
      "alpn": "",
      "fingerprint": ""
    }
  ],
  "VMess Websocket": [
    {
      "remark": "🚀 Marz ({USERNAME}) [{PROTOCOL} - {TRANSPORT}]",
      "address": "$SERVER_HOST",
      "port": null,
      "sni": null,
      "host": null,
      "security": "inbound_default",
      "alpn": "",
      "fingerprint": ""
    }
  ],
  "VLESS TCP REALITY": [
    {
      "remark": "🚀 Marz ({USERNAME}) [{PROTOCOL} - {TRANSPORT}]",
      "address": "$SERVER_HOST",
      "port": null,
      "sni": null,
      "host": null,
      "security": "inbound_default",
      "alpn": "",
      "fingerprint": ""
    }
  ],
  "VLESS GRPC REALITY": [
    {
      "remark": "🚀 Marz ({USERNAME}) [{PROTOCOL} - {TRANSPORT}]",
      "address": "$SERVER_HOST",
      "port": null,
      "sni": null,
      "host": null,
      "security": "inbound_default",
      "alpn": "",
      "fingerprint": ""
    }
  ],
  "Trojan Websocket TLS": [
    {
      "remark": "🚀 Marz ({USERNAME}) [{PROTOCOL} - {TRANSPORT}]",
      "address": "$SERVER_HOST",
      "port": null,
      "sni": null,
      "host": null,
      "security": "inbound_default",
      "alpn": "",
      "fingerprint": ""
    }
  ],
  "Shadowsocks TCP": [
    {
      "remark": "🚀 Marz ({USERNAME}) [{PROTOCOL} - {TRANSPORT}]",
      "address": "$SERVER_HOST",
      "port": null,
      "sni": null,
      "host": null,
      "security": "inbound_default",
      "alpn": "",
      "fingerprint": ""
    }
  ]
}
EOF
)"

curl -sk -XPUT \
  "$MARZBAN_HOST/api/hosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d "$PAYLOAD"

echo "done\n"


echo "Configure certificates..."
if [[ -z "$SUBSCRIPTION_DOMAIN" || -z "$EMAIL_FOR_CERTIFICATE_ISSUE" ]]; then
    echo "WARNING: Skipping the certificate installation due to the absence of a SUBSCRIPTION_DOMAIN or EMAIL_FOR_CERTIFICATE_ISSUE"
    exit 0
fi

DIR=/var/lib/marzban/certs
mkdir -p $DIR

if [[ $(netstat -anp | grep '\:80\s') ]]; then
    echo "ERROR: Port 80 is already in use!"
    echo "Shutdown Ngnix or Apache before run this script."
    echo "After running this script, you will be able to run Nginx or Apache again."
    exit 1
fi

curl -s https://get.acme.sh | sh -s email=$EMAIL_FOR_CERTIFICATE_ISSUE

~/.acme.sh/acme.sh \
    --set-default-ca \
    --server letsencrypt  \
    --issue \
    --standalone \
    --key-file $DIR/key.pem \
    --fullchain-file $DIR/fullchain.pem \
    -d $SUBSCRIPTION_DOMAIN

echo 'UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/fullchain.pem"' >> /opt/marzban/.env
echo 'UVICORN_SSL_KEYFILE = "/var/lib/marzban/certs/key.pem"' >> /opt/marzban/.env
echo "XRAY_SUBSCRIPTION_URL_PREFIX = \"https://$SUBSCRIPTION_DOMAIN\":$UVICORN_PORT" >> /opt/marzban/.env

marzban restart -n

