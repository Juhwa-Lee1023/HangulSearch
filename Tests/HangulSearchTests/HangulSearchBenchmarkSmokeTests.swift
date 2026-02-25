import Foundation
import CoreFoundation
import XCTest
@testable import HangulSearch

final class HangulSearchBenchmarkSmokeTests: XCTestCase {
    func testCombinedModeP95SmokeSynthetic10k() throws {
        let dataset = makeSyntheticDataset(count: 10_000)
        let engine = HangulSearch(
            items: dataset,
            searchMode: .combined,
            sortMode: .matchPosition,
            keySelector: { $0 }
        )
        let queries = [
            "김", "민", "ㅊㅅ", "ㄱㅊ", "가", "테",
            "Lee", "search", "훈", "도", "ㅎㅁ", "완성"
        ]
        
        var latenciesMs = [Double]()
        latenciesMs.reserveCapacity(queries.count * 3)
        
        for _ in 0..<3 {
            for query in queries {
                let startedAt = CFAbsoluteTimeGetCurrent()
                _ = engine.searchItems(input: query)
                let elapsedMs = (CFAbsoluteTimeGetCurrent() - startedAt) * 1000
                latenciesMs.append(elapsedMs)
            }
        }
        
        XCTAssertFalse(latenciesMs.isEmpty)
        XCTAssertFalse(engine.searchItems(input: "김").isEmpty)
        
        let p95 = percentile(of: latenciesMs, p: 0.95)
        let formattedP95 = String(format: "%.3f", p95)
        print(
            "benchmark_smoke synthetic_10k: sample=\(latenciesMs.count), p95_ms=\(formattedP95)"
        )
    }
    
    private func makeSyntheticDataset(count: Int) -> [String] {
        let seeds = [
            "김철수", "이영희", "박민수", "최지훈", "강하늘", "윤서연",
            "장도현", "임수아", "한가람", "홍길동", "초성검색", "자동완성",
            "테스트데이터", "검색엔진", "HangulSearch", "LeeJuhwa"
        ]
        
        return (0..<count).map { index in
            let base = seeds[index % seeds.count]
            switch index % 5 {
            case 0:
                return "\(base)\(index)"
            case 1:
                return "가\(base)\(index % 17)"
            case 2:
                return "\(base)테스트\(index % 31)"
            case 3:
                return "검색\(base)\(index % 13)"
            default:
                return "\(base) search \(index % 23)"
            }
        }
    }
    
    private func percentile(of values: [Double], p: Double) -> Double {
        guard !values.isEmpty else {
            return 0
        }
        
        let clampedP = min(max(p, 0), 1)
        let sorted = values.sorted()
        let index = Int((Double(sorted.count - 1) * clampedP).rounded(.up))
        
        return sorted[index]
    }
}
