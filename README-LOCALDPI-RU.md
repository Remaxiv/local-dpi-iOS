# LocalDPI for iPadOS

Это локальный VPN для iPadOS по схеме Rumble:

1. Основное приложение создает `NETunnelProviderManager`.
2. Packet Tunnel extension создает локальный TUN через `NEPacketTunnelProvider`.
3. `hev-socks5-tunnel` забирает IP-пакеты из TUN и отправляет их в SOCKS5.
4. `byedpi` запускается как локальный SOCKS5-прокси на `::1:8080`.
5. Аргументы `byedpi` задаются в настройках приложения.

Это не удаленный VPN-сервер. Весь трафик остается на устройстве, но проходит через локальную обработку.

## Что уже изменено

- Display name: `LocalDPI`
- Bundle ID приложения: `com.localdpi.tunnel`
- Bundle ID extension: `com.localdpi.tunnel.ext`
- Provider ID в коде: `com.localdpi.tunnel.ext`
- Дефолтные аргументы сделаны короче и понятнее:

```text
--pf 443 --proto tls --disorder 1 --split -5+se --auto=none --pf 80 --proto http --auto=none
```

## Важное ограничение

Для обычного iPad без jailbreak/TrollStore нужен Apple Developer account и право на Network Extension:

```xml
<key>com.apple.developer.networking.networkextension</key>
<array>
    <string>packet-tunnel-provider</string>
</array>
```

Без этого iPad не даст приложению создать Packet Tunnel VPN.

Если ставить через TrollStore или похожую среду, entitlements могут работать иначе. Это зависит от версии iPadOS и способа установки.

## Сборка через Theos на Mac/Linux

Установить Theos:

```sh
git clone --recursive https://github.com/theos/theos.git ~/theos
export THEOS=~/theos
```

Собрать:

```sh
cd ipad-local-dpi-vpn
make package PACKAGE_FORMAT=ipa
```

Итоговый IPA обычно появится в папке `packages`.

## Настройки внутри приложения

- `Use IPv6`: включать IPv6 route через локальный VPN.
- `DNS Server`: DNS сервер, например `1.1.1.1`, `8.8.8.8` или свой.
- `Arguments`: аргументы для `byedpi`. Приложение само добавляет начало:

```text
ciadpi -i ::1 -p 8080 -x 2
```

Поэтому в поле `Arguments` нужно вводить только правила `--pf ...`.

## Как проверить

1. Установить IPA.
2. Открыть LocalDPI.
3. Нажать кнопку питания.
4. iPadOS попросит разрешить VPN-конфигурацию.
5. После подключения в статусбаре должен появиться VPN.
6. Если сайты не открываются, сначала попробовать DNS `8.8.8.8`, затем отключить IPv6.

## Где находится основная логика

- `RMRootViewController.m`: создание VPN-профиля и запуск tunnel.
- `RMSettingsViewController.m`: настройки `IPv6`, `DNS Server`, `Arguments`.
- `RumbleExt/PacketTunnelProvider.m`: TUN, DNS, routes, запуск `byedpi` и `hev-socks5-tunnel`.
- `RumbleExt/Makefile`: сборка `byedpi`, `hev-socks5-tunnel`, `lwip`, `yaml`.

