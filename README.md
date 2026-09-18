# LocalDPI 0.0.6

LocalDPI is an iPadOS local Packet Tunnel VPN prototype.

It runs a local Network Extension tunnel, routes packets through `hev-socks5-tunnel`, and starts `byedpi` as a local SOCKS5 proxy.

Author: `Remaxiv`

## Downloads

- [`dist/LocalDPI-0.0.6-debug.ipa`](dist/LocalDPI-0.0.6-debug.ipa) - debug IPA built with Theos in WSL.
- [`dist/ipad-local-dpi-vpn-0.0.6-src.tar.gz`](dist/ipad-local-dpi-vpn-0.0.6-src.tar.gz) - source archive from a WSL filesystem clone so symlinks inside submodules are preserved.

## Changes in 0.0.6

- Fixed settings reset on app reopen. `Arguments`, DNS, and IPv6 now stay saved.
- Added Standard, TLS only, and Aggressive presets.
- Added Reset Arguments action.
- Added Diagnostics with DNS, IPv6, saved args, last started args, last VPN status, and last error.
- Added stronger Aggressive preset using TLS record splitting plus the UDP fake-data rule.

## Default byedpi args

```text
--pf 443 --proto tls --disorder 1 --split -5+se --auto=none --pf 443 --proto udp --ttl 64 --udp-fake 20 --fake-data ':@\0...' --auto=none
```

The fake-data payload is generated in code as `:@` plus 512 `\0` entries.

## Install note

This IPA uses `packet-tunnel-provider` entitlements. On a normal iPad, regular sideloading may not grant the required Network Extension entitlement. Use an install method that grants Network Extension entitlements on your device.
