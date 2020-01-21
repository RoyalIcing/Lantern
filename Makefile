.PHONY: update
update:
	carthage update --platform OSX

.PHONY: test
test:
	xcodebuild test -scheme "Lantern Model"
