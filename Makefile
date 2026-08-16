SHELL=/bin/bash

BUILD_TOOLS_DIR=./BuildTools

PACKAGE_SCHEME ?= QuranEngine-Package
PACKAGE_SDK ?= iphonesimulator
PACKAGE_DESTINATION ?= name=iPhone 17e,OS=26.5
EXAMPLE_PROJECT ?= Example/QuranEngineApp.xcodeproj
EXAMPLE_SCHEME ?= QuranEngineApp
EXAMPLE_SDK ?= iphonesimulator
EXAMPLE_DESTINATION ?= generic/platform=iOS
EXAMPLE_BUNDLE_IDENTIFIER ?= com.quran.QuranEngineApp
EXAMPLE_NO_SYNC_SIMULATOR ?= iPhone 17e,26.5
EXAMPLE_SYNC_SIMULATOR ?= iPhone 17 Pro Max,26.5
DERIVED_DATA_DIR ?= .build/DerivedData
GIT_COMMON_DIR := $(shell git rev-parse --path-format=absolute --git-common-dir)
QURAN_WORKSPACE_DIR := $(abspath $(GIT_COMMON_DIR)/../..)
MOBILE_SYNC_DIR ?= $(QURAN_WORKSPACE_DIR)/mobile-sync
MOBILE_SYNC_SPM_PATH ?= $(QURAN_WORKSPACE_DIR)/mobile-sync-spm
MOBILE_SYNC_CONFIGURATION ?= debug
MOBILE_SYNC_XCFRAMEWORK_PATH ?= ../mobile-sync/umbrella/build/XCFrameworks/$(MOBILE_SYNC_CONFIGURATION)/Shared.xcframework
MOBILE_SYNC_XCFRAMEWORK_OUTPUT ?= $(MOBILE_SYNC_DIR)/umbrella/build/XCFrameworks/$(MOBILE_SYNC_CONFIGURATION)/Shared.xcframework
MOBILE_SYNC_SPM_SCHEME ?= MobileSync
MOBILE_SYNC_SPM_SDK ?= iphonesimulator
MOBILE_SYNC_SPM_DESTINATION ?= generic/platform=iOS Simulator
MOBILE_SYNC_SPM_DERIVED_DATA ?= .build/DerivedData/local-$(MOBILE_SYNC_CONFIGURATION)
MOBILE_SYNC_HTTP_LOG_LEVEL ?= ALL
QURAN_OAUTH_CLIENT_ID ?=

SWIFT_FORMAT_REPO=https://github.com/nicklockwood/SwiftFormat
SWIFT_FORMAT_VERSION=0.62.1
SWIFT_FORMAT_DIR=$(BUILD_TOOLS_DIR)/SwiftFormat
SWIFT_FORMAT_BIN=$(SWIFT_FORMAT_DIR)/.build/release/swiftformat
SWIFT_FORMAT_VERSION_FILE=$(abspath $(SWIFT_FORMAT_DIR))/.swiftformat-version

BUILD_SCHEME=$(if $(TARGET),$(TARGET),$(PACKAGE_SCHEME))
TEST_TARGET=$(if $(TARGET),$(if $(filter %Tests,$(TARGET)),$(TARGET),$(TARGET)Tests))
TEST_FILTER=$(if $(TEST_TARGET),-only-testing:$(TEST_TARGET))
WITHOUT_QURAN_SYNC=set -o pipefail; env QURAN_SYNC=
WITH_QURAN_SYNC=set -o pipefail; env QURAN_SYNC=QURAN_SYNC
WITH_LOCAL_MOBILE_SYNC=set -o pipefail; env MOBILE_SYNC_XCFRAMEWORK_PATH="$(MOBILE_SYNC_XCFRAMEWORK_PATH)"
WITH_LOCAL_QURAN_SYNC=set -o pipefail; env QURAN_SYNC=QURAN_SYNC MOBILE_SYNC_SPM_PATH="$(MOBILE_SYNC_SPM_PATH)" MOBILE_SYNC_XCFRAMEWORK_PATH="$(MOBILE_SYNC_XCFRAMEWORK_PATH)"
WITHOUT_QURAN_SYNC_DERIVED_DATA=$(DERIVED_DATA_DIR)/no-sync
WITH_QURAN_SYNC_DERIVED_DATA=$(DERIVED_DATA_DIR)/sync
WITH_LOCAL_QURAN_SYNC_DERIVED_DATA=$(DERIVED_DATA_DIR)/sync-local-$(MOBILE_SYNC_CONFIGURATION)
WITH_QURAN_SYNC_APP_SWIFT_FLAGS='OTHER_SWIFT_FLAGS=$$(inherited) -D QURAN_SYNC'
WHATS_NEW_LAUNCH_ARGUMENTS=-whats-new.seen-version 0
LOCAL_SYNC_SIMULATOR_ENV=env SIMCTL_CHILD_MOBILE_SYNC_HTTP_LOG_LEVEL="$(MOBILE_SYNC_HTTP_LOG_LEVEL)" $(if $(QURAN_OAUTH_CLIENT_ID),SIMCTL_CHILD_QURAN_OAUTH_CLIENT_ID="$(QURAN_OAUTH_CLIENT_ID)")
comma := ,
simulator-os = $(lastword $(subst $(comma), ,$(1)))
simulator-name = $(subst $(comma)$(call simulator-os,$(1)),,$(1))
simulator-destination = platform=iOS Simulator,name=$(call simulator-name,$(1)),OS=$(call simulator-os,$(1))

define run-example-app
	@simulator="$$(xcrun simctl list devices "iOS $(call simulator-os,$(1))" | grep -F "    $(call simulator-name,$(1)) (" | sed -nE 's/.*\(([[:xdigit:]-]{36})\).*/\1/p' | head -n 1)"; \
	if [ -z "$$simulator" ]; then \
		echo "$(call simulator-name,$(1)) with iOS $(call simulator-os,$(1)) is not available." >&2; \
		exit 1; \
	fi; \
	if ! xcrun simctl list devices booted | grep -Fq "$$simulator"; then \
		xcrun simctl boot "$$simulator"; \
	fi; \
	open -a Simulator --args -CurrentDeviceUDID "$$simulator"; \
	xcrun simctl bootstatus "$$simulator" -b; \
	xcrun simctl install "$$simulator" "$(2)/Build/Products/Debug-iphonesimulator/$(EXAMPLE_SCHEME).app"; \
	if [ -n "$(strip $(3))" ]; then \
		xcrun simctl terminate "$$simulator" "$(EXAMPLE_BUNDLE_IDENTIFIER)" >/dev/null 2>&1 || true; \
	fi; \
	$(4) xcrun simctl launch "$$simulator" "$(EXAMPLE_BUNDLE_IDENTIFIER)" $(3)
endef

.PHONY: test-no-sync test-sync
.PHONY: build-no-sync build-sync
.PHONY: build-example-no-sync build-example-sync
.PHONY: run-example-no-sync run-example-sync run-example-no-sync-whats-new run-example-sync-whats-new
.PHONY: build-mobile-sync-spm build-sync-local-debug test-sync-local-debug
.PHONY: build-example-sync-local-debug run-example-sync-local-debug
.PHONY: clone-swiftformat build-swiftformat force-build-swiftformat clean-swiftformat format-lint format-autocorrect lint-no-kotlin-interop
.PHONY: install-swiftlint build-for-analyzer swiftlint-analyzer

test-no-sync:
	$(WITHOUT_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITHOUT_QURAN_SYNC_DERIVED_DATA)" build test -scheme "$(PACKAGE_SCHEME)" $(TEST_FILTER) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

test-sync:
	$(WITH_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITH_QURAN_SYNC_DERIVED_DATA)" build test -scheme "$(PACKAGE_SCHEME)" $(TEST_FILTER) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

build-no-sync:
	$(WITHOUT_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITHOUT_QURAN_SYNC_DERIVED_DATA)" build -scheme "$(BUILD_SCHEME)" -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

build-sync:
	$(WITH_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITH_QURAN_SYNC_DERIVED_DATA)" build -scheme "$(BUILD_SCHEME)" -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

build-mobile-sync-spm:
	@test -d "$(MOBILE_SYNC_DIR)" || { echo "mobile-sync not found at $(MOBILE_SYNC_DIR)" >&2; exit 1; }
	@test -n "$(MOBILE_SYNC_SPM_PATH)" || { echo "MOBILE_SYNC_SPM_PATH is required" >&2; exit 1; }
	@test -d "$(MOBILE_SYNC_SPM_PATH)" || { echo "mobile-sync-spm not found at $(MOBILE_SYNC_SPM_PATH)" >&2; exit 1; }
	@test -n "$(MOBILE_SYNC_XCFRAMEWORK_PATH)" || { echo "MOBILE_SYNC_XCFRAMEWORK_PATH is required" >&2; exit 1; }
	cd "$(MOBILE_SYNC_DIR)" && ./gradlew :umbrella:assembleSharedDebugXCFramework
	@test -d "$(MOBILE_SYNC_XCFRAMEWORK_OUTPUT)" || { echo "XCFramework not found at $(MOBILE_SYNC_XCFRAMEWORK_OUTPUT)" >&2; exit 1; }
	cd "$(MOBILE_SYNC_SPM_PATH)" && ( $(WITH_LOCAL_MOBILE_SYNC) xcrun xcodebuild -derivedDataPath "$(MOBILE_SYNC_SPM_DERIVED_DATA)" build -scheme "$(MOBILE_SYNC_SPM_SCHEME)" -sdk "$(MOBILE_SYNC_SPM_SDK)" -destination "$(MOBILE_SYNC_SPM_DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | xcbeautify --renderer github-actions )

build-sync-local-debug: build-mobile-sync-spm
	$(WITH_LOCAL_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITH_LOCAL_QURAN_SYNC_DERIVED_DATA)" build -scheme "$(BUILD_SCHEME)" -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

test-sync-local-debug: build-mobile-sync-spm
	$(WITH_LOCAL_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITH_LOCAL_QURAN_SYNC_DERIVED_DATA)" build test -scheme "$(PACKAGE_SCHEME)" $(TEST_FILTER) -sdk "$(PACKAGE_SDK)" -destination "$(PACKAGE_DESTINATION)" 2>&1 | xcbeautify --renderer github-actions

build-example-no-sync:
	$(WITHOUT_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITHOUT_QURAN_SYNC_DERIVED_DATA)" build -project $(EXAMPLE_PROJECT) -scheme $(EXAMPLE_SCHEME) -sdk "$(EXAMPLE_SDK)" -destination "$(EXAMPLE_DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO 2>&1 | xcbeautify --renderer github-actions

build-example-sync:
	$(WITH_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITH_QURAN_SYNC_DERIVED_DATA)" build -project $(EXAMPLE_PROJECT) -scheme $(EXAMPLE_SCHEME) -sdk "$(EXAMPLE_SDK)" -destination "$(EXAMPLE_DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO $(WITH_QURAN_SYNC_APP_SWIFT_FLAGS) 2>&1 | xcbeautify --renderer github-actions

build-example-sync-local-debug: build-mobile-sync-spm
	$(WITH_LOCAL_QURAN_SYNC) xcrun xcodebuild -derivedDataPath "$(WITH_LOCAL_QURAN_SYNC_DERIVED_DATA)" build -project $(EXAMPLE_PROJECT) -scheme $(EXAMPLE_SCHEME) -sdk "$(EXAMPLE_SDK)" -destination "$(EXAMPLE_DESTINATION)" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO $(WITH_QURAN_SYNC_APP_SWIFT_FLAGS) 2>&1 | xcbeautify --renderer github-actions

run-example-no-sync: EXAMPLE_DESTINATION = $(call simulator-destination,$(EXAMPLE_NO_SYNC_SIMULATOR))
run-example-sync: EXAMPLE_DESTINATION = $(call simulator-destination,$(EXAMPLE_SYNC_SIMULATOR))
run-example-no-sync-whats-new: EXAMPLE_DESTINATION = $(call simulator-destination,$(EXAMPLE_NO_SYNC_SIMULATOR))
run-example-sync-whats-new: EXAMPLE_DESTINATION = $(call simulator-destination,$(EXAMPLE_SYNC_SIMULATOR))
run-example-sync-local-debug: EXAMPLE_DESTINATION = $(call simulator-destination,$(EXAMPLE_SYNC_SIMULATOR))

run-example-no-sync: build-example-no-sync
	$(call run-example-app,$(EXAMPLE_NO_SYNC_SIMULATOR),$(WITHOUT_QURAN_SYNC_DERIVED_DATA))

run-example-sync: build-example-sync
	$(call run-example-app,$(EXAMPLE_SYNC_SIMULATOR),$(WITH_QURAN_SYNC_DERIVED_DATA))

run-example-sync-local-debug: build-example-sync-local-debug
	$(call run-example-app,$(EXAMPLE_SYNC_SIMULATOR),$(WITH_LOCAL_QURAN_SYNC_DERIVED_DATA),,$(LOCAL_SYNC_SIMULATOR_ENV))

run-example-no-sync-whats-new: build-example-no-sync
	$(call run-example-app,$(EXAMPLE_NO_SYNC_SIMULATOR),$(WITHOUT_QURAN_SYNC_DERIVED_DATA),$(WHATS_NEW_LAUNCH_ARGUMENTS))

run-example-sync-whats-new: build-example-sync
	$(call run-example-app,$(EXAMPLE_SYNC_SIMULATOR),$(WITH_QURAN_SYNC_DERIVED_DATA),$(WHATS_NEW_LAUNCH_ARGUMENTS))

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

lint-no-kotlin-interop:
	@matches="$$(git grep --line-number --extended-regexp '(^|[[:space:]])import[[:space:]]+KMPNativeCoroutines|(^|[^[:alnum:]_])(asyncFunction|asyncSequence)[[:space:]]*\(' -- '*.swift' || true)"; \
	if [ -n "$$matches" ]; then \
		echo "$$matches"; \
		echo "error: Direct Kotlin coroutine interop is forbidden in QuranEngine Swift sources." >&2; \
		echo "Use the Swift-native async APIs exposed by MobileSync; add missing wrappers upstream." >&2; \
		exit 1; \
	fi

format-lint: lint-no-kotlin-interop $(SWIFT_FORMAT_BIN)
	$(SWIFT_FORMAT_BIN) --lint .

format-autocorrect: $(SWIFT_FORMAT_BIN)
	$(SWIFT_FORMAT_BIN) .

$(SWIFT_FORMAT_BIN): build-swiftformat

install-swiftlint:
	brew install swiftlint

build-for-analyzer:
	xcrun xcodebuild clean build -scheme QuranEngine-Package -sdk "iphonesimulator" -destination "$(PACKAGE_DESTINATION)" > .build/xcodebuild.log

swiftlint-analyzer:
	swiftlint analyze --strict  --quiet --compiler-log-path .build/xcodebuild.log
