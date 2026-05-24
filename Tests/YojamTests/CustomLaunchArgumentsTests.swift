import XCTest
@testable import Yojam

final class CustomLaunchArgumentsTests: XCTestCase {
    @MainActor
    func testCustomLaunchArgsAppendURLWhenTemplateOmitsPlaceholder() {
        let url = URL(string: "https://example.com/path")!
        let args = AppDelegate.customLaunchArguments(
            template: "--profile \"$HOME/Library/Application Support/Firefox/Profiles/abc123.Profile 1\"",
            url: url,
            profile: nil,
            bundleId: "org.mozilla.firefox",
            privateWindow: false)

        XCTAssertEqual(args.last, url.absoluteString)
        XCTAssertEqual(args[0], "--profile")
        XCTAssertTrue(args[1].hasSuffix(
            "/Library/Application Support/Firefox/Profiles/abc123.Profile 1"))
    }

    @MainActor
    func testCustomLaunchArgsDoNotAppendURLWhenTemplateContainsPlaceholder() {
        let url = URL(string: "https://example.com/path")!
        let args = AppDelegate.customLaunchArguments(
            template: "--new-window $URL",
            url: url,
            profile: nil,
            bundleId: "org.mozilla.firefox",
            privateWindow: false)

        XCTAssertEqual(args, ["--new-window", url.absoluteString])
    }

    @MainActor
    func testArgumentLaunchUsesOpenForNewAppInstance() {
        let appURL = URL(fileURLWithPath: "/Applications/Chromium.app")
        let invocation = AppDelegate.argumentLaunchInvocation(
            appURL: appURL,
            arguments: ["--user-data-dir=/tmp/temporary1", "https://example.com"],
            openAsNewInstance: true)

        XCTAssertEqual(invocation.executableURL.path, "/usr/bin/open")
        XCTAssertEqual(invocation.arguments, [
            "-n",
            "-a",
            "/Applications/Chromium.app",
            "--args",
            "--user-data-dir=/tmp/temporary1",
            "https://example.com",
        ])
    }

    @MainActor
    func testCustomLaunchArgsIncludeConfiguredUserDataDirectoryBeforeAppendedURL() {
        let url = URL(string: "https://example.com/path")!
        let args = AppDelegate.customLaunchArguments(
            template: "--new-window",
            url: url,
            profile: "Profile 2",
            bundleId: "org.chromium.Chromium",
            privateWindow: false,
            userDataDirectory: "/tmp/chromium-state")

        XCTAssertEqual(args, [
            "--new-window",
            "--user-data-dir=/tmp/chromium-state",
            "--profile-directory=Profile 2",
            url.absoluteString,
        ])
    }
}
