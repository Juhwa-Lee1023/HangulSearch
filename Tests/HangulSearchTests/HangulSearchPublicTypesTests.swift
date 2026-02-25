import XCTest
@testable import HangulSearch

final class HangulSearchPublicTypesTests: XCTestCase {
    func testHangulSearchOptionsDefaultsMatchLegacyFriendlyValues() {
        let options = HangulSearchOptions()
        
        XCTAssertNil(options.mode)
        XCTAssertNil(options.sortMode)
        XCTAssertNil(options.limit)
        XCTAssertEqual(options.offset, 0)
        XCTAssertEqual(options.minInputLength, 1)
        XCTAssertFalse(options.normalizeToNFC)
        XCTAssertEqual(options.emptyQueryBehavior, .returnEmpty)
    }
    
    func testHangulSearchOptionsStoresCustomValues() {
        let options = HangulSearchOptions(
            mode: .combined,
            sortMode: .editDistance,
            limit: 25,
            offset: 5,
            minInputLength: 2,
            normalizeToNFC: true,
            emptyQueryBehavior: .returnAll
        )
        
        XCTAssertEqual(options.mode, .combined)
        XCTAssertEqual(options.sortMode, .editDistance)
        XCTAssertEqual(options.limit, 25)
        XCTAssertEqual(options.offset, 5)
        XCTAssertEqual(options.minInputLength, 2)
        XCTAssertTrue(options.normalizeToNFC)
        XCTAssertEqual(options.emptyQueryBehavior, .returnAll)
    }
    
    func testHangulSearchHitStoresMatchMetadata() {
        let sampleItem = Person(name: "홍길동", age: 30)
        let hit = HangulSearchHit(
            item: sampleItem,
            matchKinds: [.fullMatch, .autocompleteMatch],
            matchPosition: 1,
            editDistance: 2
        )
        
        XCTAssertEqual(hit.item.name, "홍길동")
        XCTAssertEqual(hit.item.age, 30)
        XCTAssertEqual(hit.matchKinds, [.fullMatch, .autocompleteMatch])
        XCTAssertEqual(hit.matchPosition, 1)
        XCTAssertEqual(hit.editDistance, 2)
    }
}
