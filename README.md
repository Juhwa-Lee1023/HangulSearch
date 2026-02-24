# HangulSearch
[![stability-beta](https://img.shields.io/badge/stability-beta-33bbff.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#beta)

`HangulSearch`는 Swift 기반 한글 검색 라이브러리입니다.  
초성 검색, 일반 문자열 검색, 자동 완성 검색, 복합 검색을 지원하며 검색 결과 정렬 기능을 함께 제공합니다.

## 지원 환경
- iOS 11.0 이상
- macOS 10.13 이상
- watchOS 4.0 이상
- tvOS 11.0 이상

## 설치
### Xcode에서 추가
1. Xcode 상단 메뉴에서 **File > Swift Packages > Add Package Dependency...**를 선택합니다.
2. 다음 저장소 URL을 입력합니다.
   - `https://github.com/Juhwa-Lee1023/HangulSearch`
3. 브랜치 또는 버전 규칙을 선택합니다.
4. 패키지 추가를 완료합니다.

## 핵심 타입
### 초기화
```swift
public init(
    items: [T],
    searchMode: HangulSearchMode = .chosungAndFullMatch,
    sortMode: SortMode = .none,
    keySelector: @escaping (T) -> String,
    isEqual: ((T, T) -> Bool)? = nil
)
```

### 파라미터 설명
- `items`: 검색 대상 데이터 배열
- `searchMode`: 검색 방식
- `sortMode`: 결과 정렬 방식
- `keySelector`: 각 항목에서 검색 기준 문자열을 추출하는 클로저
- `isEqual`: `combined` 모드에서 중복 제거 기준을 확장하기 위한 비교 클로저

## 검색 모드
### `containsMatch`
- `keySelector(item)` 값에 입력 문자열이 포함되는 항목을 검색합니다.
- 문자열 비교는 대소문자를 구분하지 않습니다.

### `chosungAndFullMatch`
- 입력이 순수 초성(예: `ㅊㅅ`)인 경우 초성 기반 검색을 수행합니다.
- 입력이 초성이 아닌 경우 `containsMatch`와 동일하게 동작합니다.

### `autocomplete`
- 입력 문자열과 항목 문자열을 한글 자모로 분해한 뒤 포함 여부를 비교합니다.
- 오타 또는 조합 입력에 대한 검색 유연성이 높습니다.

### `combined`
- 다음 결과를 결합하여 반환합니다.
  - 전체 문자열 검색
  - 초성 검색(입력이 순수 초성인 경우만)
  - 자동 완성 검색
- 중복 항목은 `keySelector` 기준으로 제거합니다.
- `isEqual`이 제공되면 `keySelector` 값이 같은 항목에 대해 추가 비교를 수행합니다.

## 정렬 모드
### `none`
- 입력 데이터 순서를 유지합니다.

### `hangulOrder`
- 검색 결과를 한글 자모 순서(오름차순)로 정렬합니다.

### `hangulOrderReversed`
- 검색 결과를 한글 자모 순서(내림차순)로 정렬합니다.

### `editDistance`
- 검색어와 항목 문자열의 Levenshtein distance를 기준으로 정렬합니다.
- 거리 값이 작은 항목이 우선합니다.

### `matchPosition`
- 항목 내에서 검색어가 처음 일치하는 위치를 기준으로 정렬합니다.
- 일치 위치가 앞설수록 우선합니다.

## 공개 메서드
### 검색 실행
```swift
public func searchItems(input: String) -> [T]
```
- 빈 문자열 입력 시 빈 배열을 반환합니다.

### 데이터 교체
```swift
public func changeItems(items: [T])
```

### 데이터 추가
```swift
public func addItems(items: [T])
```

### 검색 모드 변경
```swift
public func changeSearchMode(mode: HangulSearchMode)
```

### 검색 키 선택자 변경
```swift
public func changeKeySelector(keySelector: @escaping (T) -> String)
```

### 정렬 모드 변경
```swift
public func changeSortMode(mode: SortMode)
```

## 사용 예시
### 문자열 배열 검색
```swift
import HangulSearch

let fruits = ["사과", "바나나", "포도"]
let engine = HangulSearch(
    items: fruits,
    searchMode: .containsMatch,
    sortMode: .none,
    keySelector: { $0 }
)

let results = engine.searchItems(input: "과")
```

### 객체 배열 검색
```swift
import HangulSearch

struct Person {
    let name: String
    let age: Int
}

let people = [
    Person(name: "철수", age: 25),
    Person(name: "철수", age: 30),
    Person(name: "영희", age: 22)
]

let engine = HangulSearch(
    items: people,
    searchMode: .combined,
    sortMode: .matchPosition,
    keySelector: { $0.name },
    isEqual: { $0.age == $1.age }
)

let results = engine.searchItems(input: "ㅊㅅ")
```

## 참고 자료
- [테스트 데이터](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/Tests/HangulSearchTests/MockData/people.json)
- [테스트 코드](https://github.com/Juhwa-Lee1023/HangulSearch/blob/main/Tests/HangulSearchTests/HangulSearchTests.swift)

## 데모 영상
- 초성 검색: https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/9f5e0f28-d8ab-4010-9b58-79eafb35b798
- 전체 문자열 검색: https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/8bdc8091-03d9-4c84-b56a-8f58cc5ef8f1
- 자동 완성 검색: https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/d8d3693b-0dc0-49e9-8117-df131ec20154
- 종합 검색 모드: https://github.com/Juhwa-Lee1023/HangulSearch/assets/63584245/94652207-6896-488f-af8c-db273312becd

## 기여
이슈 등록 또는 Pull Request를 통해 기여할 수 있습니다.

## 라이선스
이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
