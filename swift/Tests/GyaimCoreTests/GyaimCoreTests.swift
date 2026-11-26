import Foundation
import XCTest
@testable import GyaimCore

/// リポジトリ同梱の接続辞書 resources/dict.txt。
let dictPath = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().appendingPathComponent("../../../resources/dict.txt").standardized.path

final class RomaKanaTests: XCTestCase {
    func testHiragana() {
        XCTAssertEqual(RomaKana.toHiragana("masui"), "ますい")
        XCTAssertEqual(RomaKana.toHiragana("kyouto"), "きょうと")
        XCTAssertEqual(RomaKana.toHiragana("gakkou"), "がっこう")
        XCTAssertEqual(RomaKana.toHiragana("kanji"), "かんじ")
        XCTAssertEqual(RomaKana.toHiragana("hon"), "ほん")
        XCTAssertEqual(RomaKana.toHiragana("ra-men"), "らーめん")
    }

    func testKatakana() {
        XCTAssertEqual(RomaKana.toKatakana("konpyu-ta"), "コンピュータ")
        XCTAssertEqual(RomaKana.toKatakana("bakku"), "バック")
    }
}

final class ConnectionDictTests: XCTestCase {
    static let dict = try! ConnectionDict(path: dictPath)

    func words(_ q: String, exact: Bool = false) -> [String] {
        var result: [String] = []
        Self.dict.search(q, exact: exact) { word, _ in
            if !word.hasSuffix("*") { result.append(word.replacingOccurrences(of: "*", with: "")) }
            return true
        }
        return result
    }

    func testPrefix() { XCTAssertTrue(words("tou").contains("東京")) }
    func testInflection() { XCTAssertTrue(words("taberarenai").contains("食べられない")) }
    func testExact() { XCTAssertFalse(words("tou", exact: true).contains("東京")) }
}

final class WordSearchTests: XCTestCase {
    var dir: URL!
    var ws: WordSearch!

    override func setUp() {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        ws = WordSearch(connectionDict: ConnectionDictTests.dict,
                        localDictURL: dir.appendingPathComponent("localdict.txt"),
                        studyDictURL: dir.appendingPathComponent("studydict.txt"))
    }

    override func tearDown() { try? FileManager.default.removeItem(at: dir) }

    func words(_ q: String, exact: Bool = false) -> [String] { ws.search(q, exact: exact).map(\.word) }

    func testSearch() {
        XCTAssertTrue(words("masui").contains("増井"))
        XCTAssertTrue(words("taberaremasen").contains("食べられません"))
        XCTAssertTrue(words("sanbyakuyonjuuni").contains("三百四十二"))
    }

    func testRegisterWritesLocalDict() throws {
        ws.register(word: "あいうえお", yomi: "aiueo")
        let text = try String(contentsOf: dir.appendingPathComponent("localdict.txt"), encoding: .utf8)
        XCTAssertEqual(text, "aiueo\tあいうえお\n")
        XCTAssertEqual(words("aiu").first, "あいうえお")
    }

    func testStudyTwiceRegistersUnknownWord() {
        ws.study(word: "ほげ山", yomi: "hogeyama")
        XCTAssertEqual(words("hogeya").first, "ほげ山")
        ws.study(word: "ほげ山", yomi: "hogeyama")
        ws.saveStudyDict()
        let reopened = WordSearch(connectionDict: ConnectionDictTests.dict,
                                  localDictURL: dir.appendingPathComponent("localdict.txt"),
                                  studyDictURL: dir.appendingPathComponent("nothing.txt"))
        XCTAssertEqual(reopened.search("hogeya", exact: false).first?.word, "ほげ山")
    }

    func testUppercaseIsLiteral() { XCTAssertEqual(words("Gyaim"), ["Gyaim"]) }
}

final class ComposerTests: XCTestCase {
    var dir: URL!
    var composer: Composer!
    var copied: String?

    override func setUp() {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let ws = WordSearch(connectionDict: ConnectionDictTests.dict,
                            localDictURL: dir.appendingPathComponent("localdict.txt"),
                            studyDictURL: dir.appendingPathComponent("studydict.txt"))
        composer = Composer(wordSearch: ws, recentCopy: { [unowned self] in self.copied })
    }

    override func tearDown() { try? FileManager.default.removeItem(at: dir) }

    func type(_ s: String) { for c in s { _ = composer.handle(.character(String(c))) } }

    func testTypingShowsInputFirstThenWords() {
        type("masui")
        XCTAssertEqual(composer.current?.word, "masui")
        XCTAssertTrue(composer.candidates.map(\.word).contains("増井"))
    }

    func testSpaceThenEnterCommitsSecondCandidate() {
        type("masui")
        _ = composer.handle(.space)
        let second = composer.current?.word
        XCTAssertEqual(composer.handle(.enter).commit, second)
        XCTAssertFalse(composer.isComposing)
    }

    func testEnterAtFirstCandidateSwitchesToKana() {
        type("kyouto")
        let r = composer.handle(.enter)
        XCTAssertNil(r.commit)
        XCTAssertEqual(composer.candidates.prefix(2).map(\.word), ["きょうと", "キョウト"])
        XCTAssertTrue(composer.candidates.map(\.word).contains("京都"))
        XCTAssertEqual(composer.handle(.enter).commit, "きょうと")
    }

    func testTypingAfterSelectingCommitsAndStartsNewWord() {
        type("masui")
        _ = composer.handle(.space)
        let picked = composer.current?.word
        XCTAssertEqual(composer.handle(.character("d")).commit, picked)
        XCTAssertEqual(composer.input, "d")
    }

    func testBackspaceStepsBackThenDeletes() {
        type("masui")
        _ = composer.handle(.space)
        _ = composer.handle(.backspace)
        XCTAssertEqual(composer.index, 0)
        _ = composer.handle(.backspace)
        XCTAssertEqual(composer.input, "masu")
        for _ in 0..<4 { _ = composer.handle(.backspace) }
        XCTAssertFalse(composer.isComposing)
        XCTAssertFalse(composer.handle(.backspace).handled)
    }

    func testKeysPassThroughWhenIdle() {
        XCTAssertFalse(composer.handle(.space).handled)
        XCTAssertFalse(composer.handle(.enter).handled)
    }

    func testSelectedTextIsRegisteredUnderTypedReading() {
        composer.selectedText = "増井俊之"
        type("msi")
        XCTAssertEqual(composer.candidates[1].word, "増井俊之")
        _ = composer.handle(.space)
        XCTAssertEqual(composer.handle(.enter).commit, "増井俊之")
        type("ms")
        XCTAssertTrue(composer.candidates.map(\.word).contains("増井俊之"))
    }

    func testRecentCopyIsOffered() {
        copied = "コピーした文"
        type("a")
        XCTAssertEqual(composer.candidates[1].word, "コピーした文")
    }

    func testTrailingPeriodAsksGoogle() {
        type("kanji")
        XCTAssertEqual(composer.handle(.character(".")).googleQuery, "かんじ")
        composer.showGoogleCandidates(["漢字", "感じ"])
        XCTAssertEqual(composer.current?.word, "漢字")
        XCTAssertEqual(composer.handle(.enter).commit, "漢字")
    }
}
