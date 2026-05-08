import XCTest
@testable import YojamCore

final class RuleProfilePersistenceTests: XCTestCase {
    func testRuleCodableRoundTripsConfiguredBrowserEntryAndProfileOverride() throws {
        let entryId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let rule = Rule(
            name: "Firefox Work",
            matchType: .domain,
            pattern: "github.com",
            targetBundleId: "org.mozilla.firefox",
            targetAppName: "Firefox - Work",
            targetBrowserEntryId: entryId,
            ruleProfileId: "work",
            ruleOpenInPrivateWindow: true,
            ruleCustomLaunchArgs: "-P work $URL",
            ruleOpenAsNewInstance: true)

        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(Rule.self, from: data)

        XCTAssertEqual(decoded.targetBrowserEntryId, entryId)
        XCTAssertEqual(decoded.ruleProfileId, "work")
        XCTAssertEqual(decoded.ruleOpenInPrivateWindow, true)
        XCTAssertEqual(decoded.ruleCustomLaunchArgs, "-P work $URL")
        XCTAssertEqual(decoded.ruleOpenAsNewInstance, true)
    }

    func testRuleDecodesLegacyRulesWithoutProfileTargetFields() throws {
        let json = """
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "name": "Legacy Firefox",
          "enabled": true,
          "matchType": "domain",
          "pattern": "example.com",
          "targetBundleId": "org.mozilla.firefox",
          "targetAppName": "Firefox",
          "isBuiltIn": false,
          "priority": 100,
          "stripUTMParams": false
        }
        """

        let decoded = try JSONDecoder().decode(Rule.self, from: Data(json.utf8))

        XCTAssertNil(decoded.targetBrowserEntryId)
        XCTAssertNil(decoded.ruleProfileId)
        XCTAssertNil(decoded.ruleOpenInPrivateWindow)
        XCTAssertNil(decoded.ruleCustomLaunchArgs)
        XCTAssertNil(decoded.ruleOpenAsNewInstance)
    }
}
