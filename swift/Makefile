# Swift 版 Gyaim のビルドとインストール。
#   make          ビルドして build/Gyaim.app を作る
#   make test     変換エンジンのテスト
#   make install  ~/Library/Input Methods に入れて再起動する
APP := build/Gyaim.app
INSTALL_DIR := $(HOME)/Library/Input Methods

.PHONY: app test install clean
app:
	swift build -c release --product Gyaim
	rm -rf build/Gyaim.app
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp "$$(swift build -c release --show-bin-path)/Gyaim" $(APP)/Contents/MacOS/
	cp Info.plist $(APP)/Contents/
	cp ../resources/dict.txt ../resources/candwin.png ../resources/icon.pdf $(APP)/Contents/Resources/
	codesign --force --sign - $(APP)

test:
	swift test

install: app
	-killall Gyaim
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(HOME)/Library/Input Methods/Gyaim.app"
	cp -R $(APP) "$(INSTALL_DIR)/"

clean:
	rm -rf .build build
