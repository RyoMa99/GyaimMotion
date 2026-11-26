import Foundation

/// 接続辞書による変換。元実装 ConnectionDict.rb を移植。
/// 各行は「読み<TAB>単語<TAB>入力接続番号<TAB>出力接続番号」。
public final class ConnectionDict {
    struct Entry {
        let pat: String
        let word: String
        let inConnection: Int
        let outConnection: Int
        var keyLink: Int?
        var connectionLink: Int?
    }

    private var dict: [Entry] = []
    private var keyLink: [Character: Int] = [:]
    private var connectionLink: [Int: Int] = [:]

    public convenience init(path: String) throws {
        try self.init(contents: String(contentsOfFile: path, encoding: .utf8))
    }

    public init(contents: String) {
        for line in contents.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let first = line.first, first != "#", !first.isWhitespace else { continue }
            let cols = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
            guard cols.count >= 2 else { continue }
            dict.append(Entry(
                pat: cols[0],
                word: cols[1],
                inConnection: cols.count > 2 ? Int(cols[2]) ?? 0 : 0,
                outConnection: cols.count > 3 ? Int(cols[3]) ?? 0 : 0
            ))
        }
        link()
    }

    /// 先頭の読みが同じ単語の連結リストと、入力接続番号が同じ単語の連結リストを張る。
    private func link() {
        var lastByKey: [Character: Int] = [:]
        var lastByConnection: [Int: Int] = [:]
        for i in dict.indices {
            let entry = dict[i]
            if !entry.word.hasPrefix("*"), let key = entry.pat.first {
                if let last = lastByKey[key] { dict[last].keyLink = i } else { keyLink[key] = i }
                lastByKey[key] = i
            }
            if let last = lastByConnection[entry.inConnection] {
                dict[last].connectionLink = i
            } else {
                connectionLink[entry.inConnection] = i
            }
            lastByConnection[entry.inConnection] = i
        }
    }

    /// `exact` が false なら前方一致、true なら完全一致。
    /// `found` は (単語, 読み) を受け取り、検索を続けるなら true を返す。
    public func search(_ pat: String, exact: Bool, found: (String, String) -> Bool) {
        _ = generate(connection: nil, pat: pat, word: "", yomi: "", exact: exact, found: found)
    }

    private func generate(
        connection: Int?, pat: String, word: String, yomi: String, exact: Bool,
        found: (String, String) -> Bool
    ) -> Bool {
        var d: Int?
        if let connection { d = connectionLink[connection] } else if let key = pat.first { d = keyLink[key] }
        while let i = d {
            let entry = dict[i]
            if pat == entry.pat || (!exact && entry.pat.hasPrefix(pat)) {
                if !found(word + entry.word, yomi + entry.pat) { return false }
            } else if !entry.pat.hasPrefix(pat), pat.hasPrefix(entry.pat) {
                let rest = String(pat.dropFirst(entry.pat.count))
                if !generate(connection: entry.outConnection, pat: rest, word: word + entry.word,
                             yomi: yomi + entry.pat, exact: exact, found: found) { return false }
            }
            d = connection == nil ? entry.keyLink : entry.connectionLink
        }
        return true
    }
}
