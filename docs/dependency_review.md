# Dependency Review (Speech recognition & secure storage)

## Packages audited
- `speech_to_text`
- `flutter_secure_storage`
- `rive`

## Summary
- Updated `speech_to_text` to the latest stable major available to avoid relying on pre-release APIs.
- Reverted `flutter_secure_storage` to the stable `9.x` line that matches the current production plugin channel.
- Downgraded `rive` to the most recent stable `0.13.x` runtime while the repository remains on stable Flutter tooling.

## Follow-up
Because the execution environment blocks outbound network traffic, I could not download the official CHANGELOG files or run `flutter pub upgrade` / `flutter analyze` / `flutter test`. Run the commands below in an environment with Flutter SDK access to verify:

```sh
flutter pub upgrade
flutter analyze
flutter test
```

If any command fails, capture the console output and re-evaluate whether a pre-release build is required.
