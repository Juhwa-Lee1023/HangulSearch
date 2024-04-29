import XCTest
@testable import HangulSearch

final class HangulSearchTests: XCTestCase {
    var searchEngine: HangulSearch<Person>?
    
    override func setUp() {
        super.setUp()
        let itemDatas = JSONLoader().loadJSON(from: "people") ?? ""
        let items = JSONParser().parseJSON(itemDatas)
        searchEngine = HangulSearch(items: items, searchMode: .combined, keySelector: { $0.name }, isEqual:  { $0.age == $1.age })
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
        let results = searchEngine?.searchItems(input: "철수")
        let expectedNames = ["김철수", "이철수", "박철수", "최철수", "정철수", "강철수", "초철수", "윤철수", "장철수", "임철수"]
        let resultNames = results?.map { $0.name }
        XCTAssertEqual(resultNames, expectedNames, "검색 성공")
    }
    
    func testAutocompleteLogic() throws {
        let results = searchEngine?.searchItems(input: "쵳")
        let expectedNames = ["최철수"]
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
        let results = searchEngine?.searchItems(input: "철수")
        let expectedNames = ["김철수", "이철수", "박철수", "최철수", "정철수", "강철수", "초철수", "윤철수", "장철수", "임철수", "킴철수", "이철수"]
        let resultNames = results?.map { $0.name }
        XCTAssertEqual(resultNames, expectedNames, "검색 성공")
    }
}
