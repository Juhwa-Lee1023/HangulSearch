import XCTest
@testable import HangulSearch

final class HangulSearchHitsTests: XCTestCase {
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
    
    func testSearchHitsContainsModeAssignsFullMatchKind() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let hits = engine.searchHits(input: "철수", options: HangulSearchOptions())
        
        XCTAssertFalse(hits.isEmpty)
        XCTAssertTrue(hits.allSatisfy { $0.matchKinds == [.fullMatch] })
    }
    
    func testSearchHitsChosungAndFullMatchAssignsChosungKindForPureChosungInput() throws {
        let engine = makeEngine(items: items, searchMode: .chosungAndFullMatch, sortMode: .none)
        let hits = engine.searchHits(input: "ㅊㅅ", options: HangulSearchOptions())
        
        XCTAssertFalse(hits.isEmpty)
        XCTAssertTrue(hits.allSatisfy { $0.matchKinds == [.chosungMatch] })
    }
    
    func testSearchHitsAutocompleteModeAssignsAutocompleteKind() throws {
        let engine = makeEngine(items: items, searchMode: .autocomplete, sortMode: .none)
        let hits = engine.searchHits(input: "힇", options: HangulSearchOptions())
        
        XCTAssertFalse(hits.isEmpty)
        XCTAssertTrue(hits.allSatisfy { $0.matchKinds == [.autocompleteMatch] })
    }
    
    func testSearchHitsCombinedMergesMatchKindsForSameResult() throws {
        let engine = makeEngine(
            items: [Person(name: "홍길동", age: 30)],
            searchMode: .combined,
            sortMode: .none
        )
        
        let hits = engine.searchHits(input: "홍", options: HangulSearchOptions())
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits[0].matchKinds, [.fullMatch, .autocompleteMatch])
    }
    
    func testSearchHitsCalculatesMatchPositionAndEditDistance() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let input = "철수"
        let hits = engine.searchHits(input: input, options: HangulSearchOptions())
        
        XCTAssertFalse(hits.isEmpty)
        
        for hit in hits {
            let expectedPosition = hit.item.name.range(of: input, options: .caseInsensitive)?
                .lowerBound
                .utf16Offset(in: hit.item.name)
            XCTAssertEqual(hit.matchPosition, expectedPosition)
            
            let expectedDistance = levenshteinDistance(from: hit.item.name, to: input)
            XCTAssertEqual(hit.editDistance, expectedDistance)
        }
    }
    
    func testSearchHitsRespectsSortAndPagination() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let options = HangulSearchOptions(sortMode: .hangulOrder, limit: 3, offset: 2)
        
        let itemsResult = engine.searchItems(input: "철수", options: options).map(\.name)
        let hitsResult = engine.searchHits(input: "철수", options: options).map(\.item.name)
        
        XCTAssertEqual(hitsResult, itemsResult)
    }
    
    func testSearchHitsReturnAllForEmptyQueryHasNoMatchMetadata() throws {
        let engine = makeEngine(items: items, searchMode: .containsMatch, sortMode: .none)
        let options = HangulSearchOptions(limit: 2, emptyQueryBehavior: .returnAll)
        
        let hits = engine.searchHits(input: "", options: options)
        XCTAssertEqual(hits.count, 2)
        XCTAssertTrue(hits.allSatisfy { $0.matchKinds.isEmpty })
        XCTAssertTrue(hits.allSatisfy { $0.matchPosition == nil })
        XCTAssertTrue(hits.allSatisfy { $0.editDistance == nil })
    }
    
    func testSearchHitsNormalizeToNFCEnablesDecomposedChosungMatch() throws {
        let decomposedName = "\u{1100}\u{1161}\u{11BC}\u{1112}\u{1174}\u{1112}\u{116E}\u{11AB}"
        let decomposedItems = [Person(name: decomposedName, age: 30)]
        let engine = makeEngine(items: decomposedItems, searchMode: .chosungAndFullMatch, sortMode: .none)
        
        let withoutNormalization = engine.searchHits(input: "ㄱㅎㅎ", options: HangulSearchOptions())
        let withNormalization = engine.searchHits(
            input: "ㄱㅎㅎ",
            options: HangulSearchOptions(normalizeToNFC: true)
        )
        
        XCTAssertTrue(withoutNormalization.isEmpty)
        XCTAssertEqual(withNormalization.count, 1)
        XCTAssertEqual(withNormalization[0].matchKinds, [.chosungMatch])
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
