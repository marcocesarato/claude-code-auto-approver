import Foundation
import Testing
@testable import AutoApproverCore

@Suite struct LocalizationTests {
    @Test(arguments: [(["it-IT", "en-US"], "it"), (["pt-BR"], "pt"), (["zh-Hans-CN", "de-DE"], "de"),
                      (["zh-Hans-CN"], "en"), ([], "en"), (["ja_JP"], "ja")])
    func picksTheFirstLanguageItHas(preferred: [String], expected: String) {
        #expect(L10n.language(for: preferred) == expected)
    }

    @Test(arguments: L10n.languages.sorted())
    func everyLanguageHasEveryString(language: String) {
        let missing = L10n.Key.allCases.filter { L10n.table[language]?[$0]?.isEmpty ?? true }
        #expect(missing.isEmpty, "\(language) lacks \(missing)")
    }

    @Test func namesPauseLengthsInTheLanguage() {
        #expect(L10n.duration(5 * 60, language: "en") == "5 minutes")
        #expect(L10n.duration(3 * 3600, language: "en") == "3 hours")
        #expect(L10n.duration(3600, language: "it") == "1 ora")
        #expect(Pause.durations.last! == nil)
    }

    @Test func showsWhenAPauseEnds() {
        let text = L10n.pausedUntil(Date(), language: "en")
        #expect(text.hasPrefix("○ Paused until ") && !text.contains("%@"))
    }

    @Test func namesTheProduct() {
        #expect(L10n.t(.running, language: "en") == "Claude Code - Auto Approver is on")
        #expect(L10n.t(.by, language: "it") == "di Marco Cesarato")
    }
}
