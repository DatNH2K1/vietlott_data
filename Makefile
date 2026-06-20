.PHONY: help crawl\:all crawl\:missing check\:i18n optimize

help:
	@echo "Available commands:"
	@echo "  make crawl:all       - Crawl all historical lottery draws"
	@echo "  make crawl:missing   - Crawl missing lottery draws (incrementally)"
	@echo "  make check:i18n      - Validate/sync translation keys between vi.json and en.json"
	@echo "  make optimize        - Optimize weights in suggestion_config.dart based on crawl data"

crawl\:all:
	dart run bin/crawl.dart all

crawl\:missing:
	dart run bin/crawl.dart missing

check\:i18n:
	dart run bin/check_i18n.dart

optimize:
	flutter test test/optimize_weights_test.dart

