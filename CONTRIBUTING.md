# Contributing to CoreJourney

Thank you for your interest in contributing to CoreJourney! This document provides guidelines and instructions for contributing.

## Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/corejourney.git`
3. Run `make setup` to install dependencies and generate code
4. Create a feature branch: `git checkout -b feature/your-feature-name`

## Branch Naming Convention

- `feature/` - New features (e.g., `feature/social-sharing`)
- `fix/` - Bug fixes (e.g., `fix/login-crash`)
- `refactor/` - Code refactoring (e.g., `refactor/database-layer`)
- `docs/` - Documentation updates (e.g., `docs/api-documentation`)
- `test/` - Adding or updating tests (e.g., `test/training-module`)
- `chore/` - Build process, tooling (e.g., `chore/update-dependencies`)

## Code Style

### Dart Style Guide

We follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style).

**Key points:**
- Use `lowerCamelCase` for variables, methods, and parameters
- Use `UpperCamelCase` for types and classes
- Use `lowercase_with_underscores` for libraries and file names
- Maximum line length: 80 characters
- Use trailing commas for better git diffs

### Code Formatting

```bash
# Format all code
make format

# Check formatting without modifying files
make format-check
```

### Linting

```bash
# Run linter
make lint

# Run full analysis with fatal infos
make analyze
```

## Testing Requirements

All new features and bug fixes must include tests.

### Unit Tests

- Place tests in `test/` directory, mirroring the `lib/` structure
- Use descriptive test names: `test('should return user when login is successful')`
- Mock external dependencies using `mocktail`

Example:
```dart
void main() {
  group('LoginService', () {
    late LoginService loginService;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      loginService = LoginService(authRepository: mockAuthRepository);
    });

    test('should return user when login is successful', () async {
      // Arrange
      when(() => mockAuthRepository.login(any(), any()))
          .thenAnswer((_) async => testUser);

      // Act
      final result = await loginService.login('email', 'password');

      // Assert
      expect(result, equals(testUser));
    });
  });
}
```

### Widget Tests

- Test widget behavior and UI interactions
- Use `ProviderScope` for widgets that use Riverpod

### Integration Tests

- Place in `integration_test/` directory
- Test complete user flows
- Run with `make integration`

### Coverage Requirements

- Aim for >70% code coverage
- Critical business logic should have >90% coverage
- Run `make test-coverage` to generate coverage report

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process, tooling, dependencies

**Examples:**
```
feat(training): add new exercise types

Add support for balance and coordination exercises with
customizable duration and difficulty levels.

Closes #123
```

```
fix(auth): prevent login crash on network error

Handle network errors gracefully in login flow by showing
appropriate error message to user.

Fixes #456
```

## Pull Request Process

1. **Update your branch** with the latest changes from `main` or `develop`
   ```bash
   git fetch origin
   git rebase origin/develop
   ```

2. **Run all checks locally** before pushing
   ```bash
   make verify  # Runs format-check, lint, and tests
   ```

3. **Push your branch** to your fork
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create a Pull Request** on GitHub
   - Use a clear, descriptive title
   - Fill out the PR template completely
   - Link related issues
   - Add screenshots/videos for UI changes

5. **Address review feedback**
   - Make requested changes
   - Push additional commits (don't force push during review)
   - Respond to comments

6. **Merge requirements**
   - All CI checks must pass
   - At least one approval from a maintainer
   - No merge conflicts
   - Up to date with target branch

## Feature Flags

When adding new features, consider using feature flags:

1. Add flag to `lib/core/feature_flags/feature_flags.dart`:
   ```dart
   newFeature('new_feature_name', false),
   ```

2. Use the flag in your code:
   ```dart
   final isEnabled = ref.watch(featureFlagProvider(FeatureFlag.newFeature));
   ```

3. Configure the flag in Firebase Remote Config

See [docs/FEATURE_FLAGS.md](docs/FEATURE_FLAGS.md) for more details.

## Code Review Guidelines

### For Authors

- Keep PRs focused and reasonably sized (< 400 lines if possible)
- Write clear descriptions of what and why
- Self-review your code before requesting review
- Respond to comments promptly
- Be open to feedback

### For Reviewers

- Be respectful and constructive
- Explain the reasoning behind suggestions
- Approve when ready, request changes when needed
- Nitpicks should be marked as optional
- Focus on logic, security, and maintainability

## Documentation

- Update relevant documentation when making changes
- Add JSDoc/DartDoc comments for public APIs
- Include examples in complex documentation
- Keep docs concise but comprehensive

## Questions or Issues?

- Check existing issues before creating new ones
- Use issue templates when available
- Provide reproduction steps for bugs
- Include device/OS information for platform-specific issues

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
