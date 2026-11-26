import Foundation

/// 入力中の状態とキー操作。元実装 GyaimController.rb の handleEvent / searchAndShowCands / fix を
/// AppKit から切り離して移植したもの。
public final class Composer {
    public enum Key: Equatable {
        case character(String)
        case space
        case enter
        case backspace
    }

    enum Mode {
        case prefix  // 前方一致で候補を出す
        case exact   // Enter で完全一致に切り替えた
        case google  // Google 変換の結果を表示中
    }

    public private(set) var input = ""
    public private(set) var candidates: [Candidate] = []
    public private(set) var index = 0
    var mode = Mode.prefix

    /// 変換開始時にアプリで選択されていた文字列。確定すると今の読みで個人辞書に登録する。
    public var selectedText: String?

    private let wordSearch: WordSearch
    private let recentCopy: () -> String?

    /// `recentCopy` は直前にコピーされた文字列を返す。古ければ nil を返す。
    public init(wordSearch: WordSearch, recentCopy: @escaping () -> String? = { nil }) {
        self.wordSearch = wordSearch
        self.recentCopy = recentCopy
    }

    public var isComposing: Bool { !input.isEmpty }

    public var current: Candidate? { candidates.indices.contains(index) ? candidates[index] : nil }

    /// 表示中の候補の後ろに続く候補。
    public var following: ArraySlice<Candidate> { candidates.dropFirst(index + 1).prefix(11) }

    public struct Result: Equatable {
        /// キーを IME が消費したか。false ならアプリにそのまま渡す。
        public var handled: Bool
        /// 確定してアプリに挿入する文字列。
        public var commit: String?
        /// 末尾が「.」のとき Google 変換に投げるひらがな。
        public var googleQuery: String?
    }

    public func handle(_ key: Key) -> Result {
        var result = Result(handled: false)
        switch key {
        case .backspace:
            guard isComposing else { break }
            if index > 0 {
                index -= 1
            } else {
                input.removeLast()
                result.googleQuery = refresh()
            }
            result.handled = true
        case .space:
            guard isComposing else { break }
            if index < candidates.count - 1 { index += 1 }
            result.handled = true
        case .enter:
            guard isComposing else { break }
            if mode == .prefix && index == 0 {
                mode = .exact
                result.googleQuery = refresh()
            } else {
                result.commit = fix()
            }
            result.handled = true
        case .character(let c):
            if index > 0 || mode != .prefix { result.commit = fix() }
            input += c
            result.googleQuery = refresh()
            result.handled = true
        }
        return result
    }

    /// 選択中の候補を確定し、学習してから状態を消す。
    public func fix() -> String? {
        defer { reset() }
        guard let cand = current else { return nil }
        if cand.word == selectedText {
            wordSearch.register(word: cand.word, yomi: input)
            selectedText = nil
        } else {
            let yomi = cand.yomi ?? input
            if yomi != "ds" { wordSearch.study(word: cand.word, yomi: yomi) }
        }
        return cand.word
    }

    /// Google 変換の結果を候補にする。
    public func showGoogleCandidates(_ words: [String]) {
        guard isComposing else { return }
        candidates = words.map { Candidate($0) }
        index = 0
        mode = .google
    }

    public func reset() {
        input = ""
        candidates = []
        index = 0
        mode = .prefix
    }

    /// 入力から候補を作り直す。Google 変換が必要なら問い合わせるひらがなを返す。
    private func refresh() -> String? {
        index = 0
        guard isComposing else {
            candidates = []
            return nil
        }
        // 末尾の「.」は Google 変換の合図。辞書は引かず、結果は showGoogleCandidates で届く。
        let google = input.count > 1 && input.hasSuffix(".")
        let found = google ? [] : wordSearch.search(input, exact: mode == .exact)
        let hiragana = RomaKana.toHiragana(input)
        if mode == .exact {
            let katakana = RomaKana.toKatakana(input)
            let kana = [hiragana, katakana].filter { !$0.isEmpty }
            candidates = kana.map { Candidate($0) }
                + found.filter { !kana.contains($0.word) }
        } else {
            var list = [Candidate(input)]
            if let copied = recentCopy(), Self.isUsable(copied) { list.append(Candidate(copied)) }
            if let selected = selectedText, Self.isUsable(selected) { list.append(Candidate(selected)) }
            list += found
            if list.count < 8 { list.append(Candidate(hiragana)) }
            var seen: Set<String> = []
            candidates = list.filter { !$0.word.isEmpty && seen.insert($0.word).inserted }
        }
        return google ? RomaKana.toHiragana(String(input.dropLast())) : nil
    }

    /// 空白だけ・URL・Gyazo の画像ID のような文字列は候補に出さない。
    static func isUsable(_ s: String) -> Bool {
        if s.allSatisfy(\.isWhitespace) || s.hasPrefix("http") { return false }
        return s.range(of: "[0-9a-fA-F]{32}", options: .regularExpression) == nil
    }
}
