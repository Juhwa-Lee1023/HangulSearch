import XCTest
@testable import HangulSearch

final class HangulSearchTests: XCTestCase {
    var searchEngine: HangulSearch<Person>?
    
    override func setUp() {
        super.setUp()
        let itemDatas = JSONLoader().loadJSON(from: "people") ?? ""
        let items = JSONParser().parseJSON(itemDatas)
        searchEngine = HangulSearch(items: items, searchMode: .combined, sortMode: .matchPosition, keySelector: { $0.name }, isEqual:  { $0.age == $1.age })
    }
    
    override func tearDown() {
        searchEngine = nil
        super.tearDown()
    }
    
    func testSearchByChosung() throws {
        let results = searchEngine?.searchItems(input: "ㅊㅅ")
        let expectedNames = ["김철수", "이철수", "박철수", "최철수", "최성수", "최상욱", "정철수", "강철수", "초철수", "초성수", "초상욱", "윤철수", "장철수", "임철수"]
        let resultNames = results?.map { $0.name }
        XCTAssertEqual(resultNames, expectedNames, "초성 검색 성공")
    }
    
    func testSearchByFullString() throws {
        let results = searchEngine?.searchItems(input: "이")
        let expectedNames = ["이민지", "이주화", "이철수", "이성수", "이희훈", "이상욱", "이영희", "이기석", "이나훈", "이아임", "김아이", "박아임", "최아임", "정아임", "강아임", "초아임", "윤아임", "장아임", "임민지", "임주화", "임철수", "임성수", "임희훈", "임상욱", "임영희", "임기석", "임나훈", "임아임"]
        let resultNames = results?.map { $0.name }
        XCTAssertEqual(resultNames, expectedNames, "검색 성공")
    }
    
    func testAutocompleteLogic() throws {
        let results = searchEngine?.searchItems(input: "힇")
        let expectedNames = ["김희훈", "이희훈", "박희훈", "최희훈", "정희훈", "강희훈", "초희훈", "윤희훈", "장희훈", "임희훈"]
        let resultNames = results?.map { $0.name }
        XCTAssertEqual(resultNames, expectedNames, "검색 성공")
    }
    
    func testEnglish() throws {
        let results = searchEngine?.searchItems(input: "test")
        XCTAssertTrue(results?.isEmpty ?? false, "비어 있음")
    }
    
    // 빈 문자열 입력에 대한 테스트
    func testEmptyInput() throws {
        let results = searchEngine?.searchItems(input: "")
        XCTAssertTrue(results?.isEmpty ?? false, "비어 있음")
    }
    
    // 데이터 추가 후 검색 테스트
    func testAddDataLogic() throws {
        searchEngine?.addItems(items: [Person(name: "킴철수", age: 29), Person(name: "이철수", age: 29)])
        let results = searchEngine?.searchItems(input: "초")
        let expectedNames = ["초민지", "초주화", "초철수", "초성수", "초희훈", "초상욱", "초영희", "초기석", "초나훈", "초아임"]
        let resultNames = results?.map { $0.name }
        XCTAssertEqual(resultNames, expectedNames, "검색 성공")
    }
}
