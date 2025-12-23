# syntax=docker/dockerfile:1
# NUT UPS Tools with SNMP support
# Based on instantlinux/nut-upsd pattern

FROM alpine:3.23

LABEL org.opencontainers.image.title="nut-snmp" \
      org.opencontainers.image.description="Network UPS Tools with SNMP driver" \
      org.opencontainers.image.source="https://github.com/LukeEvansTech/nut-snmp"

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
    USER=nut

# Install NUT and SNMP dependencies
RUN apk add --no-cache \
      nut \
      net-snmp \
      net-snmp-libs \
      libcrypto3 \
      libssl3 && \
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

# NUT port
EXPOSE 3493

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
