SHELL=/bin/bash

BUILD_TOOLS_DIR=./BuildTools

PACKAGE_SCHEME ?= QuranEngine-Package
PACKAGE_SDK ?= iphonesimulator
PACKAGE_DESTINATION ?= name=iPhone 17,OS=26.2
EXAMPLE_PROJECT ?= Example/QuranEngineApp.xcodeproj
EXAMPLE_SCHEME ?= QuranEngineApp
EXAMPLE_SDK ?= iphonesimulator
EXAMPLE_DESTINATION ?= generic/platform=iOS

SWIFT_FORMAT_REPO=https://github.com/nicklockwood/SwiftFormat
SWIFT_FORMAT_VERSION=0.62.1
SWIFT_FORMAT_DIR=$(BUILD_TOOLS_DIR)/SwiftFormat
SWIFT_FORMAT_BIN=$(SWIFT_FORMAT_DIR)/.build/release/swiftformat
SWIFT_FORMAT_VERSION_FILE=$(abspath $(SWIFT_FORMAT_DIR))/.swiftformat-version

CURRENT_TARGET=$(if $(TARGET),$(TARGET),$(PACKAGE_SCHEME))
WITHOUT_QURAN_SYNC=env -u QURAN_SYNC
WITH_QURAN_SYNC=env QURAN_SYNC=1

.PHONY: test test-no-sync test-sync test-without-sync test-with-sync build build-no-sync build-sync build-without-sync build-with-sync build-example build-example-no-sync build-example-sync build-example-without-sync build-example-with-sync clone-swiftformat build-swiftformat force-build-swiftformat clean-swiftformat format-lint format-autocorrect install-swiftlint build-for-analyzer swiftlint-analyzer

test: test-no-sync

test-no-sync: test-without-sync

test-sync: test-with-sync

test-without-sync:
	set -o pipefail; $(WITHOUT_QURAN_SYNC) xcrun xcodebuild build test -scheme $(CURRENT_TARGET) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

test-with-sync:
	set -o pipefail; $(WITH_QURAN_SYNC) xcrun xcodebuild build test -scheme $(CURRENT_TARGET) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

build: build-no-sync

build-no-sync: build-without-sync

build-sync: build-with-sync

build-without-sync:
	set -o pipefail; $(WITHOUT_QURAN_SYNC) xcrun xcodebuild build -scheme $(CURRENT_TARGET) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" | xcbeautify --renderer github-actions

build-with-sync:
	set -o pipefail; $(WITH_QURAN_SYNC) xcrun xcodebuild build -scheme $(CURRENT_TARGET) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" | xcbeautify --renderer github-actions

build-example: build-example-no-sync

build-example-no-sync: build-example-without-sync

build-example-sync: build-example-with-sync

build-example-without-sync:
	set -o pipefail; $(WITHOUT_QURAN_SYNC) xcrun xcodebuild build -project $(EXAMPLE_PROJECT) -scheme $(EXAMPLE_SCHEME) -sdk "$(EXAMPLE_SDK)" -destination "$(EXAMPLE_DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcbeautify --renderer github-actions

build-example-with-sync:
	set -o pipefail; $(WITH_QURAN_SYNC) xcrun xcodebuild build -project $(EXAMPLE_PROJECT) -scheme $(EXAMPLE_SCHEME) -sdk "$(EXAMPLE_SDK)" -destination "$(EXAMPLE_DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcbeautify --renderer github-actions

clone-swiftformat:
	@mkdir -p $(BUILD_TOOLS_DIR)
	@if [ ! -d $(SWIFT_FORMAT_DIR) ]; then \
		echo "Cloning SwiftFormat repository..."; \
		git clone --branch $(SWIFT_FORMAT_VERSION) --depth 1 $(SWIFT_FORMAT_REPO) $(SWIFT_FORMAT_DIR); \
	else \
		echo "SwiftFormat repository already exists. Checking out $(SWIFT_FORMAT_VERSION)."; \
		cd $(SWIFT_FORMAT_DIR) && git fetch --depth 1 origin tag $(SWIFT_FORMAT_VERSION) && git checkout $(SWIFT_FORMAT_VERSION); \
	fi

build-swiftformat: clone-swiftformat
	@if [ ! -f $(SWIFT_FORMAT_BIN) ] || [ "$$(cat $(SWIFT_FORMAT_VERSION_FILE) 2>/dev/null)" != "$(SWIFT_FORMAT_VERSION)" ]; then \
		echo "Building swiftformat in $(SWIFT_FORMAT_DIR)"; \
		cd $(SWIFT_FORMAT_DIR) && swift build -c release; \
		echo "$(SWIFT_FORMAT_VERSION)" > $(SWIFT_FORMAT_VERSION_FILE); \
	else \
		echo "SwiftFormat binary already exists."; \
	fi

force-build-swiftformat: clone-swiftformat
	@echo "Force building swiftformat in $(SWIFT_FORMAT_DIR)"
	cd $(SWIFT_FORMAT_DIR) && swift build -c release
	@echo "$(SWIFT_FORMAT_VERSION)" > $(SWIFT_FORMAT_VERSION_FILE)

clean-swiftformat:
	@rm -rf $(SWIFT_FORMAT_DIR)/.build

format-lint: $(SWIFT_FORMAT_BIN)
	$(SWIFT_FORMAT_BIN) --lint .

format-autocorrect: $(SWIFT_FORMAT_BIN)
	$(SWIFT_FORMAT_BIN) .

$(SWIFT_FORMAT_BIN): build-swiftformat

install-swiftlint:
	brew install swiftlint

build-for-analyzer:
	xcrun xcodebuild clean build -scheme QuranEngine-Package -sdk "iphonesimulator" -destination "name=iPhone 14 Pro,OS=17.2" > .build/xcodebuild.log

swiftlint-analyzer:
	swiftlint analyze --strict  --quiet --compiler-log-path .build/xcodebuild.log
