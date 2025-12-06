# syntax=docker/dockerfile:1
# NUT UPS Tools with SNMP support and web dashboard
# Based on instantlinux/nut-upsd pattern

FROM alpine:3.21

LABEL org.opencontainers.image.title="nut-snmp" \
      org.opencontainers.image.description="Network UPS Tools with SNMP driver and web dashboard" \
      org.opencontainers.image.source="https://github.com/LukeEvansTech/talos-cluster"

# Environment variables for configuration
ENV API_USER=upsmon \
    DESCRIPTION="APC UPS" \
    DRIVER=snmp-ups \
    GROUP=nut \
    MAXAGE=25 \
    NAME=apc \
    POLLFREQ=15 \
    PORT=3493 \
    SECRET=secret \
    SERVER=localhost \
    SNMP_COMMUNITY=public \
    SNMP_VERSION=v2c \
    USER=nut \
    # webNUT settings
    WEBNUT_PORT=6543

# Install NUT, SNMP dependencies, and Python for webNUT
RUN apk add --no-cache \
      nut \
      net-snmp \
      net-snmp-libs \
      libcrypto3 \
      libssl3 \
      python3 \
      py3-pip && \
    # Install webNUT
    pip3 install --no-cache-dir --break-system-packages webNUT && \
    # Create runtime directories
    mkdir -p /run/nut /var/state/ups && \
    chown -R nut:nut /run/nut /var/state/ups && \
    chmod 770 /run/nut /var/state/ups

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Healthcheck - verify upsd is responding
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD upsc ${NAME}@localhost:${PORT} 2>&1 | grep -q "ups.status" || exit 1

# NUT port + webNUT dashboard port
EXPOSE 3493 6543

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
