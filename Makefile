BUILD_TOOLS_DIR=./BuildTools

SWIFTFORMAT_REPO=https://github.com/nicklockwood/SwiftFormat
SWIFTFORMAT_VERSION=0.54.3
SWIFTFORMAT_DIR=$(BUILD_TOOLS_DIR)/SwiftFormat
SWIFTFORMAT_BIN=$(SWIFTFORMAT_DIR)/.build/release/swiftformat

clone-swiftformat:
	@mkdir -p $(BUILD_TOOLS_DIR)
	@if [ ! -d $(SWIFTFORMAT_DIR) ]; then \
		echo "Cloning SwiftFormat repository..."; \
		git clone --branch $(SWIFTFORMAT_VERSION) --depth 1 $(SWIFTFORMAT_REPO) $(SWIFTFORMAT_DIR); \
	else \
		echo "SwiftFormat repository already exists."; \
	fi

build-swiftformat: clone-swiftformat
	@if [ ! -f $(SWIFTFORMAT_BIN) ]; then \
		echo "Building swiftformat in $(SWIFTFORMAT_DIR)"; \
		cd $(SWIFTFORMAT_DIR) && swift build -c release; \
	else \
		echo "SwiftFormat binary already exists."; \
	fi

force-build-swiftformat: clone-swiftformat
	@echo "Force building swiftformat in $(SWIFTFORMAT_DIR)"
	cd $(SWIFTFORMAT_DIR) && swift build -c release

clean-swiftformat:
	@rm -rf $(SWIFTFORMAT_DIR)/.build

format-lint: $(SWIFTFORMAT_BIN)
	$(SWIFTFORMAT_BIN) --lint .

format-autocorrect: $(SWIFTFORMAT_BIN)
	$(SWIFTFORMAT_BIN) .

$(SWIFTFORMAT_BIN): build-swiftformat
