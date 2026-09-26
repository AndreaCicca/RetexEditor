PROJECT           ?= apps/RatexEditor/RatexEditor.xcodeproj
SCHEME            ?= RatexEditor
CONFIGURATION     ?= Debug
DMG_CONFIGURATION ?= Release
DMG_FORMAT        ?= ULMO
DESTINATION       ?= platform=macOS
DIST_DIR          ?= dist
DMG_NAME          ?= $(SCHEME).dmg

.PHONY: all bootstrap build-engine build-app run xcode dmg dng clean clean-app clean-engine

all: build-app

bootstrap:
	git submodule update --init --recursive
	$(MAKE) build-engine

build-engine:
	@if [ ! -f vendor/ratex/Cargo.toml ]; then \
		echo "Submodule vendor/ratex non inizializzato. Eseguo git submodule update..."; \
		git submodule update --init --recursive; \
	fi
	./apps/RatexEditor/Scripts/build_libtex.sh

build-app: build-engine
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' build

# Avvia l'applicazione compilata
run: build-app
	@APP_DIR=$$(xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -showBuildSettings 2>/dev/null | awk -F ' = ' '$$1 ~ /^[[:space:]]*TARGET_BUILD_DIR$$/ { print $$2 }'); \
	if [ -d "$$APP_DIR/$(SCHEME).app" ]; then \
		echo "Avvio di $$APP_DIR/$(SCHEME).app ..."; \
		open "$$APP_DIR/$(SCHEME).app"; \
	else \
		echo "Errore: applicazione non trovata in $$APP_DIR/$(SCHEME).app" >&2; \
		exit 1; \
	fi

# Apre il progetto nell'IDE Xcode senza compilare prima
xcode:
	open $(PROJECT)

# Crea l'immagine disco (.dmg) ottimizzata in Release con l'app e il collegamento ad Applications
dmg:
	@$(MAKE) build-app CONFIGURATION=$(DMG_CONFIGURATION)
	@mkdir -p $(DIST_DIR)
	@APP_DIR=$$(xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(DMG_CONFIGURATION) -showBuildSettings 2>/dev/null | awk -F ' = ' '$$1 ~ /^[[:space:]]*TARGET_BUILD_DIR$$/ { print $$2 }'); \
	APP_PATH="$$APP_DIR/$(SCHEME).app"; \
	if [ ! -d "$$APP_PATH" ]; then \
		echo "Errore: applicazione non trovata in $$APP_PATH" >&2; \
		exit 1; \
	fi; \
	DMG_TEMP=$$(mktemp -d /tmp/dmg-build-XXXXXX); \
	echo "Preparazione cartella DMG ($(DMG_CONFIGURATION)) in $$DMG_TEMP ..."; \
	cp -R "$$APP_PATH" "$$DMG_TEMP/"; \
	ln -s /Applications "$$DMG_TEMP/Applications"; \
	ICON_PATH="$$APP_PATH/Contents/Resources/AppIcon.icns"; \
	if [ ! -f "$$ICON_PATH" ]; then \
		ICON_PATH="apps/RatexEditor/RatexEditor/Resources/AppIcon.icns"; \
	fi; \
	if [ -f "$$ICON_PATH" ]; then \
		cp "$$ICON_PATH" "$$DMG_TEMP/.VolumeIcon.icns"; \
		SetFile -c icns "$$DMG_TEMP/.VolumeIcon.icns" 2>/dev/null || true; \
		SetFile -a C "$$DMG_TEMP" 2>/dev/null || true; \
	fi; \
	echo "Generazione di $(DIST_DIR)/$(DMG_NAME) con diskutil ($(DMG_FORMAT)) ..."; \
	rm -f "$(DIST_DIR)/$(DMG_NAME)"; \
	diskutil image create from --volumeName "$(SCHEME)" --format $(DMG_FORMAT) "$$DMG_TEMP" "$(DIST_DIR)/$(DMG_NAME)"; \
	rm -rf "$$DMG_TEMP"; \
	if [ -f "$$ICON_PATH" ]; then \
		swift -e 'import Cocoa; _ = NSWorkspace.shared.setIcon(NSImage(contentsOfFile: CommandLine.arguments[1]), forFile: CommandLine.arguments[2], options: [])' "$$ICON_PATH" "$(DIST_DIR)/$(DMG_NAME)" 2>/dev/null || true; \
	fi; \
	echo "✅ Immagine disco creata con successo: $(DIST_DIR)/$(DMG_NAME)"

# Alias per digitazione 'make dng'
dng: dmg

# Pulisce solo gli artefatti Xcode e la cartella di distribuzione
clean-app:
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' clean
	rm -rf $(DIST_DIR)

# Pulisce gli artefatti del motore Rust (richiede ricompilazione completa)
clean-engine:
	@[ -f vendor/ratex/Cargo.toml ] && cargo clean --manifest-path vendor/ratex/Cargo.toml || true

# Pulisce sia l'app che il motore Rust
clean: clean-app clean-engine
