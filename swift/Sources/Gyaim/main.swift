import Cocoa
import InputMethodKit

// 入力メソッドサーバを立ち上げる。接続名は Info.plist の InputMethodConnectionName と一致させる。
let server = IMKServer(name: "Gyaim_Connection", bundleIdentifier: Bundle.main.bundleIdentifier)
_ = server
NSApplication.shared.run()
