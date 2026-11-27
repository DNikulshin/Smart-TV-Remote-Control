# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Full Russian localization: `lib/l10n/app_ru.arb` (all 79 strings, with
  proper Russian plural forms for the device count), the generated
  `app_localizations_ru.dart`, and a Russian launcher name for Android
  (`values-ru/strings.xml`). Docs in Russian: [README.ru.md](README.ru.md),
  a step-by-step [setup guide](docs/ru/setup.md) and a
  [privacy summary](docs/ru/privacy.md).
- Localized iOS app name and local-network prompt: `ios/Runner/en.lproj/`
  and `ios/Runner/ru.lproj/InfoPlist.strings` are wired into the Runner
  target as an `InfoPlist.strings` variant group (`ru` added to the
  project's known regions), so the launcher name matches the Android one
  on both platforms. `tool/check_ios_localization.py` checks that wiring
  without Xcode.
- In-app language switcher (globe icon on the picker) with the choice
  persisted in `shared_preferences`; "System default" follows the device
  again. `LocaleCubit` / `LocaleStorage`, covered by storage, cubit and
  widget tests.
- Test suite grown from 44 to 88 cases; line coverage from 28% to 65%.
  `FakeWebOsTv` drives the real LG client over a genuine WebSocket
  (plaintext and TLS), covering registration, the unsigned-manifest retry,
  a denied prompt, certificate pinning and mismatch, the client-key policy
  and the pointer input socket — paths that previously needed hardware.
  Repository tests cover discovery merging, credential cleanup across host
  and MAC aliases, and the Wake-on-LAN retry; widget tests cover the
  picker, the forget flow and the manual-IP dialog.
- Every CI run prints a coverage summary, with the least-covered files, in
  its GitHub Actions job summary. No external service or token needed;
  `tool/coverage_summary.py` produces the same report locally.
- The three new languages are selectable from the language menu like the
  others, and the menu now lists whatever ARB files the app ships instead of a
  hardcoded list, so the next language appears in it by itself.

- The device list labels every card with the brand it will connect with,
  resolved through the same `TvBrand.fromDevice` the repository uses, so an
  unknown set shows the brand a tap will actually pick.

- Swipe pad for webOS pointer navigation (LG only): dragging on the pad
  moves the on-screen cursor through the pointer input socket
  (`type:move`); a tap clicks (`type:click`). A touchpad button in the
  remote's toolbar swaps the pad in for the arrow cluster, and the button is
  hidden for Samsung sets, whose channel carries key presses only. Covered by
  service, bloc, pad gesture and screen tests.
- App shortcuts on the remote: Netflix, YouTube, Disney+ and Prime Video open
  in one tap. The id is brand-specific and resolved in the implementation —
  `ssap://system.launcher/launch` with a webOS id, or an `ed.apps.launch`
  event with a Tizen one (`lg_apps.dart`, `samsung_apps.dart`). The row is
  the last section on the remote, and the screen now scrolls instead of
  squeezing its controls when a phone is short.

- The phone's hardware volume keys control the TV while the remote is open and
  connected. Android takes the keys over with a playing media session whose
  volume is remote-controlled, so the phone's own volume neither changes nor
  shows its panel; leaving the screen or losing the connection hands the keys
  back. Covered by `test/core/services/hardware_volume_keys_test.dart` and
  `test/ui/volume_keys_test.dart`. iOS has no comparable route, so there the
  keys still change the phone's volume.

- Two more brands, both over plain HTTP on the local network.
  **Roku** (ECP: `POST /keypress/<Key>`, `/launch/<id>`, `/query/device-info`)
  needs no pairing — only *Control by mobile apps → Network access* switched
  on; **Sony BRAVIA** (JSON-RPC plus SOAP `X_SendIRCC`) needs *IP control* on
  and the pre-shared key, which the add-by-IP dialog now asks for and the app
  stores like any other credential. Sony button codes come from the set's own
  `getRemoteControllerInfo` when it answers, with Sony's documented table as
  the fallback — `Info`, `Exit`, `Rewind` and `Forward` are not in that table,
  so they are dropped rather than guessed. Both brands are found by SSDP
  (`roku:ecp`, `urn:schemas-sony-com:service:ScalarWebAPI:1`), both support
  Wake-on-LAN through the MAC the device reports, and neither has been tested
  on hardware yet. Tests run against fake devices that speak the real
  protocols over `dart:io` `HttpServer`.

### Fixed
- A Sony BRAVIA with a pre-shared key worked once and then reported the key
  as rejected: the key was stored under the host it was typed for, while the
  next connect resolved the set by its MAC (from `getSystemInformation`) and
  found nothing there, so no `X-Auth-PSK` was sent and the set answered 403.
  Every stored credential now follows the device when its identifier changes
  from the host to the MAC, which also restores LG certificate pinning after
  the first connect. `forget` clears all of them, and the key is only written
  once the set has accepted it.
- The remote screen overflowed on narrow phones: the six media buttons need
  more than a 360 dp screen has (the width of most budget Android handsets),
  and the numeric keypad's four fixed rows did not fit the height left on a
  short screen. Both now give each control an equal share and scale it down
  instead of spilling past the edge; the media buttons stay tappable at
  320 dp. Covered by `test/ui/narrow_screen_test.dart`.
- The Russian device counter rendered a literal `#` (`Найдено # устройства`):
  the ARB used the ICU `#` placeholder, which `flutter gen-l10n` keeps as
  text. The plural cases now interpolate `{count}`, and
  `test/l10n/localizations_test.dart` fails if any locale leaks `#` or
  stops showing the number.
- French, German and Portuguese translations (`lib/l10n/app_fr.arb`,
  `app_de.arb`, `app_pt.arb`), each with the device-count plural forms its
  language actually has. `test/l10n/arb_keys_test.dart` now checks that every
  locale carries exactly the template's keys and placeholders — `gen-l10n`
  falls back to English for a missing key and drops an unknown one without
  complaining, which is how a half-translated language used to be able to ship.

## [0.4.1] - 2026-09-14

### Fixed
- SSDP discovery could hang forever (and keep the Android multicast lock)
  when a TV accepted the description request but never answered; device
  descriptions are now fetched after the sweep, each with its own timeout,
  and the whole sweep has a hard ceiling.
- A changed LG certificate was unrecoverable from the app. Long-press a TV
  in the picker to forget it (pairing, pinned certificate and saved entry);
  connection failures are now shown on the picker too. Closes #10.
- One failed key press on LG (e.g. the pointer socket being slow) no longer
  drops the whole session; the main connection stays usable.
- Wake-on-LAN retry works again for LG sets that are fully off: the
  handshake timeout is now recognised as "TV unreachable".
- The saved LG client key is only sent to a TV whose certificate is already
  pinned; unpinned connections pair fresh.
- Declining the LG pairing prompt no longer triggers a second prompt; only
  a rejected manifest retries unsigned.
- Tapping a TV twice, or auto-connect plus a tap, no longer opens two
  sockets and two pairing prompts; the row shows a spinner while connecting.
- Overlapping discovery sweeps no longer release the Android multicast lock
  early; the lock is reference-counted and repeat scans are ignored while
  one runs.
- A paired TV no longer appears twice in the picker (saved entry with MAC
  plus discovered entry without); results are merged by host.

## [0.4.0] - 2026-09-13

### Changed
- **LG webOS client rewritten against the current protocol.** Connects to
  `wss://<ip>:3001` first (required by firmware since January 2023) and
  falls back to `ws://<ip>:3000` for older sets; registers with LG's signed
  sample manifest and retries unsigned if rejected; drives navigation,
  colour, digit, mute, volume and channel keys through the pointer input
  socket and transport keys through `media.controls`. Mute now toggles.
  The TV's self-signed certificate is pinned on first pairing and the saved
  client key is only ever sent over that pinned TLS connection; the
  plaintext fallback for pre-2018 sets asks the TV to pair again instead.
  Still untested on hardware (#9).
- **Discovery rebuilt on the platform service browsers.** mDNS now uses
  `bonsoir` (Bonjour on iOS, NSD on Android) instead of raw multicast
  sockets, which never worked on a real iPhone without Apple's restricted
  multicast entitlement. SSDP moved out of the Samsung service into
  `SsdpDiscoveryService`, recognises LG webOS responders, skips non-TV
  devices before fetching their description, and holds an Android
  `MulticastLock` (new method channel in `MainActivity`) so replies are
  actually delivered. AirPlay and Cast TXT records are used to identify
  Samsung and LG sets; other devices are no longer listed.
- Dart SDK floor raised to 3.8 (required by `bonsoir`); sources reformatted
  for the 3.8 formatter style.

### Added
- Per-ABI release APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`, ~15-19 MB)
  next to the universal build, produced by a tag-triggered release
  workflow that signs from repository secrets.
- CI builds iOS (no code signing) on every push.
- `PRIVACY.md` and `docs/protocols.md` (Samsung WSS v2, LG webOS, SSDP,
  Bonjour, Wake-on-LAN).

## [0.3.0] - 2026-09-13

### Added
- **LG WebOS is now wired into the app.** The repository picks the LG client
  for devices tagged `LG` by mDNS, and the manual-IP dialog has a brand
  selector so an LG set can be added by address. The LG client key is
  persisted like the Samsung token. Not yet verified on real hardware —
  testers wanted.
- **Localized UI.** Every string in the picker, dialog and remote now comes
  from the ARB files (English, Spanish, Arabic) instead of hardcoded text.
- **Screenshots** in the README, plus `tool/screenshots/` to regenerate them.
- Community files: `CODE_OF_CONDUCT.md`, `SECURITY.md`, Dependabot config.
- First signed Android APK published on the GitHub Releases page.

### Changed
- Application id is now `com.summationworks.smarttvremote` on every platform
  (was the Flutter template default `com.example.remote`).
- `analysis_options.yaml` and `pubspec.lock` are committed; CI now fails on
  test failures instead of ignoring them, and runs on Flutter 3.47.
- Discovery copy no longer says "Samsung TVs" when scanning for all brands.

### Fixed
- Source formatting, which had failed the CI format check since 0.2.0.

## [0.2.0] - 2026-05-25

Major rewrite. The app moves from a single-screen prototype to a layered
Flutter architecture with real protocol support for two TV brands.

### Added
- **State management & DI**: introduced `flutter_bloc` + `get_it` with a
  repository pattern. New blocs under `lib/blocs/`:
  - `TvConnectionBloc` — owns the active TV session
  - `DeviceDiscoveryBloc` — drives the network scan
  - `ConnectivityCubit` — exposes real network state
- **Samsung Tizen WebSocket v2** client in
  `lib/services/samsung/samsung_tv_service.dart` with `wss://` transport
  and native `pingInterval`-based heartbeat.
- **LG WebOS** client in `lib/services/lg/lg_tv_service.dart` (replaces
  the prior stub) with client-key pairing.
- **mDNS discovery** (`lib/services/mdns/mdns_discovery_service.dart`)
  running in parallel with UPnP.
- **Samsung token persistence** via `TvTokenStorage` — the on-TV
  "Allow" popup now appears only on the first connect.
- **Known-TV memory** via `KnownTvsStorage` with auto-connect to the
  last used set on launch.
- **Wake-on-LAN** fallback: refused connections trigger a magic packet
  and one retry.
- **Manual IP entry** dialog as a discovery fallback.
- **Real connectivity** via `connectivity_plus` (replaces DNS polling).
- **i18n scaffold** with ARB files in `lib/l10n/` for English, Spanish,
  and Arabic.
- **Accessibility**: haptic feedback and `Semantics` labels on every
  remote button.
- **Material 3 dark theme**.

### Changed
- Discovery is no longer Samsung-only; UPnP and mDNS run in parallel
  and feed a unified device list.
- TV control is now brand-agnostic at the repository layer; UI does
  not know whether it is talking to Samsung or LG.

### Removed
- Manual 5 s / 500 ms polling timers used for the previous heartbeat.
- DNS-poll-based "is the internet up" check.
- Hard-coded Samsung-only assumptions in the UI layer.

### Fixed
- Reconnect loops after the TV slept (now handled by WoL + retry).
- "Allow" popup re-appearing on every connect (token is now persisted).

## [0.1.0] - 2025-11-01

### Added
- Initial release.
- Samsung TV discovery via UPnP.
- Basic on-screen remote (power, volume, channel, D-pad).
- Single-screen Flutter UI.

[Unreleased]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.4.1...HEAD
[0.4.1]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/mazen-salah/Smart-TV-Remote-Control/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/mazen-salah/Smart-TV-Remote-Control/releases/tag/v0.1.0
