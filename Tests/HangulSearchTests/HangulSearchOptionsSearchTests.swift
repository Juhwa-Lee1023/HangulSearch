import XCTest
@testable import HangulSearch

final class HangulSearchOptionsSearchTests: XCTestCase {
    private var items: [Person] = []
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let itemDatas = try XCTUnwrap(JSONLoader().loadJSON(from: "people"))
        items = JSONParser().parseJSON(itemDatas)
    }
    
    override func tearDownWithError() throws {
        items = []
        try super.tearDownWithError()
    }
    
    func testDefaultOptionsMatchesLegacySearchItems() throws {
        let engine = makeEngine(items: items, searchMode: .combined, sortMode: .matchPosition)
        let inputs = ["ㅊㅅ", "이", "힇", "LeE", ""]
        
        for input in inputs {
            let legacy = engine.searchItems(input: input).map(\.name)
            let withDefaultOptions = engine.searchItems(input: input, options: HangulSearchOptions()).map(\.name)
            XCTAssertEqual(legacy, withDefaultOptions)
        }
    }
    
    func testOptionsCanOverrideSearchMode() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        
        let legacy = engine.searchItems(input: "ㅊㅅ")
        let overridden = engine.searchItems(
            input: "ㅊㅅ",
            options: HangulSearchOptions(mode: .chosungAndFullMatch)
        )
        
        XCTAssertTrue(legacy.isEmpty)
        XCTAssertFalse(overridden.isEmpty)
    }
    
    func testOptionsCanOverrideSortMode() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let unsortedNames = engine.searchItems(input: "철수").map(\.name)
        
        let sortedNames = engine.searchItems(
            input: "철수",
            options: HangulSearchOptions(sortMode: .hangulOrder)
        ).map(\.name)
        
        let expected = unsortedNames.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        
        XCTAssertEqual(sortedNames, expected)
    }
    
    func testMinInputLengthBlocksShortInput() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let options = HangulSearchOptions(minInputLength: 2)
        
        XCTAssertTrue(engine.searchItems(input: "이", options: options).isEmpty)
        XCTAssertFalse(engine.searchItems(input: "이민", options: options).isEmpty)
    }
    
    func testEmptyQueryBehaviorReturnAllSupportsPagination() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let options = HangulSearchOptions(
            offset: 1,
            minInputLength: 1,
            emptyQueryBehavior: .returnAll
        )
        let limitedOptions = HangulSearchOptions(
            limit: 2,
            offset: 1,
            minInputLength: 1,
            emptyQueryBehavior: .returnAll
        )
        
        let expectedAll = Array(items.dropFirst(1)).map(\.name)
        let expectedLimited = Array(items.dropFirst(1).prefix(2)).map(\.name)
        
        let allResults = engine.searchItems(input: "", options: options).map(\.name)
        let limitedResults = engine.searchItems(input: "", options: limitedOptions).map(\.name)
        
        XCTAssertEqual(allResults, expectedAll)
        XCTAssertEqual(limitedResults, expectedLimited)
    }
    
    func testOffsetOutOfRangeReturnsEmpty() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let options = HangulSearchOptions(
            offset: items.count + 1,
            emptyQueryBehavior: .returnAll
        )
        
        XCTAssertTrue(engine.searchItems(input: "", options: options).isEmpty)
    }
    
    func testNonPositiveLimitReturnsEmptyWhenPaginationApplied() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let options = HangulSearchOptions(
            limit: 0,
            emptyQueryBehavior: .returnAll
        )
        
        XCTAssertTrue(engine.searchItems(input: "", options: options).isEmpty)
    }
    
    func testNormalizeToNFCEnablesChosungMatchForDecomposedHangul() throws {
        let decomposedName = "\u{1100}\u{1161}\u{11BC}\u{1112}\u{1174}\u{1112}\u{116E}\u{11AB}"
        let decomposedItems = [Person(name: decomposedName, age: 30)]
        let engine = makeEngine(items: decomposedItems, searchMode: .chosungAndFullMatch, sortMode: .none)
        
        let withoutNormalization = engine.searchItems(input: "ㄱㅎㅎ")
        let withNormalization = engine.searchItems(
            input: "ㄱㅎㅎ",
            options: HangulSearchOptions(normalizeToNFC: true)
        )
        
        XCTAssertTrue(withoutNormalization.isEmpty)
        XCTAssertEqual(withNormalization.map(\.age), [30])
    }
    
    private func makeEngine(
        items: [Person],
        searchMode: HangulSearchMode,
        sortMode: SortMode,
        keySelector: @escaping (Person) -> String = { $0.name },
        isEqual: ((Person, Person) -> Bool)? = nil
    ) -> HangulSearch<Person> {
        HangulSearch(
            items: items,
            searchMode: searchMode,
            sortMode: sortMode,
            keySelector: keySelector,
            isEqual: isEqual
        )
    }
}
