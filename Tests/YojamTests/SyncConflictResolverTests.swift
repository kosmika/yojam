import XCTest
@testable import Yojam
import YojamCore

final class SyncConflictResolverTests: XCTestCase {
    func testRemoteAdditionsAppear() {
        let local = [
            BrowserEntry(id: UUID(), bundleIdentifier: "com.local", displayName: "Local")
        ]
        let remoteId = UUID()
        let remote = [
            BrowserEntry(id: remoteId, bundleIdentifier: "com.remote", displayName: "Remote")
        ]
        let merged = SyncConflictResolver.mergeBrowserLists(local: local, remote: remote)
        XCTAssertEqual(merged.count, 2)
        XCTAssertTrue(merged.contains(where: { $0.id == remoteId }))
    }

    func testNewerTimestampWins() {
        let id = UUID()
        let old = BrowserEntry(
            id: id, bundleIdentifier: "com.test", displayName: "Old",
            lastModifiedAt: Date(timeIntervalSince1970: 1000))
        let new = BrowserEntry(
            id: id, bundleIdentifier: "com.test", displayName: "New",
            lastModifiedAt: Date(timeIntervalSince1970: 2000))
        let merged = SyncConflictResolver.mergeBrowserLists(local: [old], remote: [new])
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].displayName, "New")
    }

    func testDisjointListsMerge() {
        let a = BrowserEntry(bundleIdentifier: "com.a", displayName: "A")
        let b = BrowserEntry(bundleIdentifier: "com.b", displayName: "B")
        let merged = SyncConflictResolver.mergeBrowserLists(local: [a], remote: [b])
        XCTAssertEqual(merged.count, 2)
    }

    func testBrowserMergeDeduplicatesSameSyncedBrowserWithDifferentIds() {
        let localId = UUID()
        let remoteId = UUID()
        let local = BrowserEntry(
            id: localId,
            bundleIdentifier: "com.vivaldi.Vivaldi",
            displayName: "Vivaldi",
            position: 0,
            profileId: "Profile 1",
            profileName: "Personal",
            lastSeenAt: Date(timeIntervalSince1970: 1000))
        let remote = BrowserEntry(
            id: remoteId,
            bundleIdentifier: "com.vivaldi.Vivaldi",
            displayName: "Vivaldi",
            position: 1,
            profileId: "Profile 1",
            profileName: "Personal",
            lastSeenAt: Date(timeIntervalSince1970: 2000))

        let result = SyncConflictResolver.mergeBrowserListsWithAliases(
            local: [local],
            remote: [remote])

        XCTAssertEqual(result.entries.count, 1)
        XCTAssertEqual(result.entries[0].id, localId)
        XCTAssertEqual(result.idAliases[remoteId], localId)
    }

    func testBrowserMergeKeepsDistinctCustomArgumentInstances() {
        let first = BrowserEntry(
            bundleIdentifier: "org.chromium.Chromium",
            displayName: "Chromium Tmp 1",
            userDataDirectory: "/tmp/temporary1",
            openAsNewInstance: true)
        let second = BrowserEntry(
            bundleIdentifier: "org.chromium.Chromium",
            displayName: "Chromium Tmp 2",
            userDataDirectory: "/tmp/temporary2",
            openAsNewInstance: true)

        let merged = SyncConflictResolver.mergeBrowserLists(
            local: [first],
            remote: [second])

        XCTAssertEqual(merged.count, 2)
    }

    func testBrowserAliasRemapsRuleTargets() {
        let oldId = UUID()
        let newId = UUID()
        let rule = Rule(
            name: "Profile rule",
            matchType: .all,
            pattern: "",
            targetBundleId: "com.vivaldi.Vivaldi",
            targetAppName: "Vivaldi",
            targetBrowserEntryId: oldId)

        let remapped = SyncConflictResolver.remapRuleBrowserTargets(
            [rule],
            aliases: [oldId: newId])

        XCTAssertEqual(remapped[0].targetBrowserEntryId, newId)
    }

    func testRewriteRuleMerge() {
        let local = [URLRewriteRule(name: "Local", matchPattern: "a", replacement: "b", scope: .global)]
        let remote = [URLRewriteRule(name: "Remote", matchPattern: "c", replacement: "d", scope: .global)]
        let merged = SyncConflictResolver.mergeRewriteRules(local: local, remote: remote)
        XCTAssertEqual(merged.count, 2)
    }

    func testRewriteRuleMergeLocalWinsOnConflict() {
        let id = UUID()
        let local = [URLRewriteRule(id: id, name: "Local", matchPattern: "a", replacement: "b", scope: .global)]
        let remote = [URLRewriteRule(id: id, name: "Remote", matchPattern: "c", replacement: "d", scope: .global)]
        let merged = SyncConflictResolver.mergeRewriteRules(local: local, remote: remote)
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].name, "Local")
    }

    func testRuleMergeNewerWins() {
        let id = UUID()
        let old = Rule(id: id, name: "Old", matchType: .domain, pattern: "a.com",
                       targetBundleId: "com.test", targetAppName: "Test",
                       lastModifiedAt: Date(timeIntervalSince1970: 1000))
        let new = Rule(id: id, name: "New", matchType: .domain, pattern: "b.com",
                       targetBundleId: "com.test", targetAppName: "Test",
                       lastModifiedAt: Date(timeIntervalSince1970: 2000))
        let merged = SyncConflictResolver.mergeRules(local: [old], remote: [new])
        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].name, "New")
    }

    func testRuleMergePreservesMachineScopeEditFromOlderRemoteRule() {
        let id = UUID()
        let local = Rule(id: id, name: "Local renamed", matchType: .domain, pattern: "a.com",
                         targetBundleId: "com.test", targetAppName: "Test",
                         lastModifiedAt: Date(timeIntervalSince1970: 3000))
        let remote = Rule(id: id, name: "Original", matchType: .domain, pattern: "a.com",
                          targetBundleId: "com.test", targetAppName: "Test",
                          machineScopeIdentifiers: ["work-mac"],
                          machineScopeNames: ["work-mac": "Work Mac"],
                          lastModifiedAt: Date(timeIntervalSince1970: 2000))

        let merged = SyncConflictResolver.mergeRules(local: [local], remote: [remote])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged[0].name, "Local renamed")
        XCTAssertEqual(merged[0].machineScopeIdentifiers, ["work-mac"])
        XCTAssertEqual(merged[0].machineScopeNames?["work-mac"], "Work Mac")
    }

    func testRuleMergeAllowsNewerMachineScopeClear() {
        let id = UUID()
        let local = Rule(id: id, name: "Scoped", matchType: .domain, pattern: "a.com",
                         targetBundleId: "com.test", targetAppName: "Test",
                         machineScopeIdentifiers: ["work-mac"],
                         machineScopeNames: ["work-mac": "Work Mac"],
                         machineScopeModifiedAt: Date(timeIntervalSince1970: 1000),
                         lastModifiedAt: Date(timeIntervalSince1970: 1000))
        let remote = Rule(id: id, name: "Scoped", matchType: .domain, pattern: "a.com",
                          targetBundleId: "com.test", targetAppName: "Test",
                          machineScopeModifiedAt: Date(timeIntervalSince1970: 2000),
                          lastModifiedAt: Date(timeIntervalSince1970: 2000))

        let merged = SyncConflictResolver.mergeRules(local: [local], remote: [remote])

        XCTAssertEqual(merged.count, 1)
        XCTAssertNil(merged[0].machineScopeIdentifiers)
        XCTAssertNil(merged[0].machineScopeNames)
        XCTAssertEqual(merged[0].machineScopeModifiedAt, Date(timeIntervalSince1970: 2000))
    }
}
