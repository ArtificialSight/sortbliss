# Flutter

A modern Flutter-based mobile application utilizing the latest mobile development technologies and tools for building responsive cross-platform applications.

## 📋 Prerequisites

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

## 🔐 Secure configuration & secret handling

This project follows the [vpnsecurity.blog](https://vpnsecurity.blog/) guidance
for mobile secret management: secrets live on the server, the client only
receives short-lived tokens, and environment variables are injected at build
time.

### Local development

1. Duplicate the sample environment file and populate it with the tokens that
   are safe to expose to the client (short-lived session tokens only):

   ```bash
   cp .env.example .env
   ```

2. Request temporary session tokens from your Supabase Edge Function (see the
   next section). These values should **never** be committed – they expire and
   are refreshed automatically by the app at runtime.

3. Run the app. `flutter_dotenv` will hydrate configuration from `.env` while
   keeping the file outside of version control:

   ```bash
   flutter run
   ```

### CI / production builds

- Provide configuration using `--dart-define` so secrets are injected by the CI
  environment rather than embedded in the source tree:

  ```bash
  flutter build apk \
    --dart-define=SUPABASE_URL=https://your-project.supabase.co \
    --dart-define=SUPABASE_FUNCTIONS_URL=https://your-project.functions.supabase.co
  ```

- Use your secrets manager (e.g. GitHub Actions secrets, Vercel env vars) to
  provide the Supabase session token that will be exchanged for short-lived
  provider tokens during runtime.

### Supabase Edge Function guardrail

Store provider API keys (OpenAI, Gemini, Anthropic, Perplexity, etc.) inside a
Supabase Edge Function. The function verifies the caller session and returns an
ephemeral token that expires in minutes:

```ts
// supabase/functions/issue-openai-token/index.ts
import { createClient } from "@supabase/supabase-js";

export const issueOpenAiToken = async (req: Request) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    global: { headers: { Authorization: req.headers.get("Authorization")! } },
  });

  const { data: session, error } = await supabase.auth.getUser();
  if (error || !session) {
    return new Response("Unauthorized", { status: 401 });
  }

  // Issue a token stored server-side; never send the provider API key itself.
  const token = await createShortLivedToken({ ttlSeconds: 300 });
  return Response.json({ token, expiresIn: 300 });
};
```

### Client integration

- `Environment.bootstrap()` loads `.env` locally and supports `--dart-define`
  overrides for automated pipelines.
- `SecureSupabaseClient` exchanges the Supabase session for a short-lived token
  from the Edge Function, enforcing authenticated requests.
- `AuthenticatedHttpClient` wraps Dio to guarantee every outbound provider call
  includes the freshly minted token, blocking unauthenticated access paths.

When the session expires, the Supabase client refreshes it and the application
requests a new provider token. No long-lived secrets ever ship in the mobile
binary.

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
