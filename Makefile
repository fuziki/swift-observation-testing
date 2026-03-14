.PHONY: test lint format fix

test:
	swift test

lint:
	swift run --package-path tools swiftlint --fix Sources Tests
	swift run --package-path tools swiftlint lint Sources Tests

format:
	swift run --package-path tools swiftformat Sources Tests

fix: lint format
