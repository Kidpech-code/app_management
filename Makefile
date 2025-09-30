.PHONY: get format analyze test lint integ

get:
flutter pub get

format:
flutter format lib test integration_test

analyze:
flutter analyze

test:
flutter test --coverage

lint: analyze test

integ:
flutter test integration_test/app_test.dart
