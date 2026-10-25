# Digital Pharmacy

Flutter consumer application for medication, company, agent and pharmacy lookup,
with Arabic/English UI, local favorites/preferences and installation ad removal.
The administrator website is separate. Consumer browsing requires no admin login.

## Local Android workflow

Use the existing Flutter SDK and locked dependencies. The audited Mac uses
Flutter 3.47.1 / Dart 3.13.1, Android SDK 36 and Android Studio's bundled JBR.
`pubspec.yaml` currently declares version `1.0.0+11`.

Before a build/test, coordinate the single heavy execution slot with the other
active project chats and check running processes. Preserve healthy jobs, existing
APKs, signing files, app storage and emulator data. Do not use `flutter clean`,
uninstall, storage clearing or emulator wiping as a repair shortcut.

From this checkout, run gates serially:

```sh
flutter analyze --no-pub --no-fatal-infos
flutter test --no-pub --concurrency=1
flutter build apk --debug --no-pub --target=lib/main.dart --target-platform=android-arm64
```

The debug APK is `build/app/outputs/flutter-apk/app-debug.apk`. Debug/profile use
Google's demo advertising configuration. Release uses the project's existing
publisher configuration and `android/key.properties` signing setup; preserve
those files and never publish their contents. Do not run publisher ads in
automated acceptance tests or click live ads.

For an in-place install, first verify the device belongs to this project and
compare package ID, signing certificate and version with its installed APK.
Only then use `adb -s <owned-device> install -r <candidate.apk>`. A debug build
cannot replace a differently signed release. Never uninstall to bypass this.
Distribution also requires an approved destination and an appropriate release
version code; the unchanged code 11 is not a distribution decision.

## API and activation

The configured API origin is `http://144.91.111.63:5002`, overridable with
`DIGITAL_PHARMACY_API_BASE_URL`. Paths include `/api` exactly once. The current
Swagger document has 26 paths / 30 operations; its global Bearer declaration
does not accurately describe the observed public catalog boundary. Normal
production transports are anonymous and do not inherit a legacy admin session.
The owner-provided country binding remains Jordan=0, Palestine=1. Do not relabel
countries based on catalog contents or depend on protected country lookup.

Activation posts exactly `isNewUser`, `activationCode` and `deviceId` to
`/api/users/verify-device`. The owner defines `deviceId` as the current FCM
registration token, and the first attempt as `isNewUser: true`. No country,
username or password belongs in this request. The app refuses a missing token.

HTTP 200 alone is not activation. Observed invalid codes returned
`{status: 200, data: false}`. The default adapter leaves even `data: true`
unconfirmed until the backend owner provides an authoritative positive contract and approved HTTPS lifecycle
evidence. Typed synthetic adapters exercise persistence only in tests.
Previously saved activation survives ordinary restart, update,
offline use and FCM rotation. The code and FCM token are not stored in activation
preferences. No activation status or token registration route is invented.

The client blocks activation and legacy admin credentials/bearer sessions over
HTTP before dispatch; public anonymous catalog reads remain available. Do not
send real activation codes, FCM tokens or credentials over HTTP. A backend
source commit/deployment mapping and HTTPS fixture environment are required to settle success, expiry, reuse and wrong-device semantics.

## Latest continuation

The [continuation report](docs/integration-audit-20261018/continuation/REPORT.md)
supersedes activation-positive handling in the earlier audit. The preserved
1.0.0+11 APKs predate these transport/contract guards and have not been rebuilt.

## Verification record

The current audit is under `docs/integration-audit-20261018/`. Its endpoint matrix,
source ownership baseline, backend-access findings, exact check receipts and
Android acceptance evidence distinguish mocked, loopback, live read-only and
native results. Historical reports are retained. The
[native-ad follow-up](docs/integration-audit-20261018/native-ad-error0-followup/README.md)
rendered real native test ads from unchanged binaries on an isolated API33
Google Play image, including a green SDK validator result in the final debug
APK. Store/click-action handling is the strongest hypothesis for the earlier
Google APIs error0; image differences prevent a sole-cause or universal-fix
claim. Backend activation and country/scientific-detail limitations remain.
