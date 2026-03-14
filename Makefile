.PHONY: test lint format fix docc

test:
	swift test

lint:
	swift run --package-path tools swiftlint --fix Sources Tests
	swift run --package-path tools swiftlint lint Sources Tests

format:
	swift run --package-path tools swiftformat Sources Tests

fix: lint format

docc:
	mkdir -p .build/symbol-graphs
	swift build --target ObservationTesting \
		-Xswiftc -emit-symbol-graph \
		-Xswiftc -emit-symbol-graph-dir \
		-Xswiftc .build/symbol-graphs
	xcrun docc convert Sources/ObservationTesting/ObservationTesting.docc \
		--additional-symbol-graph-dir .build/symbol-graphs \
		--output-path docs \
		--transform-for-static-hosting \
		--hosting-base-path swift-observation-testing
