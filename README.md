# LocalDPI 0.0.1

LocalDPI is an iPadOS local Packet Tunnel VPN prototype based on the Rumble architecture.

It runs a local Network Extension tunnel, routes packets through `hev-socks5-tunnel`, and starts `byedpi` as a local SOCKS5 proxy.

## Downloads

- [`dist/LocalDPI-0.0.1-debug.ipa`](dist/LocalDPI-0.0.1-debug.ipa) - debug IPA built with Theos in WSL.
- [`dist/ipad-local-dpi-vpn-wsl-src.tar.gz`](dist/ipad-local-dpi-vpn-wsl-src.tar.gz) - source archive from a WSL filesystem clone so symlinks inside submodules are preserved.

## Install note

This IPA uses `packet-tunnel-provider` entitlements. On a normal iPad, regular sideloading may not grant the required Network Extension entitlement. If Rumble worked for you through TrollStore or a similar install method, test this IPA the same way.

## Default byedpi args

```text
--pf 443 --proto tls --disorder 1 --split -5+se --auto=none --pf 80 --proto http --auto=none
```

## Build

```sh
export THEOS=~/theos
make clean package PACKAGE_FORMAT=ipa
```

See [`README-LOCALDPI-RU.md`](README-LOCALDPI-RU.md) for Russian setup notes.
