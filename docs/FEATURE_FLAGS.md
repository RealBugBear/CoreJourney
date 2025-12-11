# Feature Flags Guide

## Overview

Feature flags (also called feature toggles) allow you to enable or disable features without deploying new code. This is useful for:

- **Gradual rollouts**: Release features to a small percentage of users first
- **A/B testing**: Test different implementations with different user groups
- **Kill switches**: Quickly disable problematic features
- **Dev/staging testing**: Test features in non-production environments
- **Beta features**: Let users opt-in to experimental features

## Implementation

CoreJourney uses Firebase Remote Config for feature flags with local overrides for development.

### Architecture

```
┌─────────────────────┐
│  Feature Flag       │
│  Request            │
└──────────┬──────────┘
           │
           ▼
┌──────────────────────────────┐
│  Local Override?             │
│  (Dev/Staging only)          │
└──────┬───────────────────────┘
       │ No
       ▼
┌──────────────────────────────┐
│  Firebase Remote Config      │
└──────┬───────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  Default Value               │
└──────────────────────────────┘
```

## Adding a New Feature Flag

### 1. Define the Flag

Add the flag to `lib/core/feature_flags/feature_flags.dart`:

```dart
enum FeatureFlag {
  // ... existing flags
  
  /// Your new feature description
  myNewFeature('my_new_feature', false),
}
```

**Parameters:**
- First parameter: Remote config key (use snake_case)
- Second parameter: Default value (fallback if remote config unavailable)

Add a description in the `description` getter:

```dart
String get description {
  switch (this) {
    // ... existing cases
    
    case FeatureFlag.myNewFeature:
      return 'Description of what this feature does';
  }
}
```

### 2. Use the Flag in Your Code

In a ConsumerWidget or Consumer:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final isEnabled = ref.watch(featureFlagProvider(FeatureFlag.myNewFeature));
  
  if (isEnabled) {
    return NewFeatureWidget();
  } else {
    return OldFeatureWidget();
  }
}
```

Or read it directly from the service:

```dart
final featureFlags = ref.read(featureFlagServiceProvider);
if (featureFlags.isEnabled(FeatureFlag.myNewFeature)) {
  // Feature logic
}
```

## Configuration in Firebase

### Setup Remote Config

1. Go to Firebase Console → Remote Config
2. Add a new parameter:
   - **Parameter key**: `my_new_feature` (must match the flag key)
   - **Data type**: Boolean
   - **Default value**: `false` (or `true` if enabled by default)

3. (Optional) Create conditions for gradual rollout:
   ```
   Condition: 10% of users
   Value: true
   
   Default value: false
   ```

4. Click "Publish changes"

### Environment-Specific Values

You can set different values per Firebase project:

- **Development**: Quick feature iteration
- **Staging**: Test with internal team
- **Production**: Gradual rollout to real users

## Local Development

### Developer Settings

Access via the Developer Settings screen (dev/staging only):

1. Run the app in dev/staging mode
2. Navigate to Developer Settings
3. View all feature flags
4. Toggle flags locally
5. Changes persist across app restarts
6. Clear overrides when done

### Programmatic Override

```dart
final featureFlags = ref.read(featureFlagServiceProvider);

// Set override (dev/staging only)
await featureFlags.setOverride(FeatureFlag.myNewFeature, true);

// Clear override
await featureFlags.clearOverride(FeatureFlag.myNewFeature);

// Clear all overrides
await featureFlags.clearAllOverrides();
```

## Best Practices

### 1. Naming Conventions

- Use descriptive names: `socialSharing` not `feature1`
- Use snake_case for remote config keys: `social_sharing`
- Keep names short but clear

### 2. Default Values

- Production features should default to `false` (opt-in)
- Stable features can default to `true` (opt-out)
- Consider the behavior if Firebase is unavailable

### 3. Flag Lifecycle

1. **Development**: Add flag, default to `false`
2. **Testing**: Enable in dev/staging
3. **Rollout**: Enable for small % in production
4. **Stable**: Increase rollout percentage
5. **Complete**: Set default to `true`, eventually remove flag
6. **Cleanup**: Remove flag code when feature is stable

### 4. Clean Up Old Flags

Remove feature flags after:
- Feature is stable and rolled out to 100%
- At least 2 weeks at 100% rollout
- No plans to disable the feature

### 5. Testing with Flags

Write tests for both enabled and disabled states:

```dart
group('MyFeature', () {
  test('when flag is enabled', () {
    // Test new behavior
  });
  
  test('when flag is disabled', () {
    // Test old behavior or fallback
  });
});
```

## Configuration Flags

For non-boolean configuration values, use `ConfigFlag`:

```dart
// Define in feature_flags.dart
enum ConfigFlag {
  apiTimeout('api_timeout'),
}

// Use in code
final timeout = ref.watch(configFlagIntProvider((
  flag: ConfigFlag.apiTimeout,
  defaultValue: 30,
)));
```

## Monitoring

### Analytics Integration

Track feature flag usage:

```dart
final analytics = ref.read(analyticsServiceProvider);
analytics.logFeatureUsage(
  featureName: 'my_new_feature',
  parameters: {
    'enabled': isEnabled,
  },
);
```

### Logging

Feature flag service logs all operations:

```
[FeatureFlags] Initialized with 7 flags
[FeatureFlags] Override set: my_new_feature = true
[FeatureFlags] Refreshed from Remote Config
```

## Troubleshooting

### Flag not updating

1. Check Firebase console for published changes
2. Force refresh: Developer Settings → Refresh button
3. Check minimum fetch interval in bootstrap.dart
4. Verify flag key matches exactly (case-sensitive)

### Override not working

1. Only works in dev/staging (not production)
2. Check SharedPreferences for stored overrides
3. Clear all overrides and try again

### Default value always returned

1. Check Firebase configuration
2. Verify internet connectivity
3. Check Firebase initialization in bootstrap
4. Review Remote Config fetch settings

## Examples

### Gradual Feature Rollout

```dart
// In Firebase Remote Config:
Condition: App version >= 2.0
Value: true

Condition: Random percentile <= 10
Value: true

Default: false
```

### A/B Testing

```dart
// In Firebase Remote Config:
Condition: User in group A
Parameter: button_color
Value: "blue"

Condition: User in group B  
Parameter: button_color
Value: "green"

// In code:
final buttonColor = featureFlags.getString(
  ConfigFlag.buttonColor,
  'blue', // default
);
```

### Kill Switch

```dart
// Quickly disable problematic feature:
// 1. Set flag to false in Firebase
// 2. Changes propagate within minutes
// 3. Feature disabled for all users
// 4. No app update required
```

## Resources

- [Firebase Remote Config Documentation](https://firebase.google.com/docs/remote-config)
- [Feature Toggle Best Practices](https://martinfowler.com/articles/feature-toggles.html)
