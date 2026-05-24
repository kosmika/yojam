import XCTest
@testable import Yojam

final class ChromiumProfileReaderTests: XCTestCase {
    func testCustomUserDataDirectoryDrivesProfileDiscovery() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true)

        let localState = """
        {
          "profile": {
            "last_used": "Profile 2",
            "info_cache": {
              "Default": {
                "name": "Personal",
                "user_name": "me@example.com"
              },
              "Profile 2": {
                "name": "Work",
                "user_name": "work@example.com"
              }
            }
          }
        }
        """
        try localState.write(
            to: tempDirectory.appendingPathComponent("Local State"),
            atomically: true,
            encoding: .utf8)

        let profiles = ChromiumProfileReader().readProfiles(
            appSupportPath: "Ignored",
            bundleId: "org.chromium.Chromium",
            userDataDirectory: tempDirectory.path)

        XCTAssertEqual(Set(profiles.map(\.id)), ["Default", "Profile 2"])
        XCTAssertEqual(profiles.first(where: { $0.id == "Profile 2" })?.name, "Work")
        XCTAssertEqual(profiles.first(where: { $0.id == "Profile 2" })?.isDefault, true)
    }
}
