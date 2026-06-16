.PHONY: help crawl\:all crawl\:missing check\:i18n

help:
	@echo "Available commands:"
	@echo "  make crawl:all       - Crawl all historical lottery draws"
	@echo "  make crawl:missing   - Crawl missing lottery draws (incrementally)"
	@echo "  make check:i18n      - Validate/sync translation keys between vi.json and en.json"

crawl\:all:
	dart run bin/crawl.dart all

crawl\:missing:
	dart run bin/crawl.dart missing

check\:i18n:
	dart run bin/check_i18n.dart
