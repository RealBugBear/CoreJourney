.PHONY: help dev staging prod build-dev build-staging build-prod test test-coverage integration lint format analyze clean generate watch run-dev run-staging run-prod install

# Colors for output
CYAN := \033[0;36m
NC := \033[0m # No Color

help: ## Show this help message
	@echo '${CYAN}CoreJourney Development Commands${NC}'
	@echo ''
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  ${CYAN}%-20s${NC} %s\n", $$1, $$2}'

## Development Commands

dev: ## Run app in development mode
	flutter run --flavor development -t lib/main_development.dart

staging: ## Run app in staging mode
	flutter run --flavor staging -t lib/main_staging.dart

prod: ## Run app in production mode
	flutter run --flavor production -t lib/main_production.dart

run-dev: dev ## Alias for dev

run-staging: staging ## Alias for staging

run-prod: prod ## Alias for prod

## Build Commands

build-dev: ## Build development APK
	flutter build apk --flavor development -t lib/main_development.dart --debug

build-dev-release: ## Build development release APK
	flutter build apk --flavor development -t lib/main_development.dart --release

build-staging: ## Build staging release APK/AAB
	flutter build apk --flavor staging -t lib/main_staging.dart --release
	flutter build appbundle --flavor staging -t lib/main_staging.dart --release

build-prod: ## Build production release APK/AAB
	flutter build apk --flavor production -t lib/main_production.dart --release
	flutter build appbundle --flavor production -t lib/main_production.dart --release

build-ios-dev: ## Build iOS development
	flutter build ios --flavor development -t lib/main_development.dart --debug

build-ios-staging: ## Build iOS staging
	flutter build ios --flavor staging -t lib/main_staging.dart --release

build-ios-prod: ## Build iOS production
	flutter build ipa --flavor production -t lib/main_production.dart --release

## Testing Commands

test: ## Run all unit tests
	flutter test

test-coverage: ## Generate test coverage report
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html
	@echo "${CYAN}Coverage report generated at coverage/html/index.html${NC}"

integration: ## Run integration tests
	flutter test integration_test

integration-dev: ## Run integration tests for dev flavor
	flutter test integration_test --flavor development -t lib/main_development.dart

## Code Quality Commands

lint: ## Run linter
	flutter analyze

format: ## Format code
	dart format .

format-check: ## Check code formatting
	dart format --set-exit-if-changed .

analyze: ## Run static analysis
	flutter analyze --fatal-infos

fix: ## Apply automated fixes
	dart fix --apply

## Code Generation Commands

generate: ## Run build_runner once
	flutter pub run build_runner build --delete-conflicting-outputs

watch: ## Run build_runner in watch mode
	flutter pub run build_runner watch --delete-conflicting-outputs

## Cleanup Commands

clean: ## Clean build artifacts
	flutter clean
	rm -rf build/

clean-all: clean ## Clean everything including dependencies
	rm -rf .dart_tool/
	rm -rf pubspec.lock

## Dependency Commands

install: ## Install dependencies
	flutter pub get

upgrade: ## Upgrade dependencies
	flutter pub upgrade

outdated: ## Check for outdated dependencies
	flutter pub outdated

## Firebase Commands

firebase-dev: ## Configure Firebase for development
	flutterfire configure --project=corejourney-dev --out=lib/firebase_options.dart --platforms=android,ios

firebase-prod: ## Configure Firebase for production
	flutterfire configure --project=corejourney-prod --out=lib/firebase_options_prod.dart --platforms=android,ios

## Utility Commands

doctor: ## Run Flutter doctor
	flutter doctor -v

check: lint test ## Run linter and tests

verify: format-check lint test ## Verify code quality (formatting, linting, tests)

setup: install generate ## Setup project (install deps + generate code)

rebuild: clean install generate ## Full rebuild

## Release Commands

pre-release: verify ## Run all checks before release
	@echo "${CYAN}All checks passed! Ready for release.${NC}"

release-notes: ## Generate release notes
	git log --oneline --decorate --no-merges $(shell git describe --tags --abbrev=0)..HEAD
