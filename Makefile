.PHONY: app run install release test clean

VERSION := $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)

app:
	./scripts/build-app.sh

# GitHub Releases に添付する zip を作る（Finder の圧縮だと署名が壊れることがあるので ditto）
release: app
	rm -f build/FreeSlots-$(VERSION).zip
	ditto -c -k --keepParent build/FreeSlots.app build/FreeSlots-$(VERSION).zip
	@echo "==> build/FreeSlots-$(VERSION).zip"

run: app
	-pkill -x FreeSlots
	open build/FreeSlots.app

install: app
	-pkill -x FreeSlots
	rm -rf /Applications/FreeSlots.app
	cp -R build/FreeSlots.app /Applications/
	open /Applications/FreeSlots.app

test:
	swift test

clean:
	rm -rf .build build
