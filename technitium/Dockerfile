FROM docker.io/technitium/dns-server:latest

ARG BUILD_VERSION=1.0.3
ARG BUILD_ARCH=amd64

LABEL \
  io.hass.version="${BUILD_VERSION}" \
  io.hass.type="addon" \
  io.hass.arch="${BUILD_ARCH}" \
  org.opencontainers.image.title="Technitium DNS Server Home Assistant Add-on" \
  org.opencontainers.image.description="Technitium DNS Server packaged as a Home Assistant OS add-on" \
  org.opencontainers.image.source="https://github.com/Dion/ha-technitium"

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

EXPOSE 53/tcp 53/udp 5380/tcp
ENTRYPOINT ["/run.sh"]
