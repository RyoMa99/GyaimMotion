/// ローマ字からひらがな・カタカナへの変換。元実装 Romakana.rb の roma2hiragana / roma2katakana を移植。
/// 表は先頭から順に照合し、最初に一致したものを使う (Ruby のハッシュの挿入順と同じ)。
public enum RomaKana {
    static let table: [(roma: String, hira: String, kata: String)] = [
        ("a", "あ", "ア"),
        ("ba", "ば", "バ"),
        ("be", "べ", "ベ"),
        ("bi", "び", "ビ"),
        ("bo", "ぼ", "ボ"),
        ("bu", "ぶ", "ブ"),
        ("bya", "びゃ", "ビャ"),
        ("bye", "びぇ", "ビェ"),
        ("byi", "びぃ", "ビィ"),
        ("byo", "びょ", "ビョ"),
        ("byu", "びゅ", "ビュ"),
        ("cha", "ちゃ", "チャ"),
        ("che", "ちぇ", "チェ"),
        ("chi", "ち", "チ"),
        ("cho", "ちょ", "チョ"),
        ("chu", "ちゅ", "チュ"),
        ("da", "だ", "ダ"),
        ("de", "で", "デ"),
        ("dha", "でゃ", "デャ"),
        ("dhe", "でぇ", "デェ"),
        ("dhi", "でぃ", "ディ"),
        ("dho", "でょ", "デョ"),
        ("dhu", "でゅ", "デュ"),
        ("di", "ぢ", "ヂ"),
        ("do", "ど", "ド"),
        ("du", "づ", "ヅ"),
        ("dya", "ぢゃ", "ヂャ"),
        ("dye", "ぢぇ", "ヂェ"),
        ("dyi", "ぢぃ", "ヂィ"),
        ("dyo", "ぢょ", "ヂョ"),
        ("dyu", "でゅ", "デュ"),
        ("e", "え", "エ"),
        ("fa", "ふぁ", "ファ"),
        ("fe", "ふぇ", "フェ"),
        ("fi", "ふぃ", "フィ"),
        ("fo", "ふぉ", "フォ"),
        ("fuxyu", "ふゅ", "フュ"),
        ("fu", "ふ", "フ"),
        ("ga", "が", "ガ"),
        ("ge", "げ", "ゲ"),
        ("gi", "ぎ", "ギ"),
        ("go", "ご", "ゴ"),
        ("gu", "ぐ", "グ"),
        ("gya", "ぎゃ", "ギャ"),
        ("gye", "ぎぇ", "ギェ"),
        ("gyi", "ぎぃ", "ギィ"),
        ("gyo", "ぎょ", "ギョ"),
        ("gyu", "ぎゅ", "ギュ"),
        ("ha", "は", "ハ"),
        ("he", "へ", "ヘ"),
        ("hi", "ひ", "ヒ"),
        ("ho", "ほ", "ホ"),
        ("hu", "ふ", "フ"),
        ("hya", "ひゃ", "ヒャ"),
        ("hye", "ひぇ", "ヒェ"),
        ("hyi", "ひぃ", "ヒィ"),
        ("hyo", "ひょ", "ヒョ"),
        ("hyu", "ひゅ", "ヒュ"),
        ("i", "い", "イ"),
        ("ja", "じゃ", "ジャ"),
        ("je", "じぇ", "ジェ"),
        ("ji", "じ", "ジ"),
        ("jo", "じょ", "ジョ"),
        ("ju", "じゅ", "ジュ"),
        ("ka", "か", "カ"),
        ("ke", "け", "ケ"),
        ("ki", "き", "キ"),
        ("ko", "こ", "コ"),
        ("ku", "く", "ク"),
        ("kya", "きゃ", "キャ"),
        ("kye", "きぇ", "キェ"),
        ("kyi", "きぃ", "キィ"),
        ("kyo", "きょ", "キョ"),
        ("kyu", "きゅ", "キュ"),
        ("ma", "ま", "マ"),
        ("me", "め", "メ"),
        ("mi", "み", "ミ"),
        ("mo", "も", "モ"),
        ("mu", "む", "ム"),
        ("mya", "みゃ", "ミャ"),
        ("mye", "みぇ", "ミェ"),
        ("myi", "みぃ", "ミィ"),
        ("myo", "みょ", "ミョ"),
        ("myu", "みゅ", "ミュ"),
        ("nn", "ん", "ン"),
        ("na", "な", "ナ"),
        ("ne", "ね", "ネ"),
        ("ni", "に", "ニ"),
        ("no", "の", "ノ"),
        ("nu", "ぬ", "ヌ"),
        ("nya", "にゃ", "ニャ"),
        ("nye", "にぇ", "ニェ"),
        ("nyi", "にぃ", "ニィ"),
        ("nyo", "にょ", "ニョ"),
        ("nyu", "にゅ", "ニュ"),
        ("o", "お", "オ"),
        ("pa", "ぱ", "パ"),
        ("pe", "ぺ", "ペ"),
        ("pi", "ぴ", "ピ"),
        ("po", "ぽ", "ポ"),
        ("pu", "ぷ", "プ"),
        ("pya", "ぴゃ", "ピャ"),
        ("pye", "ぴぇ", "ピェ"),
        ("pyi", "ぴぃ", "ピィ"),
        ("pyo", "ぴょ", "ピョ"),
        ("pyu", "ぴゅ", "ピュ"),
        ("ra", "ら", "ラ"),
        ("re", "れ", "レ"),
        ("ri", "り", "リ"),
        ("ro", "ろ", "ロ"),
        ("ru", "る", "ル"),
        ("rya", "りゃ", "リャ"),
        ("rye", "りぇ", "リェ"),
        ("ryi", "りぃ", "リィ"),
        ("ryo", "りょ", "リョ"),
        ("ryu", "りゅ", "リュ"),
        ("sa", "さ", "サ"),
        ("se", "せ", "セ"),
        ("sha", "しゃ", "シャ"),
        ("she", "しぇ", "シェ"),
        ("shi", "し", "シ"),
        ("sho", "しょ", "ショ"),
        ("shu", "しゅ", "シュ"),
        ("si", "し", "シ"),
        ("so", "そ", "ソ"),
        ("su", "す", "ス"),
        ("sya", "しゃ", "シャ"),
        ("sye", "しぇ", "シェ"),
        ("syi", "しぃ", "シィ"),
        ("syo", "しょ", "ショ"),
        ("syu", "しゅ", "シュ"),
        ("ta", "た", "タ"),
        ("te", "て", "テ"),
        ("tha", "てゃ", "テャ"),
        ("the", "てぇ", "テェ"),
        ("thi", "てぃ", "ティ"),
        ("tho", "てょ", "テョ"),
        ("thu", "てゅ", "テュ"),
        ("ti", "ち", "チ"),
        ("to", "と", "ト"),
        ("tsu", "つ", "ツ"),
        ("tu", "つ", "ツ"),
        ("tya", "ちゃ", "チャ"),
        ("tye", "ちぇ", "チェ"),
        ("tyi", "ちぃ", "チィ"),
        ("tyo", "ちょ", "チョ"),
        ("tyu", "ちゅ", "チュ"),
        ("u", "う", "ウ"),
        ("va", "う゛ぁ", "ヴァ"),
        ("ve", "う゛ぃ", "ヴェ"),
        ("vi", "う゛ぅ", "ヴィ"),
        ("vo", "う゛ぉ", "ヴォ"),
        ("vu", "う゛", "ヴ"),
        ("wa", "わ", "ワ"),
        ("we", "うぇ", "ウェ"),
        ("wi", "うぃ", "ウィ"),
        ("wo", "を", "ヲ"),
        ("xa", "ぁ", "ァ"),
        ("xe", "ぇ", "ェ"),
        ("xi", "ぃ", "ィ"),
        ("xo", "ぉ", "ォ"),
        ("xtu", "っ", "ッ"),
        ("xtsu", "っ", "ッ"),
        ("xu", "ぅ", "ゥ"),
        ("xwa", "ゎ", "ヮ"),
        ("ya", "や", "ヤ"),
        ("yo", "よ", "ヨ"),
        ("yu", "ゆ", "ユ"),
        ("za", "ざ", "ザ"),
        ("ze", "ぜ", "ゼ"),
        ("zi", "じ", "ジ"),
        ("zo", "ぞ", "ゾ"),
        ("zu", "ず", "ズ"),
        ("zya", "じゃ", "ジャ"),
        ("zye", "じぇ", "ジェ"),
        ("zyi", "じぃ", "ジィ"),
        ("zyo", "じょ", "ジョ"),
        ("zyu", "じゅ", "ジュ"),
        ("xya", "ゃ", "ャ"),
        ("xyu", "ゅ", "ュ"),
        ("xyo", "ょ", "ョ"),
        ("-", "ー", "ー"),
    ]

    public static func toHiragana(_ roma: String) -> String {
        convert(roma, kana: { $0.hira }, n: "ん", tsu: "っ")
    }

    public static func toKatakana(_ roma: String) -> String {
        convert(roma, kana: { $0.kata }, n: "ン", tsu: "ッ")
    }

    private static let nFollowers = Set("bcdfghjklmnpqrstvwxz")
    private static let doubled = Set("bcdfghjklmpqrstvwxyz")

    private static func convert(
        _ roma: String,
        kana: ((roma: String, hira: String, kata: String)) -> String,
        n: String,
        tsu: String
    ) -> String {
        let chars = Array(roma)
        var result = ""
        var i = 0
        while i < chars.count {
            if let entry = table.first(where: { matches($0.roma, chars, at: i) }) {
                result += kana(entry)
                i += entry.roma.count
                continue
            }
            let r0 = chars[i]
            let r1: Character? = i + 1 < chars.count ? chars[i + 1] : nil
            let isN = r0 == "n" || r0 == "N"
            if isN, let r1, nFollowers.contains(r1) {
                result += n
            } else if doubled.contains(r0), r0 == r1 {
                result += tsu
            } else if isN, r1 == nil {
                result += n
            }
            i += 1
        }
        return result
    }

    private static func matches(_ roma: String, _ chars: [Character], at i: Int) -> Bool {
        var j = i
        for c in roma {
            guard j < chars.count, chars[j] == c else { return false }
            j += 1
        }
        return true
    }
}
