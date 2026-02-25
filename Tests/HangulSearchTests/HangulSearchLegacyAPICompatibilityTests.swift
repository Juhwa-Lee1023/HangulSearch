import XCTest
@testable import HangulSearch

final class HangulSearchLegacyAPICompatibilityTests: XCTestCase {
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
    
    func testLegacySearchItemsMatchesDefaultOptionsAcrossModesAndSortModes() {
        let modes: [HangulSearchMode] = [.containsMatch, .chosungAndFullMatch, .autocomplete, .combined]
        let sortModes: [SortMode] = [.none, .hangulOrder, .hangulOrderReversed, .editDistance, .matchPosition]
        let queries = ["철수", "ㅊㅅ", "힇", "LeE", ""]
        
        for mode in modes {
            for sortMode in sortModes {
                let engine = makeEngine(items: items, searchMode: mode, sortMode: sortMode)
                
                for query in queries {
                    let legacy = engine.searchItems(input: query).map(\.name)
                    let withDefaultOptions = engine.searchItems(
                        input: query,
                        options: HangulSearchOptions()
                    ).map(\.name)
                    
                    XCTAssertEqual(
                        legacy,
                        withDefaultOptions,
                        "legacy compatibility mismatch - mode: \(mode), sortMode: \(sortMode), query: \(query)"
                    )
                }
            }
        }
    }
    
    func testLegacyMutationAPIsStillWorkInSequence() {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        
        engine.addItems(items: [
            Person(name: "신규철수", age: 731),
            Person(name: "LeeCompat", age: 941)
        ])
        XCTAssertTrue(engine.searchItems(input: "신규").map(\.name).contains("신규철수"))
        
        engine.changeSearchMode(mode: .containsMatch)
        XCTAssertTrue(engine.searchItems(input: "ㅅㄱ").isEmpty)
        
        engine.changeSearchMode(mode: .chosungAndFullMatch)
        XCTAssertTrue(engine.searchItems(input: "ㅅㄱ").map(\.name).contains("신규철수"))
        
        engine.changeSortMode(mode: .hangulOrder)
        let sortedNames = engine.searchItems(input: "철수").map(\.name)
        let expected = sortedNames.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        XCTAssertEqual(sortedNames, expected)
        
        engine.changeKeySelector { String($0.age) }
        XCTAssertEqual(engine.searchItems(input: "731").map(\.name), ["신규철수"])
        
        engine.changeItems(items: [Person(name: "호환성테스트", age: 99)])
        XCTAssertTrue(engine.searchItems(input: "731").isEmpty)
        engine.changeKeySelector { $0.name }
        XCTAssertEqual(engine.searchItems(input: "호환성").map(\.age), [99])
    }
    
    func testLegacyCombinedDedupRuleRemainsUnchanged() {
        let duplicatedItems = [
            Person(name: "홍길동", age: 20),
            Person(name: "홍길동", age: 20),
            Person(name: "홍길동", age: 21)
        ]
        
        let defaultEngine = makeEngine(
            items: duplicatedItems,
            searchMode: .combined,
            sortMode: .none,
            isEqual: nil
        )
        let customizedEngine = makeEngine(
            items: duplicatedItems,
            searchMode: .combined,
            sortMode: .none,
            isEqual: { $0.age == $1.age }
        )
        
        XCTAssertEqual(defaultEngine.searchItems(input: "홍").count, 1)
        XCTAssertEqual(customizedEngine.searchItems(input: "홍").count, 2)
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
