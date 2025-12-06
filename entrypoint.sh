#!/bin/sh
set -e

echo "=== NUT SNMP UPS Daemon Starting ==="
echo "UPS Name: ${NAME}"
echo "Server: ${SERVER}"
echo "Driver: ${DRIVER}"
echo "SNMP Community: ${SNMP_COMMUNITY}"
echo "SNMP Version: ${SNMP_VERSION}"

# Generate nut.conf
cat > /etc/nut/nut.conf << EOF
MODE=netserver
EOF

# Generate ups.conf for SNMP driver
cat > /etc/nut/ups.conf << EOF
maxretry = 3

[${NAME}]
    driver = ${DRIVER}
    port = ${SERVER}
    desc = "${DESCRIPTION}"
    community = ${SNMP_COMMUNITY}
    snmp_version = ${SNMP_VERSION}
    pollfreq = ${POLLFREQ}
    mibs = auto
EOF

# Generate upsd.conf
cat > /etc/nut/upsd.conf << EOF
MAXAGE ${MAXAGE}
LISTEN 0.0.0.0 ${PORT}
EOF

# Generate upsd.users
cat > /etc/nut/upsd.users << EOF
[${API_USER}]
    password = ${SECRET}
    actions = SET
    instcmds = ALL
    upsmon primary

[monuser]
    password = ${SECRET}
    upsmon secondary
EOF

# Fix permissions
chown -R root:nut /etc/nut
chmod 640 /etc/nut/*
chown -R nut:nut /run/nut /var/state/ups

echo "=== Configuration files generated ==="

# Verify snmp-ups driver exists
if [ ! -f /usr/lib/nut/snmp-ups ]; then
    echo "ERROR: snmp-ups driver not found at /usr/lib/nut/snmp-ups"
    exit 1
fi

echo "=== Starting UPS driver via upsdrvctl ==="
/usr/sbin/upsdrvctl -u root start

# Wait for driver socket
echo "Waiting for driver socket..."
sleep 5

echo "=== Starting upsd ==="
/usr/sbin/upsd -u root
sleep 2

# Generate webNUT config
echo "=== Starting webNUT dashboard on port ${WEBNUT_PORT} ==="
mkdir -p /etc/webnut
cat > /etc/webnut/webnut.ini << EOF
[app:main]
use = egg:webNUT

pyramid.reload_templates = false
pyramid.debug_authorization = false
pyramid.debug_notfound = false
pyramid.debug_routematch = false

nut.host = localhost
nut.port = ${PORT}

[server:main]
use = egg:waitress#main
host = 0.0.0.0
port = ${WEBNUT_PORT}

[loggers]
keys = root

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = INFO
handlers = console

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(asctime)s %(levelname)-5.5s [%(name)s] %(message)s
EOF

# Start webNUT in the foreground
exec pserve /etc/webnut/webnut.ini
