import Foundation

/// The labels the app looks for in the Claude desktop app, and how it compares them.
/// Kept free of AppKit and Accessibility so it can be tested on its own.
public enum Labels {
    /// The Claude app's own translations of "Allow once": its button follows its language.
    /// One-time approvals only: "Always allow" would write a permanent rule, and a bare
    /// "Allow" also labels the Allow/Deny choice of a rule in the app's settings.
    public static let allowOnce = [
        "Allow once", "Consenti una volta", "Einmalig erlauben", "Permitir una vez", "Autoriser une fois",
        "Permitir uma vez", "Izinkan sekali", "1回のみ許可", "한 번만 허용", "एक बार अनुमति दें",
    ]

    /// How the Claude sidebar marks a session waiting on you, in the same languages.
    public static let waiting = [
        "needs your input", "in attesa di una tua risposta", "wartet auf deine eingabe", "necesita tu respuesta",
        "en attente de votre réponse", "aguardando sua resposta", "perlu masukan anda", "応答が必要です", "응답 필요",
        "आपके इनपुट की ज़रूरत है",
    ]

    /// Claude builds the body of a permission notification in English whatever its
    /// language: "Allow Claude to run …?", optionally after "On <host>: ".
    public static let permissionBanner = "allow claude to"

    /// A label as its words, so shortcut glyphs and digits beside it do not matter:
    /// "Allow once ⌘⏎" and "1 Allow once" both read as ["allow", "once"].
    public static func words(_ s: String) -> [String] {
        s.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
    }

    /// The labels to press, from a labels file's text: one per line, blank lines and
    /// `#` comments skipped. A missing or empty file means the default, `allowOnce`.
    public static func wanted(fromFile text: String?) -> Set<[String]> {
        let listed = (text ?? "").split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        return Set((listed.isEmpty ? allowOnce : listed).map(words))
    }

    public static func matches(_ label: String, _ wanted: Set<[String]>) -> Bool {
        wanted.contains(words(label))
    }

    /// Whether an element's text marks a session waiting on you.
    public static func isWaiting(_ text: String) -> Bool {
        let lower = text.lowercased()
        return waiting.contains { lower.contains($0) }
    }
}
