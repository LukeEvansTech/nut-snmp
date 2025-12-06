# nut-snmp

Network UPS Tools (NUT) container with SNMP driver support and web dashboard.

Designed for network-connected UPS devices like APC with Network Card 2.

## Features

- **SNMP driver** (`snmp-ups`) for network-connected UPS
- **NUT server** (`upsd`) on port 3493
- **webNUT dashboard** on port 6543
- Multi-arch support (amd64, arm64)

## Usage

```bash
docker run -d \
  --name nut-snmp \
  -e SERVER=your-ups-hostname.local \
  -e NAME=apc \
  -e SNMP_COMMUNITY=public \
  -p 3493:3493 \
  -p 6543:6543 \
  ghcr.io/lukeevanstach/nut-snmp:latest
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NAME` | `apc` | UPS name identifier |
| `SERVER` | `localhost` | UPS hostname/IP (SNMP target) |
| `DRIVER` | `snmp-ups` | NUT driver |
| `SNMP_COMMUNITY` | `public` | SNMP community string |
| `SNMP_VERSION` | `v2c` | SNMP version |
| `POLLFREQ` | `15` | Poll frequency in seconds |
| `MAXAGE` | `25` | Max age before stale data |
| `PORT` | `3493` | NUT server port |
| `API_USER` | `upsmon` | NUT API username |
| `SECRET` | `secret` | NUT API password |
| `WEBNUT_PORT` | `6543` | webNUT dashboard port |

## Ports

- **3493**: NUT protocol (upsd)
- **6543**: webNUT web dashboard

## Query UPS Status

```bash
# From inside container
docker exec nut-snmp upsc apc@localhost:3493

# From external NUT client
upsc apc@your-docker-host:3493
```

## Kubernetes

Example HelmRelease for use with bjw-s app-template:

```yaml
controllers:
  nut-snmp:
    containers:
      app:
        image:
          repository: ghcr.io/lukeevanstach/nut-snmp
          tag: latest
        env:
          NAME: apc
          SERVER: your-ups-hostname.local
          SNMP_COMMUNITY: public
service:
  app:
    ports:
      nut:
        port: 3493
      web:
        port: 6543
```
