FROM mcr.microsoft.com/dotnet/aspnet:9.0-bookworm-slim

ARG BUILD_VERSION=1.0.0
ARG BUILD_ARCH=amd64
ARG TECHNITIUM_DOWNLOAD_URL=https://download.technitium.com/dns/DnsServerPortable.tar.gz

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="app" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.title="Technitium DNS Server Home Assistant Add-on" \
  org.opencontainers.image.description="Technitium DNS Server packaged as a Home Assistant OS add-on" \
  org.opencontainers.image.source="https://github.com/Dion/ha-technitium"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
  && mkdir -p /opt/technitium/dns \
  && curl -fsSL "${TECHNITIUM_DOWNLOAD_URL}" | tar -xz -C /opt/technitium/dns \
  && apt-get purge -y --auto-remove curl \
  && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

EXPOSE 53/tcp 53/udp 5380/tcp
CMD ["/run.sh"]
