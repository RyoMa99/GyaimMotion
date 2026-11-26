import Cocoa
import GyaimCore
import InputMethodKit

/// 辞書と候補ウィンドウはプロセスに1つだけ持ち、入力先アプリごとのコントローラで共有する。
enum Shared {
    static let directory: URL = {
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gyaim")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let wordSearch = WordSearch(
        connectionDict: try! ConnectionDict(path: Bundle.main.path(forResource: "dict", ofType: "txt")!),
        localDictURL: directory.appendingPathComponent("localdict.txt"),
        studyDictURL: directory.appendingPathComponent("studydict.txt")
    )

    static let window = CandidateWindow()
    static let clipboard = Clipboard()
}

/// 直前にコピーされた文字列を覚えておく。コピーから5秒以内だけ候補に出す。
final class Clipboard {
    private var changeCount = NSPasteboard.general.changeCount
    private var copiedAt = Date.distantPast

    func recent() -> String? {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != changeCount {
            changeCount = pasteboard.changeCount
            copiedAt = Date()
        }
        guard Date().timeIntervalSince(copiedAt) < 5 else { return nil }
        return pasteboard.string(forType: .string)
    }
}

@objc(GyaimController)
final class GyaimController: IMKInputController {
    private let composer = Composer(wordSearch: Shared.wordSearch, recentCopy: { Shared.clipboard.recent() })

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        _ = Shared.clipboard.recent()
    }

    override func deactivateServer(_ sender: Any!) {
        commitComposition(sender)
        Shared.window.orderOut(nil)
        Shared.wordSearch.saveStudyDict()
        super.deactivateServer(sender)
    }

    override func commitComposition(_ sender: Any!) {
        guard let client = sender as? IMKTextInput ?? client() else { return }
        if let word = composer.fix() { insert(word, into: client) }
        update(client)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, event.type == .keyDown, let client = sender as? IMKTextInput else { return false }
        // かなキー・英数キーは何もしない
        if event.keyCode == 102 || event.keyCode == 104 { return true }

        if !composer.isComposing, let selected = selectedText(in: client) { composer.selectedText = selected }

        guard let key = key(for: event) else { return false }
        let result = composer.handle(key)
        if let commit = result.commit { insert(commit, into: client) }
        if let query = result.googleQuery {
            Google.transliterate(query) { [weak self] words in
                guard let self, self.composer.input.hasSuffix(".") else { return }
                self.composer.showGoogleCandidates(words)
                self.update(client)
            }
        }
        update(client)
        return result.handled
    }

    private func key(for event: NSEvent) -> Composer.Key? {
        guard let chars = event.characters, let scalar = chars.unicodeScalars.first else { return nil }
        switch scalar.value {
        case 0x08, 0x7f, 0x1b: return .backspace
        case 0x20: return .space
        case 0x0a, 0x0d: return .enter
        case 0x21...0x7e where event.modifierFlags.isDisjoint(with: [.control, .command, .option]):
            return .character(chars)
        default: return nil
        }
    }

    private func selectedText(in client: IMKTextInput) -> String? {
        let range = client.selectedRange()
        guard range.location != NSNotFound, range.length > 0 else { return nil }
        return client.attributedSubstring(from: range)?.string
    }

    private func insert(_ word: String, into client: IMKTextInput) {
        client.insertText(word, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
    }

    /// 選択中の候補を下線つきで表示し、続く候補をウィンドウに並べる。
    private func update(_ client: IMKTextInput) {
        guard composer.isComposing, let word = composer.current?.word else {
            client.setMarkedText("", selectionRange: NSRange(location: 0, length: 0),
                                 replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
            Shared.window.orderOut(nil)
            return
        }
        let range = NSRange(location: 0, length: (word as NSString).length)
        let style = mark(forStyle: kTSMHiliteRawText, at: range) ?? [:]
        let attributes = Dictionary(uniqueKeysWithValues: style.compactMap { key, value in
            (key as? String).map { (NSAttributedString.Key($0), value) }
        })
        client.setMarkedText(NSAttributedString(string: word, attributes: attributes),
                             selectionRange: NSRange(location: range.length, length: 0),
                             replacementRange: NSRange(location: NSNotFound, length: NSNotFound))

        var lineRect = NSRect.zero
        client.attributes(forCharacterIndex: 0, lineHeightRectangle: &lineRect)
        Shared.window.show(composer.following.map(\.word), below: lineRect)
    }
}
