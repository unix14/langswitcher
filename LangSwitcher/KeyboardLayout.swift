import Foundation

enum KeyboardLayout {
    private static let englishToHebrew: [Character: Character] = {
        let pairs: [(Character, Character)] = [
            ("q", "/"), ("w", "\u{05F3}"),
            ("e", "ק"), ("r", "ר"), ("t", "א"), ("y", "ט"),
            ("u", "ו"), ("i", "ן"), ("o", "מ"), ("p", "פ"),
            ("[", "]"), ("]", "["),
            ("a", "ש"), ("s", "ד"), ("d", "ג"), ("f", "כ"),
            ("g", "ע"), ("h", "י"), ("j", "ח"), ("k", "ל"),
            ("l", "ך"), (";", "ף"), ("'", ","),
            ("z", "ז"), ("x", "ס"), ("c", "ב"), ("v", "ה"),
            ("b", "נ"), ("n", "ם"), ("m", "צ"),
            (",", "ת"), (".", "ץ"), ("/", "."),
        ]
        return Dictionary(uniqueKeysWithValues: pairs)
    }()

    private static let hebrewToEnglish: [Character: Character] =
        Dictionary(uniqueKeysWithValues: englishToHebrew.map { ($1, $0) })

    private static let toFinal:   [Character: Character] = ["מ":"ם","נ":"ן","כ":"ך","פ":"ף","צ":"ץ"]
    private static let toRegular: [Character: Character] = ["ם":"מ","ן":"נ","ך":"כ","ף":"פ","ץ":"צ"]

    static func convert(_ input: String) -> String {
        let hebrewRange: ClosedRange<Unicode.Scalar> = "\u{0590}"..."\u{05FF}"
        let scalars = Array(input.unicodeScalars)
        let hebrewCount = scalars.filter { hebrewRange.contains($0) }.count
        let latinRange: ClosedRange<Unicode.Scalar> = "\u{0041}"..."\u{007A}"
        let latinCount = scalars.filter { latinRange.contains($0) }.count
        let isHebrewMajority = hebrewCount > latinCount

        let source = isHebrewMajority ? input : input.lowercased()
        let table = isHebrewMajority ? hebrewToEnglish : englishToHebrew
        var chars = Array(source.map { table[$0] ?? $0 })

        if !isHebrewMajority {
            func isHebrew(_ c: Character) -> Bool {
                c.unicodeScalars.allSatisfy { hebrewRange.contains($0) }
            }
            for i in chars.indices where isHebrew(chars[i]) {
                let atEnd = i + 1 == chars.count || !isHebrew(chars[i + 1])
                chars[i] = atEnd ? (toFinal[chars[i]] ?? chars[i]) : (toRegular[chars[i]] ?? chars[i])
            }
        }

        return String(chars)
    }
}
