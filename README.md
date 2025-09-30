# Flutter
A modern Flutter-based mobile application utilizing the latest mobile development technologies and tools for building responsive cross-platform applications.

## 🔐 Secure configuration & secret handling
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
2. Calls a Supabase Edge Function (e.g. issue-openai-token).
3. Edge Function validates session; mints short‑lived provider token.
4. AuthenticatedHttpClient includes that token in outbound provider requests.

Edge functions never return raw provider secret keys—only ephemeral tokens.

### OpenAI integration scaffold
OpenAiService (direct) and OpenAiProxyService (secure) implement the generic AIProvider strategy. Prefer the proxy service for production because the real OpenAI API key stays server-side in a Supabase Edge Function (openai-chat).

- • Ephemeral token acquisition (Supabase Edge Function)
- • Exponential backoff + jitter retry policy
- • Structured error mapping (unauthorized, rate limit, network, parsing)
- • Pluggable provider registry for future models (Anthropic, Gemini, etc.)

Example usage (proxy, recommended):
```dart
final service = OpenAiService();
final registry = AIProviderRegistry();
registry.register(OpenAiProxyService());
final reply = await registry.provider('openai-proxy').createChatCompletion(
  messages: const [
    AIMessage(role: 'system', content: 'You are a helpful assistant'),
    AIMessage(role: 'user', content: 'Say hello concisely'),
  ],
);
print(reply);
```

### AI Provider Abstraction
AIProvider interface:
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
Defined in retry_policy.dart with exponential backoff + jitter. Override:
```dart
final customRetry = RetryPolicy(maxAttempts: 5);
OpenAiService(retryPolicy: customRetry);
```

### Structured Errors
Errors derive from AIError:
• AIUnauthorizedError (401/403)
• AIRateLimitError (429, includes optional retryAfter)
• AIServerError (>=500)
• AINetworkError (timeouts / connectivity)
• AIResponseParsingError (invalid payload)

### Supabase Edge Function (Proxy)
Located at supabase/functions/openai-chat/index.ts.

Environment variables (set in Supabase dashboard):
• OPENAI_API_KEY: Your real OpenAI key (never exposed to client)
• OPENAI_BASE_URL (optional override)

Request flow: Client → openai-chat (Authorization: Bearer Supabase session) → OpenAI → Response → Client

Legacy mock token function removed. Secure proxy (openai-chat) is the default.

### Debug & Observability
Enable verbose AI logs:
```bash
flutter run --dart-define=AI_DEBUG=1
```

Logs are tagged with AI (use devtools logging view).

### Streaming
OpenAiProxyStreamService consumes Server-Sent Events (SSE) when stream: true. Edge function now forwards OpenAI streaming chunks:
```dart
final streamService = OpenAiProxyStreamService();
final buffer = StringBuffer();
await for (final token in streamService.streamChatCompletion(
  messages: const [AIMessage(role: 'user', content: 'Explain streams briefly')],
)) {
  buffer.write(token);
}
print(buffer.toString());
```

Handle partial tokens incrementally for responsive UI (e.g. animated typing effect).

### Composite Provider Fallback
Use CompositeAIProvider to chain providers:
```dart
final composite = CompositeAIProvider([
  OpenAiProxyService(),
  // AnthropicProxyService(), // future
]);
final reply = await composite.createChatCompletion(
  messages: const [AIMessage(role: 'user', content: 'Fallback test')],
);
```

### Testing
Example test in test/openai_service_test.dart uses a fake Dio client to simulate provider responses. Run:
```bash
flutter test
```

### Continuous Integration
GitHub Actions workflow at .github/workflows/ci.yml runs:
1. flutter pub get
2. flutter analyze
3. flutter test --coverage

Artifacts: coverage/lcov.info uploaded for inspection.

### Environment Variables Recap
OPENAI_BASE_URL optional override (defaults to https://api.openai.com/v1). Ephemeral tokens returned by edge functions — never store static API keys locally.

### Moderation
The edge function performs a moderation pre-check (model omni-moderation-latest) on the last user message. If flagged, it returns HTTP 400 with { "error": "Content flagged by moderation" }. Client code should catch this and present a polite warning. Local placeholder OpenAiModerationService is included for future client-side heuristics or offline simulation.

## 📋 Prerequisites

- • Flutter SDK (^3.29.2)
- • Dart SDK
- • Android Studio / VS Code with Flutter extensions
- • Android SDK / Xcode (for iOS development)

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

This project follows the [vpnsecurity.blog](https://vpnsecurity.blog/) guidance for mobile secret management: secrets live on the server, the client only receives short-lived tokens, and environment variables are injected at build time.

### Local development

1. Duplicate the sample environment file and populate it with the tokens that are safe to expose to the client (short-lived session tokens only):
```bash
cp .env.example .env
```
2. Request temporary session tokens from your Supabase Edge Function (see the next section). These values should never be committed – they expire and are refreshed automatically by the app at runtime.
3. Run the app. flutter_dotenv will hydrate configuration from .env while keeping the file outside of version control:
```bash
flutter run
```

### CI / production builds

• Provide configuration using --dart-define so secrets are injected by the CI environment rather than embedded in the source tree:
```bash
flutter build apk \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_FUNCTIONS_URL=https://your-project.functions.supabase.co
```
• Use your secrets manager (e.g. GitHub Actions secrets, Vercel env vars) to provide the Supabase session token that will be exchanged for short-lived provider tokens during runtime.

### Supabase Edge Function guardrail
Store provider API keys (OpenAI, Gemini, Anthropic, Perplexity, etc.) inside a Supabase Edge Function. The function verifies the caller session and returns an ephemeral token that expires in minutes:
```javascript
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
• Environment.bootstrap() loads .env locally and supports --dart-define overrides for automated pipelines.
• SecureSupabaseClient exchanges the Supabase session for a short-lived token from the Edge Function, enforcing authenticated requests.
• AuthenticatedHttpClient wraps Dio to guarantee every outbound provider call includes the freshly minted token, blocking unauthenticated access paths.

When the session expires, the Supabase client refreshes it and the application requests a new provider token. No long-lived secrets ever ship in the mobile binary.

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

To add new routes to the application, update the lib/routes/app_routes.dart file:
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
- • Color schemes for light and dark modes
- • Typography styles
- • Button themes
- • Input decoration themes
- • Card and dialog themes

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

- • Built with [Rocket.new](https://rocket.new/)
- • Powered by [Flutter](https://flutter.dev/) & [Dart](https://dart.dev/)
- • Styled with Material Design

Built with ❤️ on Rocket.new

<!-- CI workflow trigger: Updated after fixing gameplay_screen.dart syntax errors -->
