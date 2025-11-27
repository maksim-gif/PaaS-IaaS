#!/bin/bash
# SSL Certificate renewal script for HAProxy

DOMAIN="{{ ssl_domain }}"
EMAIL="{{ ssl_email }}"
ACME_HOME="/usr/local/share/acme.sh"
HAPROXY_SOCKET="/var/run/haproxy/admin.sock"
SSL_PATH="/etc/haproxy/ssl"

export HOME=/var/lib/acme

echo "$(date): Starting SSL certificate renewal for $DOMAIN"

# Renew certificate
/usr/local/bin/acme.sh --renew -d $DOMAIN --stateless --server letsencrypt

if [ $? -eq 0 ]; then
    echo "$(date): Certificate renewed successfully"
    
    # Deploy to HAProxy
    DEPLOY_HAPROXY_STATS_SOCKET=$HAPROXY_SOCKET \
    DEPLOY_HAPROXY_PEM_PATH=$SSL_PATH \
    /usr/local/bin/acme.sh --deploy -d $DOMAIN --deploy-hook haproxy
    
    if [ $? -eq 0 ]; then
        echo "$(date): Certificate deployed to HAProxy successfully"
        # Reload HAProxy configuration
        echo "reload" | socat stdio $HAPROXY_SOCKET
        echo "$(date): HAProxy reloaded with new certificate"
    else
        echo "$(date): ERROR: Failed to deploy certificate to HAProxy"
        exit 1
    fi
else
    echo "$(date): ERROR: Certificate renewal failed"
    exit 1
fi
