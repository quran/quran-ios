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
SWIFT_FORMAT_VERSION=0.54.3
SWIFT_FORMAT_DIR=$(BUILD_TOOLS_DIR)/SwiftFormat
SWIFT_FORMAT_BIN=$(SWIFT_FORMAT_DIR)/.build/release/swiftformat

CURRENT_TARGET=$(if $(TARGET),$(TARGET),$(PACKAGE_SCHEME))

.PHONY: test build build-example clone-swiftformat build-swiftformat force-build-swiftformat clean-swiftformat format-lint format-autocorrect install-swiftlint build-for-analyzer swiftlint-analyzer

test:
	set -o pipefail; xcrun xcodebuild build test -scheme $(CURRENT_TARGET) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

build:
	set -o pipefail; xcrun xcodebuild build -scheme $(CURRENT_TARGET) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" | xcbeautify --renderer github-actions

build-example:
	set -o pipefail; xcrun xcodebuild build -project $(EXAMPLE_PROJECT) -scheme $(EXAMPLE_SCHEME) -sdk "$(EXAMPLE_SDK)" -destination "$(EXAMPLE_DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO | xcbeautify --renderer github-actions

clone-swiftformat:
	@mkdir -p $(BUILD_TOOLS_DIR)
	@if [ ! -d $(SWIFT_FORMAT_DIR) ]; then \
		echo "Cloning SwiftFormat repository..."; \
		git clone --branch $(SWIFT_FORMAT_VERSION) --depth 1 $(SWIFT_FORMAT_REPO) $(SWIFT_FORMAT_DIR); \
	else \
		echo "SwiftFormat repository already exists."; \
	fi

build-swiftformat: clone-swiftformat
	@if [ ! -f $(SWIFT_FORMAT_BIN) ]; then \
		echo "Building swiftformat in $(SWIFT_FORMAT_DIR)"; \
		cd $(SWIFT_FORMAT_DIR) && swift build -c release; \
	else \
		echo "SwiftFormat binary already exists."; \
	fi

force-build-swiftformat: clone-swiftformat
	@echo "Force building swiftformat in $(SWIFT_FORMAT_DIR)"
	cd $(SWIFT_FORMAT_DIR) && swift build -c release

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
