# Technitium DNS Server Add-on

This add-on runs Technitium DNS Server on Home Assistant OS through the Home Assistant Supervisor.

The initial version is intentionally minimal and stable:

- DNS on port **53/UDP**
- DNS on port **53/TCP**
- Technitium web UI on port **5380/TCP** and via Home Assistant Ingress
- Persistent Technitium data in the add-on configuration directory
- No enforced DNS-over-HTTPS, DNS-over-TLS, or HTTPS setup

## Installation

1. Add the repository to Home Assistant under **Settings → Add-ons → Add-on Store → Repositories**.
2. Open the **Technitium DNS Server** add-on page.
3. Select **Install**.
4. Wait for the image to build and install.

## Start

1. Open the add-on page.
2. Start the add-on.
3. Check the **Log** tab for startup messages.
4. Enable **Start on boot** if it is not already enabled.

## Web UI

Prefer the Home Assistant add-on page button:

1. Open **Settings → Add-ons → Technitium DNS Server**.
2. Click **Open Web UI**.
3. Technitium should open inside Home Assistant via Ingress, similar to add-ons such as AdGuard Home.

The direct LAN URL remains available as a fallback:

```text
http://HOME_ASSISTANT_IP:5380
```

Replace `HOME_ASSISTANT_IP` with the IP address of your Home Assistant OS host.

Technitium may initialize its own default administrator account on first start. Change default credentials immediately in the Technitium web UI if Technitium prompts or auto-logs in with defaults.

## DNS test

From another machine on the same network, test DNS resolution with either `dig`:

```sh
dig @HOME_ASSISTANT_IP example.com
```

or `nslookup`:

```sh
nslookup example.com HOME_ASSISTANT_IP
```

If the test fails, first check whether the add-on is running and whether another service already occupies port 53.

## Logs

Logs are written to stdout and stderr, so they appear in the Home Assistant add-on log view.

To inspect logs:

1. Open **Settings → Add-ons**.
2. Select **Technitium DNS Server**.
3. Open the **Log** tab.

## Persistent data and backups

Technitium is started with this data directory inside the add-on container:

```text
/config/technitium
```

The add-on maps `/config` to the Supervisor-managed `addon_config` directory. On the Home Assistant host this is the add-on-specific folder under:

```text
/addon_configs/{REPO}_technitium_dns
```

This is preferred over storing application data in Home Assistant Core's own configuration directory because it keeps add-on state isolated and aligned with current Home Assistant add-on conventions.

Use Home Assistant backups before major changes. A full backup should include the Supervisor-managed add-on configuration directory and the add-on settings. For important DNS deployments, export Technitium configuration from the web UI before upgrades or large configuration changes.

## Updates

This minimal add-on builds on the official `technitium/dns-server:latest` container image so the Technitium application and required .NET runtime stay aligned. To update Technitium, update/rebuild the add-on image through Home Assistant after a new add-on release is published.

Before updating:

1. Create a Home Assistant backup.
2. Optionally export Technitium settings from the web UI.
3. Review the add-on release notes and Technitium release notes.

## Known limitations

- This add-on uses `host_network: true` so DNS clients can reach port 53 directly on the Home Assistant host IP. If another service already uses port 53, the add-on will not start correctly.
- The **Open Web UI** button uses Home Assistant Ingress on internal port 5380. If direct access to `http://HOME_ASSISTANT_IP:5380` fails, use the Ingress button first and then check the add-on logs.
- Home Assistant OS becomes part of the DNS path. If Home Assistant OS is offline, clients that rely only on this DNS server may lose DNS resolution.
- Only `amd64`, `aarch64`, and `armv7` are declared. The Docker base image and .NET runtime must be available for the target architecture during build.
- DoH, DoT, DoQ, HTTPS for the web UI, DHCP service, and certificate automation are not configured by this add-on.
- No secrets are hardcoded by the add-on. Configure credentials in Technitium itself after first start.

## Future extensions

Technitium supports encrypted DNS modes such as DNS-over-HTTPS and DNS-over-TLS. Those can be added later together with a clear certificate and port strategy. They are intentionally not enabled in this first minimal Home Assistant add-on version.
