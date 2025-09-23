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

`OpenAiService` demonstrates calling the OpenAI Chat Completions API using a
short‑lived token minted by a Supabase Edge Function. Example usage:

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

You still need to implement the `issue-openai-token` Edge Function to return the
ephemeral token JSON shape: `{ "token": "...", "expiresIn": 300 }`.

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
