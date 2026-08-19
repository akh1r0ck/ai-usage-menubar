.PHONY: build build-codex build-claude check render-settings clean

build: build-codex build-claude

build-codex:
	./scripts/build-app.sh

build-claude:
	./scripts/build-claude-app.sh

check: build
	plutil -lint "dist/ChatGPT Usage.app/Contents/Info.plist"
	plutil -lint "dist/Claude Usage.app/Contents/Info.plist"
	file "dist/ChatGPT Usage.app/Contents/MacOS/ChatGPTUsage"
	file "dist/Claude Usage.app/Contents/MacOS/ClaudeUsage"
	codesign --verify --deep --verbose=2 "dist/ChatGPT Usage.app"
	codesign --verify --deep --verbose=2 "dist/Claude Usage.app"
	./scripts/test-claude-statusline.sh
	./scripts/test-claude-usage.sh
	./scripts/test-settings.sh
	./scripts/test-providers.sh
	test "$$(sips -g pixelWidth docs/images/settings-window.png | tail -1 | awk '{print $$2}')" = "620"
	test "$$(sips -g pixelWidth docs/images/settings-window-dark.png | tail -1 | awk '{print $$2}')" = "620"

render-settings:
	./scripts/render-settings.sh

clean:
	rm -rf dist
