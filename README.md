# App Management Starter

Production-ready Flutter starter using Riverpod 3, go_router 14, Hive, and Dio.

## Stack

- Flutter (Material 3)
- Riverpod 3 (`AsyncNotifier`, generated providers)
- go_router 14 with typed routes & deep-link support
- Dio with auth/retry/logging interceptors
- Hive + secure storage for offline cache & secrets
- Freezed/JSON Serializable for immutable models
- Strict `very_good_analysis` lints

## Project structure

```
lib/
  app/                # application shell, router, DI, theme
  core/               # cross-cutting concerns (config, network, storage)
  features/
    auth/             # authentication feature (clean architecture layers)
    example_todos/    # sample feature showing offline-first CRUD
    settings/         # configuration & profile screen
```

## Environment configuration

Run with flavor-specific config using `--dart-define` values:

| Define | Description | Default |
| --- | --- | --- |
| `API_BASE_URL` | Backend base URL | `https://dev.api.example.com` |
| `BUILD_FLAVOR` | `dev`, `stg`, `prod` | `dev` |
| `SENTRY_DSN` | Monitoring DSN | Placeholder |
| `LOG_LEVEL` | `none`, `error`, `warning`, `info`, `debug` | `debug` in debug builds |

Example launch commands:

```bash
# Development
flutter run \
  --dart-define=API_BASE_URL=https://dev.api.example.com \
  --dart-define=BUILD_FLAVOR=dev \
  --dart-define=SENTRY_DSN=https://public@sentry.invalid/1 \
  --dart-define=LOG_LEVEL=debug

# Staging
flutter run \
  --dart-define=API_BASE_URL=https://stg.api.example.com \
  --dart-define=BUILD_FLAVOR=stg \
  --dart-define=SENTRY_DSN=https://public@sentry.invalid/1 \
  --dart-define=LOG_LEVEL=info

# Production
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=BUILD_FLAVOR=prod \
  --dart-define=SENTRY_DSN=https://public@sentry.invalid/1 \
  --dart-define=LOG_LEVEL=warning
```

## Tooling

Common commands (also available via `Makefile`):

```bash
make get        # flutter pub get
make analyze    # flutter analyze
make test       # flutter test --coverage
make integ      # flutter test integration_test/app_test.dart
```

## Deep link testing

- Android: `adb shell am start -a android.intent.action.VIEW -d "myapp://todos/42"`
- iOS (Simulator): `xcrun simctl openurl booted myapp://todos/42`
- Web: navigate to `/#/todos/42`

Ensure platform-specific manifests/intent filters are updated when wiring real URLs.

## Offline storage

Hive boxes opened during bootstrap:

- `app_prefs` – general preferences
- `secure_tokens` – encrypted (AES) token store, key managed via `flutter_secure_storage`
- `todos_cache` – cached todo responses (with TTL baked into adapter)

TypeAdapters registered in `bootstrap.dart`.

## Testing strategy

- Unit tests cover Riverpod notifiers, router guard logic, and error mapping.
- Widget/integration test simulates login → todos list → detail → deep link navigation.
- CI pipeline (`.github/workflows/ci.yml`) runs `flutter pub get`, code generation, analyze, and tests.

## Notes

- All dependencies resolved via Riverpod providers (`lib/app/di/providers.dart`).
- Auth flows support token refresh, optimistic updates, and guard-based redirects.
- Todos feature demonstrates offline-first repository that merges Hive cache and remote API.
- Logging is gated by build flavor and `LOG_LEVEL`.
