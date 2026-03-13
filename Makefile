.PHONY: test lint format

test:
	swift test

lint:
	swift run --package-path tools swiftlint lint Sources Tests

format:
	swift run --package-path tools swiftformat Sources Tests
