# LocalDPI 0.0.4

LocalDPI is an iPadOS local Packet Tunnel VPN prototype.

It runs a local Network Extension tunnel, routes packets through `hev-socks5-tunnel`, and starts `byedpi` as a local SOCKS5 proxy.

Author: `Remaxiv`

## Downloads

- [`dist/LocalDPI-0.0.4-debug.ipa`](dist/LocalDPI-0.0.4-debug.ipa) - debug IPA built with Theos in WSL.
- [`dist/ipad-local-dpi-vpn-0.0.4-src.tar.gz`](dist/ipad-local-dpi-vpn-0.0.4-src.tar.gz) - source archive from a WSL filesystem clone so symlinks inside submodules are preserved.

## Changes in 0.0.4

- Settings includes a clickable GitHub row for `github.com/Remaxiv/local-dpi-0.0.1`.
- Settings includes a short byedpi arguments reference from the bundled byedpi build.
- Default `Arguments` remains the requested TLS + UDP fake-data rule.

## Default byedpi args

```text
--pf 443 --proto tls --disorder 1 --split -5+se --auto=none --pf 443 --proto udp --ttl 64 --udp-fake 20 --fake-data ':@\0...' --auto=none
```

The fake-data payload is generated in code as `:@` plus 512 `\0` entries.

## Install note

This IPA uses `packet-tunnel-provider` entitlements. On a normal iPad, regular sideloading may not grant the required Network Extension entitlement. Use an install method that grants Network Extension entitlements on your device.
