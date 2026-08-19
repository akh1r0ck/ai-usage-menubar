.PHONY: build build-codex build-claude check clean

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

clean:
	rm -rf dist
