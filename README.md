# LocalDPI 0.0.2

LocalDPI is an iPadOS local Packet Tunnel VPN prototype based on the Rumble architecture.

It runs a local Network Extension tunnel, routes packets through `hev-socks5-tunnel`, and starts `byedpi` as a local SOCKS5 proxy.

Author: `Remaxiv`

## Downloads

- [`dist/LocalDPI-0.0.2-debug.ipa`](dist/LocalDPI-0.0.2-debug.ipa) - debug IPA built with Theos in WSL.
- [`dist/ipad-local-dpi-vpn-0.0.2-src.tar.gz`](dist/ipad-local-dpi-vpn-0.0.2-src.tar.gz) - source archive from a WSL filesystem clone so symlinks inside submodules are preserved.

## Changes in 0.0.2

- Default `byedpi` arguments now include the TLS rule and UDP fake-data rule.
- Settings screen shows `Author: Remaxiv`.
- VPN profile creation now searches for `com.localdpi.tunnel.ext` instead of taking the last saved tunnel profile.
- Save/start VPN errors are shown as alerts instead of only going to logs.

## Default byedpi args

```text
--pf 443 --proto tls --disorder 1 --split -5+se --auto=none --pf 443 --proto udp --ttl 64 --udp-fake 20 --fake-data ':@\0...' --auto=none
```

The fake-data payload is generated in code as `:@` plus 512 `\0` entries.

## Install note

This IPA uses `packet-tunnel-provider` entitlements. On a normal iPad, regular sideloading may not grant the required Network Extension entitlement. If Rumble worked for you through TrollStore or a similar install method, test this IPA the same way.

