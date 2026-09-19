.PHONY: all bootstrap build-engine build-app clean run

all: build-app

bootstrap:
	git submodule update --init --recursive
	./apps/RatexEditor/Scripts/build_libtex.sh

build-engine:
	./apps/RatexEditor/Scripts/build_libtex.sh

build-app: build-engine
	xcodebuild -project apps/RatexEditor/RatexEditor.xcodeproj -scheme RatexEditor -configuration Debug build

run: build-app
	open apps/RatexEditor/RatexEditor.xcodeproj

clean:
	cd vendor/ratex && cargo clean
	xcodebuild -project apps/RatexEditor/RatexEditor.xcodeproj -scheme RatexEditor clean
