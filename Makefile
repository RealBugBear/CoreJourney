.PHONY: help dev staging prod build-dev build-staging build-prod test test-coverage integration lint format analyze clean generate watch run-dev run-staging run-prod install release-readiness-mobile phase0-smoke long-test-ready ios iphone iphone-debug iphone-open iphone-profile emo iphone-emu emo-build emo-open

# Colors for output
CYAN := \033[0;36m
NC := \033[0m # No Color
IOS_DEVICE_ID ?= $(shell (flutter devices --machine 2>/dev/null || echo '[]') | node -e 'const fs=require("fs");let devices=[];try{devices=JSON.parse(fs.readFileSync(0,"utf8")||"[]")}catch(_){devices=[]}const iphone=devices.find(d=>d.targetPlatform==="ios"&&!d.emulator);if(iphone)process.stdout.write(iphone.id);' 2>/dev/null)
IOS_SIMULATOR_ID ?= $(shell (flutter devices --machine 2>/dev/null || echo '[]') | node -e 'const fs=require("fs");let devices=[];try{devices=JSON.parse(fs.readFileSync(0,"utf8")||"[]")}catch(_){devices=[]}const sim=devices.find(d=>d.targetPlatform==="ios"&&d.emulator);if(sim)process.stdout.write(sim.id);' 2>/dev/null)
IOS_BUNDLE_ID_DEV ?= com.alexandermessinger.corejourney.dev
IOS_BUNDLE_ID_RELEASE ?= com.alexandermessinger.corejourney

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

ios: ## Clean, install deps and run on iOS simulator/device
	flutter clean
	flutter pub get
	flutter run

iphone: ## Build, install, and launch iPhone app in a home-screen-safe mode (override with DEVICE=<id>)
	@DEVICE_ID="$${DEVICE:-$(IOS_DEVICE_ID)}"; \
	TARGET_BUNDLE_ID="$(IOS_BUNDLE_ID_RELEASE)"; \
	if [ -z "$$DEVICE_ID" ]; then \
		echo "No physical iPhone detected. Connect one and run: flutter devices"; \
		exit 1; \
	fi; \
	echo "Preparing iPhone $$DEVICE_ID"; \
	if grep -q "Profile-development" ios/Runner.xcodeproj/project.pbxproj; then \
		TARGET_BUNDLE_ID="$(IOS_BUNDLE_ID_DEV)"; \
		echo "Building profile development flavor..."; \
		if ! flutter build ios --profile --flavor development -t lib/main_development.dart; then \
			echo "Profile-development build failed. Check iOS flavor config or run: make iphone-debug"; \
			exit 1; \
		fi; \
	else \
		echo "Profile-development config not found; using release build (lib/main.dart) with bundle $$TARGET_BUNDLE_ID."; \
		flutter build ios --release -t lib/main.dart; \
	fi; \
	if [ ! -f build/ios/iphoneos/Runner.app/Info.plist ]; then \
		echo "Build artifact missing: build/ios/iphoneos/Runner.app"; \
		exit 1; \
	fi; \
	BUNDLE_ID="$$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - build/ios/iphoneos/Runner.app/Info.plist)"; \
	if [ "$$BUNDLE_ID" != "$$TARGET_BUNDLE_ID" ]; then \
		echo "Built bundle id '$$BUNDLE_ID' does not match expected '$$TARGET_BUNDLE_ID'."; \
		echo "Stop to avoid launching the wrong app variant."; \
		exit 1; \
	fi; \
	echo "Installing $$BUNDLE_ID on $$DEVICE_ID..."; \
	xcrun devicectl device install app --device "$$DEVICE_ID" build/ios/iphoneos/Runner.app >/tmp/corejourney_iphone_install.log 2>&1 || { \
		cat /tmp/corejourney_iphone_install.log; \
		echo "Install failed. Make sure the phone is connected and trusted."; \
		exit 1; \
	}; \
	echo "Launching $$BUNDLE_ID on $$DEVICE_ID..."; \
	LAUNCH_LOG="$$(mktemp)"; \
	if ! xcrun devicectl device process launch --device "$$DEVICE_ID" "$$BUNDLE_ID" 2>&1 | tee "$$LAUNCH_LOG"; then \
		if grep -Eq "could not be, unlocked|BSErrorCodeDescription = Locked|reason: Locked" "$$LAUNCH_LOG"; then \
			echo "iPhone is locked. Unlock iPhone and retry."; \
		elif grep -Eq "not installed|Unknown application|BundleIdentifier" "$$LAUNCH_LOG"; then \
			echo "App is not installed. Run: make iphone"; \
		else \
			echo "Launch failed. If prompted, allow Xcode/Terminal automation in macOS Settings > Privacy & Security > Automation."; \
		fi; \
		rm -f "$$LAUNCH_LOG"; \
		exit 1; \
	fi; \
	rm -f "$$LAUNCH_LOG"; \
	echo "Launch complete. You can reopen from the home screen."

iphone-debug: ## Launch dev flavor in debug mode with Flutter attach (not home-screen safe)
	@DEVICE_ID="$${DEVICE:-$(IOS_DEVICE_ID)}"; \
	if [ -z "$$DEVICE_ID" ]; then \
		echo "No physical iPhone detected. Connect one and run: flutter devices"; \
		exit 1; \
	fi; \
	echo "Running debug build on iPhone $$DEVICE_ID"; \
	echo "Note: On iOS 14+, debug Flutter apps can only be launched from Flutter/Xcode."; \
	if ! flutter run --flavor development -t lib/main_development.dart -d "$$DEVICE_ID"; then \
		echo "Debug launch failed. If needed, allow Terminal/Codex control of Xcode in macOS Settings > Privacy & Security > Automation."; \
		exit 1; \
	fi

iphone-open: ## Launch already-installed iPhone app bundle (no rebuild)
	@DEVICE_ID="$${DEVICE:-$(IOS_DEVICE_ID)}"; \
	TARGET_BUNDLE_ID="$(IOS_BUNDLE_ID_RELEASE)"; \
	if grep -q "Profile-development" ios/Runner.xcodeproj/project.pbxproj; then \
		TARGET_BUNDLE_ID="$(IOS_BUNDLE_ID_DEV)"; \
	fi; \
	BUNDLE_ID="$${BUNDLE_ID:-$$TARGET_BUNDLE_ID}"; \
	if [ -z "$$DEVICE_ID" ]; then \
		echo "No physical iPhone detected. Connect one and run: flutter devices"; \
		exit 1; \
	fi; \
	LAUNCH_LOG="$$(mktemp)"; \
	if ! xcrun devicectl device process launch --device "$$DEVICE_ID" "$$BUNDLE_ID" 2>&1 | tee "$$LAUNCH_LOG"; then \
		if grep -Eq "could not be, unlocked|BSErrorCodeDescription = Locked|reason: Locked" "$$LAUNCH_LOG"; then \
			echo "iPhone is locked. Unlock iPhone and retry."; \
		elif grep -Eq "Unknown application|not installed|BundleIdentifier" "$$LAUNCH_LOG"; then \
			echo "App '$$BUNDLE_ID' is not installed. Run: make iphone"; \
		else \
			echo "Launch failed. Retry with: make iphone"; \
		fi; \
		rm -f "$$LAUNCH_LOG"; \
		exit 1; \
	fi; \
	rm -f "$$LAUNCH_LOG"

iphone-profile: iphone ## Alias for iphone

emo: ## Build, install, and launch app on iPhone Simulator (Mac)
	@SIM_ID="$${SIM:-$(IOS_SIMULATOR_ID)}"; \
	if [ -z "$$SIM_ID" ]; then \
		SIM_ID="$$(xcrun simctl list devices booted | awk -F '[()]' '/iPhone/ && /Booted/ {print $$2; exit}')"; \
	fi; \
	if [ -z "$$SIM_ID" ]; then \
		echo "No booted iOS simulator found. Open Simulator and boot an iPhone first."; \
		echo "Tip: open -a Simulator"; \
		exit 1; \
	fi; \
	$(MAKE) emo-build SIM="$$SIM_ID" && \
	$(MAKE) emo-open SIM="$$SIM_ID"

emo-build: ## Build app for iPhone Simulator with explicit Xcode logging
	@SIM_ID="$${SIM:-$(IOS_SIMULATOR_ID)}"; \
	APP_PATH="build/ios_sim/Build/Products/Debug-iphonesimulator/Runner.app"; \
	LOG_FILE="/tmp/corejourney_emo_xcodebuild.log"; \
	if [ -z "$$SIM_ID" ]; then \
		echo "No iOS simulator detected. Open Simulator and boot an iPhone first."; \
		exit 1; \
	fi; \
	echo "Building for simulator $$SIM_ID"; \
	flutter pub get >/dev/null; \
	(cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination "id=$$SIM_ID" -derivedDataPath ../build/ios_sim build > "$$LOG_FILE" 2>&1); \
	BUILD_EXIT="$$?"; \
	cat "$$LOG_FILE"; \
	if [ "$$BUILD_EXIT" -ne 0 ]; then \
		echo "xcodebuild failed. Last log lines:"; \
		tail -n 80 "$$LOG_FILE"; \
		exit 1; \
	fi; \
	if [ ! -f "$$APP_PATH/Info.plist" ]; then \
		echo "Build artifact missing: $$APP_PATH"; \
		echo "Last xcodebuild log lines:"; \
		tail -n 80 "$$LOG_FILE"; \
		exit 1; \
	fi; \
	echo "Build complete: $$APP_PATH"

emo-open: ## Install and launch previously built simulator app
	@SIM_ID="$${SIM:-$(IOS_SIMULATOR_ID)}"; \
	APP_PATH="build/ios_sim/Build/Products/Debug-iphonesimulator/Runner.app"; \
	if [ -z "$$SIM_ID" ]; then \
		echo "No iOS simulator detected. Open Simulator and boot an iPhone first."; \
		exit 1; \
	fi; \
	if [ ! -f "$$APP_PATH/Info.plist" ]; then \
		echo "Build artifact missing: $$APP_PATH"; \
		echo "Run: make emo-build"; \
		exit 1; \
	fi; \
	BUNDLE_ID="$$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$$APP_PATH/Info.plist")"; \
	echo "Installing $$BUNDLE_ID on simulator $$SIM_ID..."; \
	xcrun simctl install "$$SIM_ID" "$$APP_PATH" || { \
		echo "Install failed. Ensure simulator is booted and reachable."; \
		exit 1; \
	}; \
	xcrun simctl terminate "$$SIM_ID" "$$BUNDLE_ID" >/dev/null 2>&1 || true; \
	echo "Launching $$BUNDLE_ID on simulator $$SIM_ID..."; \
	xcrun simctl launch "$$SIM_ID" "$$BUNDLE_ID" || { \
		echo "Launch failed. Try: xcrun simctl list devices booted"; \
		exit 1; \
	}

iphone-emu: emo ## Alias for iPhone simulator run

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

release-readiness-mobile: ## Focused mobile readiness checks for latest sessions
	./scripts/release_readiness.sh

phase0-smoke: ## Run Phase 0 stability gate + manual smoke prompt
	./scripts/phase0_smoke_check.sh

long-test-ready: ## Run expanded gate before multi-day test phase
	./scripts/long_test_ready.sh

release-notes: ## Generate release notes
	git log --oneline --decorate --no-merges $(shell git describe --tags --abbrev=0)..HEAD
