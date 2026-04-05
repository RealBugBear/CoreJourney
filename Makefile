DEVICE_ID   := 00008140-000671E10AEB001C
SIM_ID      := 4D038F07-94D0-4E0C-8794-74CE91566CAB
ENTRY       := lib/main_development.dart
ENTRY_PROD  := lib/main_production.dart

.PHONY: run run-sim release clean

# NOTE: Profile mode is the ONLY stable mode on physical iPhone with iOS 26.2.1 beta.
# Debug mode fails to establish the Xcode debug proxy.
# Release mode fails to establish the launch connection.
# Profile mode (AOT-compiled, minimal VM overhead) launches reliably.
# Make sure iPhone is UNLOCKED and screen is ON before running.

## [DEFAULT] Run on physical iPhone in profile mode
## Quits Xcode first — Xcode being open causes "Timed out waiting for workspace" errors.
run:
	@osascript -e 'tell application "Xcode" to quit' 2>/dev/null || true
	@sleep 1
	flutter run --profile -d $(DEVICE_ID) -t $(ENTRY)

## Run on iOS 26 simulator in debug mode
run-sim:
	flutter run -d $(SIM_ID) -t $(ENTRY)

## Build release IPA for TestFlight / App Store
## After this completes, open Xcode → Window → Organizer → distribute the archive.
release:
	@osascript -e 'tell application "Xcode" to quit' 2>/dev/null || true
	@sleep 1
	flutter build ipa -t $(ENTRY_PROD) --release
	@echo ""
	@echo "✅ Build complete."
	@echo "   Open Xcode Organizer to upload:"
	@echo "   open build/ios/archive/Runner.xcarchive"

## Clean build artifacts and reinstall packages
clean:
	flutter clean && flutter pub get
