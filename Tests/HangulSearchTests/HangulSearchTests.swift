import XCTest
@testable import HangulSearch

final class HangulSearchTests: XCTestCase {
    private var items: [Person] = []
    private var searchEngine: HangulSearch<Person>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        let itemDatas = try XCTUnwrap(JSONLoader().loadJSON(from: "people"))
        items = JSONParser().parseJSON(itemDatas)
        searchEngine = makeEngine(
            items: items,
            searchMode: .combined,
            sortMode: .matchPosition,
            keySelector: { $0.name },
            isEqual: { $0.age == $1.age }
        )
    }
    
    override func tearDownWithError() throws {
        searchEngine = nil
        items = []
        try super.tearDownWithError()
    }
    
    func testSearchByChosungInCombinedMode() throws {
        let results = searchEngine.searchItems(input: "ㅊㅅ")
        let expectedNames = ["김철수", "이철수", "박철수", "최철수", "최성수", "최상욱", "정철수", "강철수", "초철수", "초성수", "초상욱", "윤철수", "장철수", "임철수"]
        XCTAssertEqual(results.map(\.name), expectedNames)
    }
    
    func testSearchByFullStringInCombinedMode() throws {
        let results = searchEngine.searchItems(input: "이")
        let resultNames = results.map(\.name)
        XCTAssertTrue(resultNames.contains("이민지"))
        XCTAssertTrue(resultNames.contains("김아이"))
        XCTAssertTrue(resultNames.contains("임아임"))
    }
    
    func testAutocompleteInCombinedMode() throws {
        let results = searchEngine.searchItems(input: "힇")
        let expectedNames = ["김희훈", "이희훈", "박희훈", "최희훈", "정희훈", "강희훈", "초희훈", "윤희훈", "장희훈", "임희훈"]
        XCTAssertEqual(results.map(\.name), expectedNames)
    }
    
    func testEnglishCaseInsensitiveSearchInCombinedMode() throws {
        let results = searchEngine.searchItems(input: "LeE")
        let expectedNames = ["LeeJuhwa", "LeeTest", "LeeSun"]
        XCTAssertEqual(results.map(\.name), expectedNames)
    }
    
    func testContainsMatchModeReturnsExpectedItems() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let results = engine.searchItems(input: "철수")
        let expectedNames = ["김철수", "이철수", "박철수", "최철수", "정철수", "강철수", "초철수", "윤철수", "장철수", "임철수"]
        XCTAssertEqual(results.map(\.name), expectedNames)
    }
    
    func testChosungAndFullMatchUsesFullMatchForNonChosungInput() throws {
        let engine = makeEngine(items: items, searchMode: .chosungAndFullMatch, sortMode: .none)
        let results = engine.searchItems(input: "철수")
        let expectedNames = ["김철수", "이철수", "박철수", "최철수", "정철수", "강철수", "초철수", "윤철수", "장철수", "임철수"]
        XCTAssertEqual(results.map(\.name), expectedNames)
    }
    
    func testHangulOrderSortMode() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .hangulOrder)
        let results = engine.searchItems(input: "철수").map(\.name)
        let expected = results.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        XCTAssertEqual(results, expected)
    }
    
    func testHangulOrderReversedSortMode() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .hangulOrderReversed)
        let results = engine.searchItems(input: "철수").map(\.name)
        let expected = results.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedDescending
        }
        XCTAssertEqual(results, expected)
    }
    
    func testEditDistanceSortModeIsMonotonic() throws {
        let engine = makeEngine(items: items, searchMode: .combined, sortMode: .editDistance)
        let input = "이"
        let results = engine.searchItems(input: input)
        
        var previousDistance = Int.min
        for person in results {
            let currentDistance = levenshteinDistance(from: person.name, to: input)
            XCTAssertGreaterThanOrEqual(currentDistance, previousDistance)
            previousDistance = currentDistance
        }
    }
    
    func testMatchPositionSortModeIsMonotonic() throws {
        let engine = makeEngine(items: items, searchMode: .combined, sortMode: .matchPosition)
        let input = "이"
        let results = engine.searchItems(input: input)
        
        var previousPosition = Int.min
        for person in results {
            let currentPosition = matchPosition(of: input, in: person.name)
            XCTAssertGreaterThanOrEqual(currentPosition, previousPosition)
            previousPosition = currentPosition
        }
    }
    
    func testNoneSortModeKeepsOriginalOrder() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let results = engine.searchItems(input: "철수").map(\.name)
        let expected = items
            .filter { $0.name.localizedCaseInsensitiveContains("철수") }
            .map(\.name)
        XCTAssertEqual(results, expected)
    }
    
    func testEmptyInputReturnsEmptyAcrossModes() throws {
        let modes: [HangulSearchMode] = [.containsMatch, .chosungAndFullMatch, .autocomplete, .combined]
        
        for mode in modes {
            let engine = makeEngine(items: items, searchMode: mode, sortMode: .none)
            XCTAssertTrue(engine.searchItems(input: "").isEmpty)
        }
    }
    
    func testChangeItemsReplacesSearchSpace() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        XCTAssertFalse(engine.searchItems(input: "철수").isEmpty)
        
        let newItems = [Person(name: "홍길동", age: 30), Person(name: "김영희", age: 22)]
        engine.changeItems(items: newItems)
        
        XCTAssertTrue(engine.searchItems(input: "철수").isEmpty)
        XCTAssertEqual(engine.searchItems(input: "홍").map(\.name), ["홍길동"])
    }
    
    func testChangeSearchModeReprocessesCaches() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        XCTAssertTrue(engine.searchItems(input: "ㅊㅅ").isEmpty)
        
        engine.changeSearchMode(mode: .chosungAndFullMatch)
        XCTAssertFalse(engine.searchItems(input: "ㅊㅅ").isEmpty)
    }
    
    func testChangeKeySelectorReprocessesItems() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        XCTAssertTrue(engine.searchItems(input: "33").isEmpty)
        
        engine.changeKeySelector { String($0.age) }
        let results = engine.searchItems(input: "33").map(\.name)
        let expected = items
            .filter { String($0.age).localizedCaseInsensitiveContains("33") }
            .map(\.name)
        XCTAssertEqual(results, expected)
    }
    
    func testChangeSortModeUpdatesOrdering() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let original = engine.searchItems(input: "철수").map(\.name)
        
        engine.changeSortMode(mode: .hangulOrder)
        let sortedResults = engine.searchItems(input: "철수").map(\.name)
        let expected = original.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        
        XCTAssertEqual(sortedResults, expected)
    }
    
    func testCombinedModeDeduplicatesWithIsEqual() throws {
        let duplicatedItems = [
            Person(name: "홍길동", age: 20),
            Person(name: "홍길동", age: 20),
            Person(name: "홍길동", age: 21)
        ]
        
        let engine = makeEngine(
            items: duplicatedItems,
            searchMode: .combined,
            sortMode: .none,
            isEqual: { $0.age == $1.age }
        )
        
        let results = engine.searchItems(input: "홍")
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.map(\.age).sorted(), [20, 21])
    }
    
    func testAddDataLogic() throws {
        searchEngine.addItems(items: [Person(name: "킴철수", age: 29), Person(name: "이철수", age: 29)])
        let results = searchEngine.searchItems(input: "초")
        let expectedNames = ["초민지", "초주화", "초철수", "초성수", "초희훈", "초상욱", "초영희", "초기석", "초나훈", "초아임"]
        XCTAssertEqual(results.map(\.name), expectedNames)
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
    
    private func matchPosition(of input: String, in target: String) -> Int {
        target.range(of: input, options: .caseInsensitive)?.lowerBound.utf16Offset(in: target) ?? Int.max
    }
    
    private func levenshteinDistance(from s1: String, to s2: String) -> Int {
        let s1Chars = Array(s1)
        let s2Chars = Array(s2)
        let m = s1Chars.count
        let n = s2Chars.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var distanceMatrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m {
            distanceMatrix[i][0] = i
        }
        for j in 0...n {
            distanceMatrix[0][j] = j
        }
        
        for i in 1...m {
            for j in 1...n {
                let cost = (s1Chars[i - 1].lowercased() == s2Chars[j - 1].lowercased()) ? 0 : 1
                distanceMatrix[i][j] = min(
                    distanceMatrix[i - 1][j] + 1,
                    distanceMatrix[i][j - 1] + 1,
                    distanceMatrix[i - 1][j - 1] + cost
                )
            }
        }
        
        return distanceMatrix[m][n]
    }
}
