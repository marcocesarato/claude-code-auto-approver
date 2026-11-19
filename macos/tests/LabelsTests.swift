import Testing
@testable import AutoApproverCore

@Suite struct LabelsTests {
    let defaults = Labels.wanted(fromFile: nil)

    @Test(arguments: ["Allow once", "Allow once ⌘⏎", "1  Allow once", "allow ONCE", "Allow once 2",
                      "Consenti una volta 3", "Einmalig erlauben", "1回のみ許可", "한 번만 허용 2", "एक बार अनुमति दें"])
    func pressesAllowOnceInEveryLanguage(label: String) {
        #expect(Labels.matches(label, defaults))
    }

    /// "Always allow" writes a permanent rule; a bare "Allow" also labels a settings choice.
    @Test(arguments: ["Always allow", "Allow", "Deny 1", "Consenti sempre", "Immer erlauben",
                      "Allow once for this session", ""])
    func neverPressesAnythingElse(label: String) {
        #expect(!Labels.matches(label, defaults))
    }

    @Test func labelsFileReplacesTheDefault() {
        let wanted = Labels.wanted(fromFile: "# my labels\n\n  Yes  \nApprove\n")
        #expect(wanted == [["yes"], ["approve"]])
        #expect(!Labels.matches("Allow once", wanted))
    }

    @Test(arguments: ["", "\n\n", "# only a comment\n"])
    func emptyLabelsFileMeansTheDefault(text: String) {
        #expect(Labels.wanted(fromFile: text) == defaults)
    }

    @Test(arguments: ["Needs your input", "SESSIONS — Needs Your Input", "In attesa di una tua risposta", "응답 필요"])
    func recognisesAWaitingSession(text: String) {
        #expect(Labels.isWaiting(text))
    }

    @Test func idleSessionIsNotWaiting() {
        #expect(!Labels.isWaiting("Fix the build Idle"))
    }
}
