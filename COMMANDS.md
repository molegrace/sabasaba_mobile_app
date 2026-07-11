# Important Commands

Run these commands from the project root.

## Install dependencies

```bash
flutter pub get
```

## Run the application

```bash
flutter run
```

List available devices if Flutter cannot find the intended target:

```bash
flutter devices
```

Run on a specific device:

```bash
flutter run -d <device-id>
```

## Check the map API

```bash
curl --request GET \
  --url https://77.alphabeti.co.tz/api/map \
  --header "accept: application/json"
```

The application loads all rendered map data from this endpoint. There is no
local `data/` fallback.

## Format and validate

```bash
dart format lib test
flutter analyze
flutter test
```

## Build releases

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

Web:

```bash
flutter build web --release
```

## Clean generated output

Use this when cached build files cause unexpected problems:

```bash
flutter clean
flutter pub get
```
