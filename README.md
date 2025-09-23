# Flutter

A modern Flutter-based mobile application utilizing the latest mobile development technologies and tools for building responsive cross-platform applications.

## � Secure configuration & secret handling

This project keeps provider API keys (OpenAI, Gemini, Anthropic, Perplexity, etc.) off the client. Only short‑lived, narrowly scoped tokens reach the app. Runtime configuration resolves in this order:

1. `--dart-define` values passed at build or launch time.
2. `.env` file (local development only, ignored by Git).
3. Fallback empty string (feature gracefully disabled until configured).

Environment access is centralized in `lib/core/config/environment.dart`.

### Local development

```bash
cp .env.example .env
# edit .env with non-sensitive values
flutter run
```

Leave provider session tokens blank; they should be fetched at runtime from a Supabase Edge Function using a valid Supabase session.

### Production / CI builds

Inject configuration without committing secrets:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_FUNCTIONS_URL=https://your-project.functions.supabase.co
```

Session + provider tokens are exchanged dynamically; do not embed long‑lived keys.

### Token exchange flow

1. App holds (or authenticates to obtain) a Supabase session token.
2. Calls a Supabase Edge Function (e.g. `issue-openai-token`).
3. Edge Function validates session; mints short‑lived provider token.
4. `AuthenticatedHttpClient` includes that token in outbound provider requests.

Edge functions never return raw provider secret keys—only ephemeral tokens.

### OpenAI integration scaffold

`OpenAiService` now implements a generic `AIProvider` strategy with:

- Ephemeral token acquisition (Supabase Edge Function)
- Exponential backoff + jitter retry policy
- Structured error mapping (unauthorized, rate limit, network, parsing)
- Pluggable provider registry for future models (Anthropic, Gemini, etc.)

Example usage (after registering provider):

```dart
final service = OpenAiService();
final reply = await service.createChatCompletion(
  edgeFunction: 'issue-openai-token',
  messages: const [
    OpenAiMessage(role: 'system', content: 'You are a helpful assistant'),
    OpenAiMessage(role: 'user', content: 'Say hello concisely'),
  ],
);
print(reply);
```

### AI Provider Abstraction

`AIProvider` interface:
```dart
abstract class AIProvider {
  String get name;
  Future<String> createChatCompletion({
    required List<AIMessage> messages,
    String? model,
    double? temperature,
  });
}
```

Registering multiple providers:
```dart
final registry = AIProviderRegistry();
registry.register(OpenAiService());
// registry.register(AnthropicService()); // future
final reply = await registry.provider('openai').createChatCompletion(
  messages: [AIMessage(role: 'user', content: 'Hi')],
);
```

### Retry Policy
Defined in `retry_policy.dart` with exponential backoff + jitter. Override:
```dart
final customRetry = RetryPolicy(maxAttempts: 5);
OpenAiService(retryPolicy: customRetry);
```

### Structured Errors
Errors derive from `AIError`:
- `AIUnauthorizedError` (401/403)
- `AIRateLimitError` (429, includes optional retryAfter)
- `AIServerError` (>=500)
- `AINetworkError` (timeouts / connectivity)
- `AIResponseParsingError` (invalid payload)

### Supabase Edge Function (Mock)
Located at `supabase/functions/issue-openai-token/index.ts`. Replace mock logic
with real validation + ephemeral token issuance.

### Testing
Example test in `test/openai_service_test.dart` uses a fake Dio client to
simulate provider responses. Run:
```bash
flutter test
```

### Continuous Integration
GitHub Actions workflow at `.github/workflows/ci.yml` runs:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test --coverage`

Artifacts: `coverage/lcov.info` uploaded for inspection.

### Environment Variables Recap
`OPENAI_BASE_URL` optional override (defaults to `https://api.openai.com/v1`).
Ephemeral tokens returned by edge functions — never store static API keys locally.

## �📋 Prerequisites

- Flutter SDK (^3.29.2)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## 🛠️ Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```

## 📁 Project Structure

```
flutter_app/
├── android/            # Android-specific configuration
├── ios/                # iOS-specific configuration
├── lib/
│   ├── core/           # Core utilities and services
│   │   └── utils/      # Utility classes
│   ├── presentation/   # UI screens and widgets
│   │   └── splash_screen/ # Splash screen implementation
│   ├── routes/         # Application routing
│   ├── theme/          # Theme configuration
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Application entry point
├── assets/             # Static assets (images, fonts, etc.)
├── pubspec.yaml        # Project dependencies and configuration
└── README.md           # Project documentation
```

## 🧩 Adding Routes

To add new routes to the application, update the `lib/routes/app_routes.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:package_name/presentation/home_screen/home_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // Add more routes as needed
  }
}
```

## 🎨 Theming

This project includes a comprehensive theming system with both light and dark themes:

```dart
// Access the current theme
ThemeData theme = Theme.of(context);

// Use theme colors
Color primaryColor = theme.colorScheme.primary;
```

The theme configuration includes:
- Color schemes for light and dark modes
- Typography styles
- Button themes
- Input decoration themes
- Card and dialog themes

## 📱 Responsive Design

The app is built with responsive design using the Sizer package:

```dart
// Example of responsive sizing
Container(
  width: 50.w, // 50% of screen width
  height: 20.h, // 20% of screen height
  child: Text('Responsive Container'),
)
```
## 📦 Deployment

Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## 🙏 Acknowledgments
- Built with [Rocket.new](https://rocket.new)
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ on Rocket.new
