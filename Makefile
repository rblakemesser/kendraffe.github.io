SHELL := /bin/bash

HOST ?= 127.0.0.1
PORT ?= 4000
BASE_URL := http://$(HOST):$(PORT)

BUNDLE_PATH := vendor/bundle
NPM := npm

.PHONY: doctor install build serve open shot ship

doctor:
	@set -euo pipefail; \
	echo "ruby: $$(ruby -v)"; \
	echo "bundler: $$(bundle -v)"; \
	echo "node: $$(node -v)"; \
	echo "npm: $$(npm -v)"; \
	echo "git: $$(git --version)"; \
	branch="$$(git rev-parse --abbrev-ref HEAD)"; \
	if [[ "$$branch" != "master" ]]; then \
	  echo "ERROR: expected branch 'master' (got '$$branch')"; \
	  exit 1; \
	fi; \
	echo "branch: $$branch"; \
	echo "remote: origin -> $$(git remote get-url origin)"

install:
	@set -euo pipefail; \
	echo "==> bundle install (path=$(BUNDLE_PATH))"; \
	BUNDLE_PATH="$(BUNDLE_PATH)" bundle install; \
	if [[ -f package-lock.json ]]; then \
	  echo "==> npm ci"; \
	  $(NPM) ci; \
	else \
	  echo "==> npm install"; \
	  $(NPM) install; \
	fi; \
	echo "==> playwright install chromium"; \
	npx playwright install chromium

build:
	@set -euo pipefail; \
	echo "==> jekyll build"; \
	BUNDLE_PATH="$(BUNDLE_PATH)" bundle exec jekyll build -d _site; \
	if [[ -f CNAME ]]; then \
	  cp CNAME _site/CNAME; \
	fi; \
	echo "built: _site/"

serve:
	@set -euo pipefail; \
	echo "==> jekyll serve $(BASE_URL)"; \
	BUNDLE_PATH="$(BUNDLE_PATH)" bundle exec jekyll serve --host "$(HOST)" --port "$(PORT)"

open:
	@set -euo pipefail; \
	echo "==> open $(BASE_URL)"; \
	open "$(BASE_URL)"

shot:
	@set -euo pipefail; \
	if [[ -z "$${PAGE:-}" ]]; then \
	  echo "ERROR: provide PAGE=/some/page/ (e.g. PAGE=/)"; \
	  exit 1; \
	fi; \
	echo "==> screenshot $(BASE_URL)$${PAGE}"; \
	node tools/shot.mjs --host "$(HOST)" --port "$(PORT)" --path "$${PAGE}"

ship:
	@set -euo pipefail; \
	msg="$${MSG:-chore: update site}"; \
	dry="$${DRY_RUN:-0}"; \
	$(MAKE) build; \
	if [[ "$$dry" == "1" ]]; then \
	  echo "==> DRY_RUN=1: git add/commit/push preview"; \
	  git add -A; \
	  git commit --dry-run -m "$$msg" || true; \
	  git push --dry-run origin master; \
	  exit 0; \
	fi; \
	echo "==> git add -A"; \
	git add -A; \
	if git diff --cached --quiet; then \
	  echo "no changes to commit"; \
	  exit 0; \
	fi; \
	echo "==> git commit"; \
	git commit -m "$$msg"; \
	echo "==> git push origin master"; \
	git push origin master
