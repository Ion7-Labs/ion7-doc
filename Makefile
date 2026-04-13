## ion7-doc — documentation generator and deployer

# GitHub organisation (used for auto-clone URLs)
GITHUB_ORG  ?= ion7-labs

# Local output for development builds
DOCS_OUT    ?= $(abspath docs)

# Sibling repos — auto-cloned by "make pages" if not present
GRAMMAR_DIR ?= $(abspath ../ion7-grammar)
PAGES_DIR   ?= $(abspath ../ion7-labs.github.io)

.PHONY: core grammar all docs pages clean help

help:
	@echo "ion7-doc targets:"
	@echo "  make core     Generate ion7-core docs   → $(DOCS_OUT)/core/"
	@echo "  make grammar  Generate ion7-grammar docs → $(DOCS_OUT)/grammar/"
	@echo "  make all      Generate all docs + portal → $(DOCS_OUT)/"
	@echo "  make pages    Deploy all docs to GitHub Pages (auto-clones repos)"
	@echo ""
	@echo "Variables:"
	@echo "  GITHUB_ORG=$(GITHUB_ORG)"
	@echo "  GRAMMAR_DIR=$(GRAMMAR_DIR)"
	@echo "  PAGES_DIR=$(PAGES_DIR)"

# ── Local builds ──────────────────────────────────────────────────────────────

core:
	luajit bin/gendoc.lua core $(DOCS_OUT)

grammar:
	luajit bin/gendoc.lua grammar $(DOCS_OUT)

# "make all" / "make docs" — core + grammar + docs/index.html portal
all docs:
	luajit bin/gendoc.lua all $(DOCS_OUT)

# ── Deploy to GitHub Pages ────────────────────────────────────────────────────

pages:
	@# Clone ion7-grammar if not present (needed for grammar docs)
	@if [ ! -d "$(GRAMMAR_DIR)" ]; then \
	  echo "[ion7-doc] cloning ion7-grammar..."; \
	  git clone https://github.com/$(GITHUB_ORG)/ion7-grammar.git "$(GRAMMAR_DIR)"; \
	fi
	@# Clone ion7-labs.github.io if not present
	@if [ ! -d "$(PAGES_DIR)" ]; then \
	  echo "[ion7-doc] cloning ion7-labs.github.io..."; \
	  git clone https://github.com/$(GITHUB_ORG)/ion7-labs.github.io.git "$(PAGES_DIR)"; \
	fi
	@# Wipe previously generated content (keep LICENSE, README, CNAME, etc.)
	@rm -rf "$(PAGES_DIR)/api.html" "$(PAGES_DIR)/core" "$(PAGES_DIR)/grammar" "$(PAGES_DIR)/index.html"
	@# Generate core + grammar + portal index.html
	@luajit bin/gendoc.lua all "$(PAGES_DIR)"
	@# Commit and push
	@cd "$(PAGES_DIR)" && \
	  git add -A && \
	  git commit -m "docs: regenerate $$(date +%Y-%m-%d)" && \
	  git push
	@echo "[ion7-doc] deployed → $(PAGES_DIR)"

# ── Clean local output ────────────────────────────────────────────────────────

clean:
	rm -rf $(DOCS_OUT)/core $(DOCS_OUT)/grammar $(DOCS_OUT)/api.html $(DOCS_OUT)/index.html
