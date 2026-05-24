import XCTest
@testable import Yojam

final class ProfileLaunchHelperTests: XCTestCase {
    func testFirefoxProfileArgumentsDoNotForceNewInstance() {
        let reader = FirefoxProfileReader(
            applicationSupportDirectory: URL(fileURLWithPath: "/tmp/yojam-empty-\(UUID().uuidString)"))
        let args = ProfileLaunchHelper.launchArguments(
            forProfile: "Work",
            browserBundleId: "org.mozilla.firefox",
            firefoxProfileReader: reader)

        XCTAssertEqual(args, ["-P", "Work"])
        XCTAssertFalse(args.contains("--new-instance"))
        XCTAssertFalse(args.contains("-no-remote"))
    }

    func testFirefoxProfilePathUsesProfileFlagAndNewInstance() {
        let profilePath = "/Users/test/Library/Application Support/Firefox/Profiles/abc123.Work"
        let args = ProfileLaunchHelper.launchArguments(
            forProfile: profilePath,
            browserBundleId: "org.mozilla.firefox")

        XCTAssertEqual(args, ["--profile", profilePath, "--new-instance"])
        XCTAssertFalse(args.contains("-P"))
    }

    func testFirefoxStoredProfileNameResolvesSelectableProfilePath() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let firefoxDirectory = tempDirectory.appendingPathComponent("Firefox")
        try FileManager.default.createDirectory(
            at: firefoxDirectory.appendingPathComponent("Profile Groups"),
            withIntermediateDirectories: true)

        let profilesIni = """
        [Profile0]
        Name=Work
        IsRelative=1
        Path=Profiles/abc123.Work
        StoreID=group-123
        """
        try profilesIni.write(
            to: firefoxDirectory.appendingPathComponent("profiles.ini"),
            atomically: true,
            encoding: .utf8)

        let args = ProfileLaunchHelper.launchArguments(
            forProfile: "Work",
            browserBundleId: "org.mozilla.firefox",
            firefoxProfileReader: FirefoxProfileReader(
                applicationSupportDirectory: tempDirectory))

        XCTAssertEqual(
            args,
            [
                "--profile",
                firefoxDirectory.appendingPathComponent("Profiles/abc123.Work").path,
                "--new-instance",
            ])
    }

    func testFirefoxStoredProfileNameResolvesFirefox138ProfilePathWithoutProfileGroups() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let firefoxDirectory = tempDirectory.appendingPathComponent("Firefox")
        try FileManager.default.createDirectory(
            at: firefoxDirectory,
            withIntermediateDirectories: true)

        let profilesIni = """
        [Profile0]
        Name=Work
        IsRelative=1
        Path=Profiles/qwer.Work
        StoreID=xxx663
        ShowSelector=1
        """
        try profilesIni.write(
            to: firefoxDirectory.appendingPathComponent("profiles.ini"),
            atomically: true,
            encoding: .utf8)

        let args = ProfileLaunchHelper.launchArguments(
            forProfile: "Work",
            browserBundleId: "org.mozilla.firefox",
            firefoxProfileReader: FirefoxProfileReader(
                applicationSupportDirectory: tempDirectory,
                firefoxVersionProvider: { _ in "138.0.1" }))

        XCTAssertEqual(
            args,
            [
                "--profile",
                firefoxDirectory.appendingPathComponent("Profiles/qwer.Work").path,
                "--new-instance",
            ])
    }

    func testChromiumProfileArgumentsStillUseProfileDirectory() {
        let args = ProfileLaunchHelper.launchArguments(
            forProfile: "Profile 2",
            browserBundleId: "com.vivaldi.Vivaldi")

        XCTAssertEqual(args, ["--profile-directory=Profile 2"])
    }

    func testChromiumProfileArgumentsIncludeCustomUserDataDirectory() {
        let args = ProfileLaunchHelper.launchArguments(
            forProfile: "Profile 2",
            browserBundleId: "org.chromium.Chromium",
            userDataDirectory: "/tmp/chromium-state")

        XCTAssertEqual(args, [
            "--user-data-dir=/tmp/chromium-state",
            "--profile-directory=Profile 2",
        ])
    }
}
