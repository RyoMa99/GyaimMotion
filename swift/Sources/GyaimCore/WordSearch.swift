import Foundation

/// 変換候補。`yomi` が nil の候補は辞書由来ではない (入力そのもの、ひらがな、コピー文字列など)。
public struct Candidate: Equatable {
    public let word: String
    public let yomi: String?

    public init(_ word: String, yomi: String? = nil) {
        self.word = word
        self.yomi = yomi
    }
}

/// 辞書の1行。「読み<TAB>単語」で保存する。
struct DictEntry: Equatable {
    let yomi: String
    let word: String
}

/// 学習辞書・個人辞書・接続辞書をまとめて検索する。元実装 WordSearch.rb を移植。
public final class WordSearch {
    private let connectionDict: ConnectionDict
    private let localDictURL: URL
    private let studyDictURL: URL
    private var localDict: [DictEntry]
    private var localDictDate: Date?
    private var studyDict: [DictEntry]
    private let studyDictLimit = 1000

    public init(connectionDict: ConnectionDict, localDictURL: URL, studyDictURL: URL) {
        self.connectionDict = connectionDict
        self.localDictURL = localDictURL
        self.studyDictURL = studyDictURL
        localDict = Self.load(localDictURL)
        localDictDate = Self.modificationDate(localDictURL)
        studyDict = Self.load(studyDictURL)
    }

    /// `exact` が false なら前方一致、true なら完全一致。
    public func search(_ q: String, exact: Bool, limit: Int = 10) -> [Candidate] {
        guard !q.isEmpty else { return [] }
        reloadLocalDictIfChanged()

        if q == "ds" {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            return [Candidate(formatter.string(from: Date()))]
        }
        if q.contains(where: { $0.isUppercase }) {
            return [Candidate(q, yomi: q)]
        }

        var candidates: [Candidate] = []
        var seen: Set<String> = []
        func add(_ word: String, _ yomi: String) -> Bool {
            if seen.insert(word).inserted { candidates.append(Candidate(word, yomi: yomi)) }
            return candidates.count <= limit
        }

        for entry in studyDict + localDict where exact ? entry.yomi == q : entry.yomi.hasPrefix(q) {
            if !add(entry.word, entry.yomi) { return candidates }
        }
        connectionDict.search(q, exact: exact) { word, yomi in
            if word.hasSuffix("*") { return true }
            return add(word.replacingOccurrences(of: "*", with: ""), yomi)
        }
        return candidates
    }

    /// 個人辞書に登録する。
    public func register(word: String, yomi: String) {
        let entry = DictEntry(yomi: yomi, word: word)
        localDict.removeAll { $0 == entry }
        localDict.insert(entry, at: 0)
        Self.save(localDict, to: localDictURL)
        localDictDate = Self.modificationDate(localDictURL)
    }

    /// 確定した単語を学習する。接続辞書にない単語を2回確定すると個人辞書に登録する。
    public func study(word: String, yomi: String) {
        if yomi.count > 1 {
            var inConnectionDict = false
            connectionDict.search(yomi, exact: false) { w, _ in
                if w.hasSuffix("*") { return true }
                inConnectionDict = w.replacingOccurrences(of: "*", with: "") == word
                return !inConnectionDict
            }
            if !inConnectionDict, studyDict.contains(DictEntry(yomi: yomi, word: word)) {
                register(word: word, yomi: yomi)
            }
        }
        studyDict.insert(DictEntry(yomi: yomi, word: word), at: 0)
        if studyDict.count > studyDictLimit { studyDict.removeLast(studyDict.count - studyDictLimit) }
    }

    /// 学習辞書をファイルに書き出す。
    public func saveStudyDict() {
        Self.save(studyDict, to: studyDictURL)
    }

    private func reloadLocalDictIfChanged() {
        let date = Self.modificationDate(localDictURL)
        if let date, date > (localDictDate ?? .distantPast) {
            localDict = Self.load(localDictURL)
            localDictDate = date
        }
    }

    static func load(_ url: URL) -> [DictEntry] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").compactMap { line in
            guard !line.hasPrefix("#") else { return nil }
            let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard cols.count >= 2, !cols[0].isEmpty, !cols[1].isEmpty else { return nil }
            return DictEntry(yomi: String(cols[0]), word: String(cols[1]))
        }
    }

    static func save(_ dict: [DictEntry], to url: URL) {
        var seen: Set<String> = []
        let lines = dict.map { "\($0.yomi)\t\($0.word)" }.filter { seen.insert($0).inserted }
        try? (lines.map { $0 + "\n" }.joined()).write(to: url, atomically: true, encoding: .utf8)
    }

    static func modificationDate(_ url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }
}
