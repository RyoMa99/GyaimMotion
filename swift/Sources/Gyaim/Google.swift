import Foundation

/// Google 日本語変換 API で、ひらがなを漢字かな混じりの候補にする。
enum Google {
    static func transliterate(_ hiragana: String, completion: @escaping ([String]) -> Void) {
        var components = URLComponents(string: "https://www.google.com/transliterate")!
        components.queryItems = [
            URLQueryItem(name: "langpair", value: "ja-Hira|ja"),
            URLQueryItem(name: "text", value: hiragana),
        ]
        URLSession.shared.dataTask(with: components.url!) { data, _, _ in
            // 応答は [["かんじ", ["漢字", "感じ", ...]], ...]。文節ごとに分かれるので第1候補同士をつなげた候補を先頭に置く。
            guard let data,
                  let segments = (try? JSONSerialization.jsonObject(with: data)) as? [[Any]] else { return }
            let options = segments.compactMap { $0.count > 1 ? $0[1] as? [String] : nil }
            guard !options.isEmpty else { return }
            var words = options.count == 1 ? options[0] : [options.compactMap(\.first).joined()]
            words.removeAll { $0 == hiragana }
            var seen: Set<String> = []
            words = words.filter { seen.insert($0).inserted }
            DispatchQueue.main.async { completion(words) }
        }.resume()
    }
}
