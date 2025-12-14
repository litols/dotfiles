.PHONY: help lint format lint-sh format-sh lint-yaml format-yaml format-json format-toml format-md format-lua

# Default target
help:
	@echo "Available targets:"
	@echo "  make lint        - Run all linters"
	@echo "  make format      - Run all formatters"
	@echo "  make lint-sh     - Lint shell scripts"
	@echo "  make format-sh   - Format shell scripts"
	@echo "  make lint-yaml   - Lint YAML files"
	@echo "  make format-yaml - Format YAML files"
	@echo "  make format-json - Format JSON files"
	@echo "  make format-toml - Format TOML files"
	@echo "  make format-md   - Format Markdown files"
	@echo "  make format-lua  - Format Lua files"

# Run all linters
lint: lint-sh lint-yaml

# Run all formatters (check mode)
format: format-sh format-yaml format-json format-toml format-md format-lua

# Shell script linting and formatting
# Note: .tmpl files are excluded because they contain template syntax that shellcheck/shfmt can't parse
SHELL_FILES := $(shell find . -type f \( -name "*.sh" -o -name "*.zsh" \) ! -name "*.tmpl" ! -path "./.git/*")
ZSHRC_FILES := dot_zshrc

lint-sh:
	@echo "Linting shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		for file in $(SHELL_FILES) $(ZSHRC_FILES); do \
			if [ -f "$$file" ]; then \
				echo "Checking $$file"; \
				shellcheck -x "$$file" || exit 1; \
			fi; \
		done; \
	else \
		echo "shellcheck not found. Install with: brew install shellcheck"; \
		exit 1; \
	fi

format-sh:
	@echo "Formatting shell scripts..."
	@if command -v shfmt >/dev/null 2>&1; then \
		for file in $(SHELL_FILES) $(ZSHRC_FILES); do \
			if [ -f "$$file" ]; then \
				echo "Formatting $$file"; \
				shfmt -i 2 -ci -bn -w "$$file"; \
			fi; \
		done; \
	else \
		echo "shfmt not found. Install with: brew install shfmt"; \
		exit 1; \
	fi

# YAML linting and formatting
YAML_FILES := $(shell find . -type f \( -name "*.yml" -o -name "*.yaml" \) ! -path "./.git/*")

lint-yaml:
	@echo "Linting YAML files..."
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --check $(YAML_FILES); \
	else \
		echo "prettier not found. Install with: npm install -g prettier"; \
		exit 1; \
	fi

format-yaml:
	@echo "Formatting YAML files..."
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --write $(YAML_FILES); \
	else \
		echo "prettier not found. Install with: npm install -g prettier"; \
		exit 1; \
	fi

# JSON formatting
JSON_FILES := $(shell find . -type f -name "*.json" ! -path "./.git/*")

format-json:
	@echo "Formatting JSON files..."
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --write $(JSON_FILES); \
	else \
		echo "prettier not found. Install with: npm install -g prettier"; \
		exit 1; \
	fi

# TOML formatting
TOML_FILES := $(shell find . -type f -name "*.toml" ! -path "./.git/*")

format-toml:
	@echo "Formatting TOML files..."
	@if command -v taplo >/dev/null 2>&1; then \
		taplo format $(TOML_FILES); \
	else \
		echo "taplo not found. Install with: brew install taplo"; \
		exit 1; \
	fi

# Markdown formatting
MD_FILES := $(shell find . -type f -name "*.md" ! -path "./.git/*")

format-md:
	@echo "Formatting Markdown files..."
	@if command -v prettier >/dev/null 2>&1; then \
		prettier --write $(MD_FILES); \
	else \
		echo "prettier not found. Install with: npm install -g prettier"; \
		exit 1; \
	fi

# Lua formatting
LUA_FILES := $(shell find . -type f -name "*.lua" -o -name "*.lua.tmpl" ! -path "./.git/*")

format-lua:
	@echo "Formatting Lua files..."
	@if command -v stylua >/dev/null 2>&1; then \
		stylua $(LUA_FILES); \
	else \
		echo "stylua not found. Install with: brew install stylua"; \
		exit 1; \
	fi
