# CoreJourney

Pränatales Reflextraining App - A comprehensive Flutter application for prenatal reflex training.

## Features

- 🎯 Comprehensive training modules
- 📊 Progress tracking and analytics
- 🔄 Offline-first architecture with cloud sync
- 🎨 Modern Material Design UI
- 🌍 Multi-environment support (Dev, Staging, Production)
- 🚀 Feature flag system for gradual rollouts
- 📈 Analytics and crash reporting
- 🔒 Secure data storage

## Quick Start

### Prerequisites

- Flutter SDK 3.3.0 or higher
- Dart SDK 3.0.0 or higher
- Firebase project (separate projects for dev/staging/prod)
- Android Studio / Xcode for platform-specific builds

### Installation

```bash
# Clone the repository
git clone https://github.com/alexandermessinger/corejourney.git
cd corejourney

# Install dependencies
flutter pub get

# Run code generation (for Isar database)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app in development mode
make dev
# or
flutter run --flavor development -t lib/main_development.dart
```

## Development

### Build Flavors

The app supports three build flavors:

1. **Development** - For local development and testing
   - Bundle ID: `com.alexandermessinger.corejourney.dev`
   - App Name: CoreJourney DEV
   - Debug banner: Visible
   - Analytics: Disabled

2. **Staging** - For internal testing and QA
   - Bundle ID: `com.alexandermessinger.corejourney.staging`
   - App Name: CoreJourney STAGING
   - Debug banner: Hidden
   - Analytics: Enabled

3. **Production** - For release to app stores
   - Bundle ID: `com.alexandermessinger.corejourney`
   - App Name: CoreJourney
   - Debug banner: Hidden
   - Analytics: Enabled

### Common Commands

We use a Makefile for common development tasks. Run `make help` to see all available commands.

```bash
# Development
make dev              # Run in development mode
make staging          # Run in staging mode
make prod             # Run in production mode

# Building
make build-dev        # Build development APK
make build-staging    # Build staging release
make build-prod       # Build production release

# Testing
make test             # Run unit tests
make test-coverage    # Generate coverage report
make integration      # Run integration tests

# Code Quality
make lint             # Run linter
make format           # Format code
make analyze          # Static analysis
make verify           # Run all checks (format, lint, test)

# Code Generation
make generate         # Run build_runner once
make watch            # Run build_runner in watch mode

# Utilities
make clean            # Clean build artifacts
make setup            # Install deps + generate code
```

## Architecture

The app follows Clean Architecture principles with the following structure:

```
lib/
├── bootstrap/          # App initialization
├── config/             # App configuration
├── core/               # Core utilities and services
│   ├── analytics/      # Analytics service
│   ├── database/       # Local database (Isar)
│   ├── feature_flags/  # Feature flag system
│   ├── logging/        # Logging service
│   ├── security/       # Secure storage
│   └── sync/           # Cloud sync service
├── features/           # Feature modules
│   ├── auth/           # Authentication
│   ├── profile/        # User profile
│   ├── progress/       # Progress tracking
│   └── training/       # Training modules
└── main_*.dart         # Environment entry points
```

### Key Technologies

- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local Database**: Isar
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Analytics**: Firebase Analytics
- **Crash Reporting**: Firebase Crashlytics
- **Feature Flags**: Firebase Remote Config

## Feature Flags

Feature flags allow gradual rollout of new features. Access them via:

```dart
// In a ConsumerWidget
final isEnabled = ref.watch(featureFlagProvider(FeatureFlag.newFeature));

if (isEnabled) {
  // Show new feature
}
```

In dev/staging environments, you can override flags in the Developer Settings screen.

## Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# Test with coverage
flutter test --coverage

# View coverage report
make test-coverage
open coverage/html/index.html
```

## Deployment

### Staging

Push to `develop` branch to automatically deploy to Firebase App Distribution:

```bash
git push origin develop
```

### Production

Create a version tag to trigger production deployment:

```bash
# Create and push tag
git tag v1.0.0
git push origin v1.0.0
```

This will:
1. Build production APK/AAB
2. Upload to Play Store Internal Track
3. Build and upload iOS to TestFlight
4. Create a GitHub release

## Environment Variables

Environment-specific variables are stored in `.env.*` files:

- `.env.dev` - Development environment
- `.env.staging` - Staging environment
- `.env.prod` - Production environment

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Documentation

- [Build Flavors Guide](docs/BUILD_FLAVORS.md)
- [Feature Flags Guide](docs/FEATURE_FLAGS.md)
- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [iOS Setup Guide](docs/IOS_SCHEMES_SETUP.md)
- [Accessibility Guide](docs/ACCESSIBILITY_GUIDE.md)

## License

Copyright © 2024 Alexander Messinger. All rights reserved.
