# Smart TV Remote — форк с русской поддержкой

> Форк [mazen-salah/Smart-TV-Remote-Control](https://github.com/mazen-salah/Smart-TV-Remote-Control) (Flutter,
> MIT). Апстрим главнее по коду приложения: наши изменения — локализация и документация,
> чтобы их можно было отправить PR'ом.

## Что добавлено поверх апстрима

- `lib/l10n/app_ru.arb` — полный русский перевод (79 строк, плюрализация счётчика устройств).
- `lib/l10n/app_localizations*.dart` — сгенерированы `flutter gen-l10n`, коммитятся.
- Марки (issues #16, #17): Roku — `lib/services/roku/` (ECP по HTTP, порт 8060, без сопряжения);
  Sony — `lib/services/sony/` (JSON-RPC `/sony/system` + SOAP `/sony/IRCC`, ключ PSK).
  Коды кнопок Sony берутся у самого телевизора (`getRemoteControllerInfo`), запасной
  вариант — только документированные Sony коды; `Info`, `Exit`, перемотка не угадываются.
  Ключ PSK идёт из диалога ручного добавления через `TVDevice.additionalInfo['sonyPsk']`
  и сохраняется в `TvTokenStorage` как `psk:sony:<id>`. Учётные данные живут под
  префиксами (`''` — токен сопряжения, `cert:` — закреплённый сертификат LG, `psk:` — ключ
  Sony) и обязаны переезжать вместе: идентификатор устройства меняется с IP на MAC, как
  только телевизор его назвал, и `TvRepository.carryCredentials` переносит все три
  префикса. Без этого Sony работал ровно один запуск: второй искал `psk:sony:<mac>`,
  не находил ключ, не отправлял `X-Auth-PSK` и получал 403 (найдено вычиткой, `9a6531f`).
  Ключ пишется только после того, как телевизор его принял, а `forget` чистит все три
  префикса.
- Громкость (issue #13, Android): `MainActivity.kt` держит играющую `MediaSession` с
  `VolumeProvider`, пока открыт экран пульта и есть связь; нажатия уходят в
  `HardwareVolumeKeys` (`lib/core/services/hardware_volume_keys.dart`) и превращаются в
  `KEY_VOLUP`/`KEY_VOLDOWN`. Три грабли, найденные ревью: без `session.setCallback(...)`
  AOSP `MediaSession.postToCallback` молча выбрасывает изменение громкости и
  `onAdjustVolume` не срабатывает; `BlocListener` не вызывает слушателя для начального
  состояния, поэтому экран пульта синхронизирует захват с тем состоянием, на котором
  открылся (в обычном сценарии пикер пушит пульт уже подключённым); в фоне клавиши
  отпускаются через `didChangeAppLifecycleState`. Проверка Kotlin — только сборкой APK.
- Приложения (issue #14): `TvApp` в `lib/core/models/tv_app.dart`, id по марке —
  `lib/services/lg/lg_apps.dart` (`ssap://system.launcher/launch`), `lib/services/samsung/samsung_apps.dart`
  (событие `ed.apps.launch`). UI — `app_shortcuts.dart`, последний ряд на экране пульта.
  Экран пульта ездит (`SingleChildScrollView`), средний блок — фиксированная высота 210:
  крестовина/клавиатура/тачпад подменяют друг друга, остальное не двигается.
- Тачпад для курсора на LG webOS (issue #15): `lib/ui/widgets/remote_controls/components/touchpad.dart`,
  протокол — `type:move` / `type:click` в сокете указателя (`lg_tv_service.dart`), слой —
  `TVInterface.supportsPointer/pointerMove/pointerClick` → `TvRepository` → `TvConnectionBloc`
  (`TvPointerMoved`, `TvPointerClicked`). Кнопка тачпада показывается только для LG
  (`TvBrand.hasPointer`), на Samsung сокета указателя нет.
- Языки (issue #12): fr/de/pt в `lib/l10n/app_{fr,de,pt}.arb`; меню языка берёт список из
  `AppLocalizations.supportedLocales`, а не из константы, поэтому новый ARB попадает в меню сам.
  Строки, добавленные форковыми фичами (`apps`, `touchpad*`, `brandRoku/Sony`, `preSharedKey*`,
  `language*`), в fr/de/pt дописаны вручную — в PR #51 их нет, там база без этих фич.
- Переключатель языка в шапке экрана выбора устройства: `LocaleCubit` + `LocaleStorage`
  (`shared_preferences`), «Как в системе» сбрасывает выбор. Тесты:
  `test/blocs/locale/`, `test/ui/language_menu_button_test.dart`.
- Название приложения на Android: `res/values-ru/strings.xml` (`@string/app_name` в манифесте).
- Название и текст разрешения на локальную сеть на iOS: `ios/Runner/{en,ru}.lproj/InfoPlist.strings`,
  подключены вариант-группой в `project.pbxproj`; связность проверяет `tool/check_ios_localization.py`.
- Документация: `README.ru.md`, `docs/ru/setup.md` (гайд по настройке), `docs/ru/privacy.md`.

## Проверка на железе

`docs/testing.md` — чек-лист для тестировщиков: что включить на телевизоре, какие группы
кнопок поддержаны, какие алиасы намеренные (Roku: `MENU` → `Info`, `PAUSE` → `Play`), что
не поддержано по замыслу и какие 2–3 вопроса может решить только железо (скорость курсора
webOS, отвечает ли Bravia в `getRemoteControllerInfo`, живые ли id приложений Tizen).
Ветка `docs/tester-checklist`, PR #52.

## Открытые PR и их совместимость

Восемь PR в апстрим (#44–#51) правятся независимо, но **вместе** требуют ручной
сборки: #47 добавил в `TVInterface` метод `launchApp(TvApp)`, #49 — `supportsPointer`,
`pointerMove`, `pointerClick`, поэтому Roku/Sony из #48 без этих методов не
компилируются; #47 заменил середину экрана на `SizedBox(height: 210)`, а #49
оборачивает тачпад в `Expanded` — `Expanded` внутри `SizedBox` падает с
`Incorrect use of ParentDataWidget`; #51 добавляет паритетный тест ARB, которому не
хватает 16 ключей в de/fr/pt, пока не смержены #44/#47/#48/#49. Всё это уже сведено
в `main` форка, оттуда и брать готовые решения.

## Описания в репозитории

Описания — на двух языках, английском и русском: так же, как документация
(`README.md` + `README.ru.md`). Это касается GitHub-описания репозитория форка,
`description` в `pubspec.yaml`, `description` в `web/manifest.json` и
`<meta name="description">` в `web/index.html`.

Правила формата: GitHub принимает одну строку без переводов строки и не длиннее 350
символов, файлы в репозитории длиной не ограничены, но держим их короткими. В каждом
месте сначала английский текст, потом русский — так порядок одинаков везде.

## Команды

Flutter локально: `export PATH="$HOME/sdk/flutter/bin:$PATH"` (3.47.9 stable).

| Что | Команда |
|---|---|
| Зависимости | `flutter pub get` |
| Строки из ARB | `flutter gen-l10n` |
| Формат | `dart format .` (CI проверяет `--set-exit-if-changed`) |
| Анализ | `flutter analyze` (very_good_analysis, infos тоже валят CI) |
| Тесты | `flutter test --coverage`, отчёт покрытия — `python3 tool/coverage_summary.py` |
| Проверка UI без телефона | `flutter build web` → `python3 -m http.server` в `build/web` |
| Проверка Android-сборки | `flutter build apk --debug` (см. окружение ниже) |

Порядок после правок: `flutter gen-l10n` → `dart format .` → `flutter analyze` → `flutter test`.

Android-сборка: в системе нет `java` и Android SDK из `apt` (sudo в контейнере запрещён),
поэтому JDK 17 (Temurin) и SDK установлены в `~/sdk`. Перед `flutter build apk` нужны переменные:

```bash
export JAVA_HOME="$HOME/sdk/jdk/jdk-17.0.21.1+2"
export ANDROID_HOME="$HOME/sdk/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

В SDK стоят `platform-tools`, `platforms;android-36`, `build-tools;36.0.0`, NDK r28c скачался
сам при первой сборке. Подпись — debug-ключ: `android/key.properties` здесь нет и не должно быть.
Проверить, что ресурсы попали в APK, можно без телефона:
`"$ANDROID_HOME/build-tools/36.0.0/aapt2" dump badging build/app/outputs/flutter-apk/app-debug.apk`.

`coverage/lcov.info` коммитится в репозиторий: после `flutter test --coverage` он меняется,
и это нормально включать в коммит с тестами (так делал апстрим).

## Правила локализации

- Ключи добавляются сначала в `app_en.arb` (шаблон), потом во все остальные локали;
  набор ключей должен совпадать (проверяется скриптом ниже).
- Плейсхолдеры (`{count}`, `{host}`) в переводе не переименовывать.
- Надписи на кнопках пульта (`MENU`, `MORE`, `SMART`, `INPUT`, `EXIT`, `TOOLS`, `GUIDE`)
  не переводятся: это лица кнопок штатного пульта.
- `lib/l10n/**` исключён из анализа линтером — руками не правим.

```bash
python3 - <<'PY'
import json
en = {k for k in json.load(open('lib/l10n/app_en.arb')) if not k.startswith('@')}
for loc in ('ru', 'es', 'ar'):
    d = {k for k in json.load(open(f'lib/l10n/app_{loc}.arb')) if not k.startswith('@')}
    print(loc, 'missing:', sorted(en - d), 'extra:', sorted(d - en))
PY
```

## Git

- `origin` — `DNikulshin/Smart-TV-Remote-Control` (форк), `upstream` — апстрим (`mazen-salah`).
- PR в апстрим идёт из отдельной ветки, а не из `main`: ветка — это нужный апстрим-база плюс
  коммиты, без `AGENTS.md` (правила форка апстриму не нужны). После правок в ветке изменения
  переносятся в `main` через `git cherry-pick`, чтобы файлы форка не утекли в PR.
- Открытые PR:
  - #44 `i18n/ru` — русская локализация, переключатель языка, iOS-название, RU-документация.
    База — `upstream/main`, без `AGENTS.md`.
  - #45 `fix/narrow-remote-overflow` — переполнение экрана пульта на 360 dp; от i18n не зависит.
  - #46 `feat/hardware-volume-keys` — качелька громкости телефона управляет ТВ (Android,
    `MediaSession` + `VolumeProvider` в `MainActivity.kt`, канал `.../volume_keys`);
    от i18n не зависит. iOS не сделан — в issue #13 остаётся открытым.
  - #50 `feat/brand-on-device-item` — марка на карточке устройства (issue #11); от i18n не зависит.
  - #51 `feat/translations-fr-de-pt` — французский, немецкий, португальский (issue #12) и тест
    `test/l10n/arb_keys_test.dart` на совпадение ключей и плейсхолдеров с шаблоном;
    от `app_ru.arb` не зависит.
  - #48 `feat/sony-roku` — Roku (ECP) и Sony BRAVIA (JSON-RPC + IRCC) (issues #17 и #16).
    База — `i18n/ru`, потому что добавлены строки марок и поле ключа PSK. В main они
    дополнительно реализуют `launchApp`/`supportsPointer`: у Roku есть id каналов
    (12/837/291097/13), у Sony — только заглушка до появления URI приложений.
  - #49 `feat/webos-touchpad` — тачпад для webOS (issue #15).
  - #47 `feat/app-launcher` — приложения (issue #14). Обе ветки лежат поверх `i18n/ru`,
    потому что добавляют ключи в `app_ru.arb`, а этот файл появляется только в #44,
    и обе несут его коммиты, пока он не смержен. (#47 сначала висел пустым шаблоном
    с заголовком «Feat/app launcher» — заполнен вручную.)
  - `main` форка = #44 + тачпад + приложения + фикс вёрстки (#45) + громкость (#46) + Roku/Sony (#48)
    + марка на карточке (#50) + fr/de/pt (#51); в upstream уходят только сами фичи.
    Состояние main проверено целиком: 194 теста, покрытие 70.5%, `flutter build apk --debug`
    проходит.
- Правило для новых фич: если изменения не трогают файлы из #44, ветку можно резать прямо от
  `upstream/main` и открывать PR сразу (так сделаны #45, #46, #48).
- Порядок слияния важен: `app_ru.arb` появляется только в #44, поэтому #47 и #49 имеют смысл
  после него. Компиляция не ломается от лишних ключей в `app_ru.arb`, но ломается от
  отсутствующих: ключ, добавленный в `app_en.arb`, обязан быть и в `app_ru.arb`.
- Workflow CI в апстриме на PR из форка висит в `action_required`, пока мейнтейнер не
  разрешит запуск. Поэтому перед PR полезно прогнать локально то же, что делает CI:
  формат, анализ, тесты с покрытием и `flutter build apk --debug`.

## iOS: локализация названия

`Info.plist` правится только в одном языке, поэтому название и текст разрешения на локальную сеть
переведены через `ios/Runner/{en,ru}.lproj/InfoPlist.strings`; в проекте они подключены
вариант-группой `InfoPlist.strings` (`PBXVariantGroup`), в `knownRegions` добавлен `ru`.
Xcode на этой машине нет, CI собирает только Android, поэтому связность проверяется скриптом:

```bash
python3 tool/check_ios_localization.py          # ожидает en и ru
```

Он парсит `project.pbxproj` как OpenStep-plist, проверяет, что все ссылки разрешаются,
файлы `.lproj` существуют и содержат `CFBundleDisplayName` и `NSLocalNetworkUsageDescription`,
а build-файл лежит в фазе Resources таргета Runner. Новый язык — `--languages en,ru,de`
и такая же ветка в `values-<lang>/strings.xml` для Android.
