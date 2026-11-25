import Foundation
import Testing
@testable import AutoApproverCore

@Suite struct ActivityTests {
    static let log = """
    2026-11-24 18:00:01 🤖 Approved #1: pressed "Allow once"
    2026-11-25 10:40:00 🔍 Monitoring — pressing: Allow once
    2026-11-25 10:41:07 🤖 Approved #1: pressed "Allow once (notification)"
    2026-11-25 10:42:07 ▶️ Resumed
    2026-11-25 10:43:09 🤖 Approved #2: pressed "Consenti una volta" 🔒
    """

    @Test func readsTheApprovalsNewestFirst() {
        #expect(Activity.approvals(fromLog: Self.log) == [
            Approval(time: "2026-11-25 10:43:09", label: "Consenti una volta", fromNotification: false, locked: true),
            Approval(time: "2026-11-25 10:41:07", label: "Allow once", fromNotification: true, locked: false),
            Approval(time: "2026-11-24 18:00:01", label: "Allow once", fromNotification: false, locked: false),
        ])
    }

    @Test func readsTheChatAndTheRequestItWrote() {
        let line = Activity.logLine(number: 4, label: "Allow once (notification)", locked: true,
                                    chat: "Fix \"flaky\" tests", request: "Allow Claude to run git status\nand more")
        let read = Activity.approvals(fromLog: "2026-11-25 11:00:00 " + line)
        #expect(read == [Approval(time: "2026-11-25 11:00:00", label: "Allow once", fromNotification: true, locked: true,
                                  chat: "Fix \"flaky\" tests", request: "Allow Claude to run git status and more")])
        let plain = Activity.approvals(fromLog: "2026-11-25 11:00:00 " + Activity.logLine(
            number: 5, label: "Allow once", locked: false, chat: "Write notes", request: "Claude wants to fetch github.com"))
        #expect(plain == [Approval(time: "2026-11-25 11:00:00", label: "Allow once", fromNotification: false, locked: false,
                                   chat: "Write notes", request: "Claude wants to fetch github.com")])
    }

    @Test func takesTheChatAndTheRequestOfAnOlderLineFromItsBanner() {
        let log = """
        2026-11-25 10:10:17 🔔 Permission notification: Claude, vanguard, Fix tests, Allow Claude to run ls
        2026-11-25 10:10:18 🤖 Approved #8: pressed "Allow once (notification)"
        2026-11-25 10:10:19 🤖 Approved #9: pressed "Allow once"
        """
        let read = Activity.approvals(fromLog: log)
        #expect(read.map(\.chat) == [nil, "Fix tests"])
        #expect(read.last?.request == "Allow Claude to run ls")
    }

    @Test func readsTheChatAndTheRequestOfABanner() {
        let banner = Activity.bannerRequest("Claude, vanguard, Prefix repeated, in replies, Allow Claude to run docker ps")
        #expect(banner.chat == "Prefix repeated, in replies")
        #expect(banner.request == "Allow Claude to run docker ps")
        #expect(Activity.bannerRequest("Something else").request == nil)
    }

    @Test func ignoresOtherLinesAndCutOnes() {
        #expect(Activity.approvals(fromLog: "").isEmpty)
        #expect(Activity.approvals(fromLog: "proved #4: pressed \"Allow once\"\n2026-11-25 10:42:07 ▶️ Resumed").isEmpty)
    }

    @Test func groupsByDayNewestFirst() {
        let days = Activity.byDay(Activity.approvals(fromLog: Self.log))
        #expect(days.map(\.day) == ["2026-11-25", "2026-11-24"])
        #expect(days.map(\.approvals.count) == [2, 1])
        #expect(days[0].approvals[0].clock == "10:43")
    }

    @Test func writesDaysAsTheLogDoes() {
        #expect(Activity.isoDay(Date(timeIntervalSince1970: 0)).count == 10)
        #expect(L10n.day(Activity.isoDay(Date()), language: "en") == "Today")
        #expect(L10n.day("2020-03-14", language: "en") == "Mar 14, 2020")
    }
}
