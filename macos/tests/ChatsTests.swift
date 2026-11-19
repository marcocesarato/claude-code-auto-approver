import Testing
@testable import AutoApproverCore

@Suite struct ChatsTests {
    @Test func readsTheTitleFromTheHeaderButton() {
        #expect(Chats.title(fromMenuButton: "More options for Refactor billing service") == "Refactor billing service")
        #expect(Chats.title(fromMenuButton: "More options for ") == nil)
        #expect(Chats.title(fromMenuButton: "Show more") == nil)
    }

    @Test func listsChatsThatAreNotIdle() {
        #expect(Chats.activeTitle(rowLabel: "Refactor billing service Running", status: "Running") == "Refactor billing service")
        #expect(Chats.activeTitle(rowLabel: "Release notes", status: "Needs your input") == "Release notes")
        #expect(Chats.activeTitle(rowLabel: "Release notes Idle", status: "Idle") == nil)
        #expect(Chats.activeTitle(rowLabel: "Release notes", status: "") == nil)
    }

    @Test func togglingAddsThenRemoves() {
        let added = Chats.toggled("Release notes", inFile: "# mine\nDeploy\n")
        #expect(Chats.skipped(fromFile: added) == ["Deploy", "Release notes"])
        #expect(Chats.skipped(fromFile: Chats.toggled("release NOTES", inFile: added)) == ["Deploy"])
    }

    @Test func matchesTitlesIgnoringCase() {
        #expect(Chats.isSkipped("deploy", ["Deploy"]))
        #expect(!Chats.isSkipped("Deploy staging", ["Deploy"]))
        #expect(!Chats.isSkipped(nil, ["Deploy"]))
    }

    @Test func findsTheChatInABanner() {
        let banner = "Claude, my-app, Refactor billing service, Allow Claude to run docker ps?"
        #expect(Chats.bannerIsSkipped(banner, ["refactor billing service"]))
        #expect(!Chats.bannerIsSkipped(banner, ["Release notes"]))
        #expect(!Chats.bannerIsSkipped(banner, []))
    }
}
