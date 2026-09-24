.PHONY: app run install test clean

app:
	./scripts/build-app.sh

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
