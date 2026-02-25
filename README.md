# HangulSearch
[![stability-beta](https://img.shields.io/badge/stability-beta-33bbff.svg)](https://github.com/mkenney/software-guides/blob/master/STABILITY-BADGES.md#beta)

Swift에서 한글 검색을 구현할 때 바로 사용할 수 있는 라이브러리입니다.

## 설치

### Xcode (Swift Package Manager)

1. `File > Swift Packages > Add Package Dependency...`
2. 저장소 URL 입력: `https://github.com/Juhwa-Lee1023/HangulSearch`
3. 버전 규칙 선택 후 추가

## 기본 사용

```swift
import HangulSearch

struct Person {
    let name: String
    let age: Int
}

let people = [
    Person(name: "김철수", age: 25),
    Person(name: "이철수", age: 30),
    Person(name: "이영희", age: 22)
]

let engine = HangulSearch(
    items: people,
    searchMode: .combined,
    sortMode: .none,
    keySelector: { $0.name }
)

let results = engine.searchItems(input: "철수")
print(results.map(\.name))
```

## 검색 모드

사용 가능한 검색 모드:

- `.containsMatch`: 입력 문자열이 원문에 포함되면 매칭합니다. 일반적인 부분 문자열 검색에 사용합니다.
- `.chosungAndFullMatch`: 입력이 순수 초성(예: `ㅊㅅ`)이면 초성 검색으로, 그 외에는 일반 문자열 검색으로 동작합니다.
- `.autocomplete`: 입력 문자열을 자동완성 형태로 해석해 매칭합니다.
- `.combined`: `contains/chosung/autocomplete` 결과를 합쳐 반환합니다.

추천 사용 케이스:

1. `.containsMatch`: 주소록/회원 목록처럼 "일부 문자열 포함" 검색이 필요한 경우
2. `.chosungAndFullMatch`: 초성 검색과 일반 검색을 하나의 입력창에서 함께 처리하고 싶은 경우
3. `.autocomplete`: 검색창 입력 중간 단계에서 후보를 빠르게 보여주고 싶은 경우
4. `.combined`: 사용자가 초성/완성형/자동완성 패턴을 섞어 입력하는 통합 검색창

실전 예시:

```swift
// containsMatch: 이름 일부 검색
let containsCase = containsEngine.searchItems(input: "영희")

// chosungAndFullMatch: 초성 또는 일반 검색을 같은 창에서 처리
let chosungCase = chosungEngine.searchItems(input: "ㅊㅅ")

// autocomplete: 타이핑 중 추천 목록
let autocompleteCase = autoEngine.searchItems(input: "철")

// combined: 입력 패턴이 섞여도 하나의 모드로 처리
let combinedCase = engine.searchItems(input: "ㅊㅅ")
```

```swift
// 1) 문자열 포함 검색
let containsEngine = HangulSearch(
    items: people,
    searchMode: .containsMatch,
    sortMode: .none,
    keySelector: { $0.name }
)
let containsResults = containsEngine.searchItems(input: "철수")

// 2) 초성 검색 (입력이 순수 초성일 때)
let chosungEngine = HangulSearch(
    items: people,
    searchMode: .chosungAndFullMatch,
    sortMode: .none,
    keySelector: { $0.name }
)
let chosungResults = chosungEngine.searchItems(input: "ㅊㅅ")

// 3) 자동 완성 검색
let autoEngine = HangulSearch(
    items: people,
    searchMode: .autocomplete,
    sortMode: .none,
    keySelector: { $0.name }
)
let autoResults = autoEngine.searchItems(input: "철")

// 4) 종합 검색
let combinedResults = engine.searchItems(input: "ㅊㅅ")
```

## 정렬 사용

```swift
let sortedEngine = HangulSearch(
    items: people,
    searchMode: .containsMatch,
    sortMode: .matchPosition,
    keySelector: { $0.name }
)

let sorted = sortedEngine.searchItems(input: "이")
```

사용 가능한 정렬 모드:

- `.none`: 검색 결과 순서를 변경하지 않습니다.
- `.hangulOrder`: 한글 사전순(오름차순)으로 정렬합니다.
- `.hangulOrderReversed`: 한글 사전순(내림차순)으로 정렬합니다.
- `.editDistance`: 입력과의 편집 거리(Levenshtein)가 작은 항목을 우선합니다.
- `.matchPosition`: 매칭 시작 위치가 앞쪽인 항목을 우선합니다.

추천 사용 케이스:

1. `.none`: 서버 랭킹이나 원본 데이터 순서를 그대로 유지해야 하는 경우
2. `.hangulOrder`: 가나다순 목록 화면처럼 알파벳/한글 정렬이 필요한 경우
3. `.hangulOrderReversed`: 역순 목록(하단 문자부터)으로 탐색하는 화면
4. `.editDistance`: 오타가 많은 자유 입력 검색에서 유사도 중심 정렬이 필요한 경우
5. `.matchPosition`: 접두어 매칭(앞부분 일치) 결과를 우선 노출하고 싶은 경우

실전 예시:

```swift
let noneSorted = HangulSearch(
    items: people,
    searchMode: .containsMatch,
    sortMode: .none,
    keySelector: { $0.name }
).searchItems(input: "이")

let hangulSorted = HangulSearch(
    items: people,
    searchMode: .containsMatch,
    sortMode: .hangulOrder,
    keySelector: { $0.name }
).searchItems(input: "이")

let editDistanceSorted = HangulSearch(
    items: people,
    searchMode: .containsMatch,
    sortMode: .editDistance,
    keySelector: { $0.name }
).searchItems(input: "이쳘수")
```

## 옵션 API 사용

자주 쓰는 옵션:

- `mode`: 엔진 기본 모드 대신 이번 검색에만 모드를 덮어씁니다.
- `sortMode`: 엔진 기본 정렬 대신 이번 검색에만 정렬 기준을 덮어씁니다.
- `limit` / `offset`: 결과 개수 제한과 페이지네이션을 설정합니다.
- `minInputLength`: 너무 짧은 입력(예: 1글자)에서 검색을 제한할 수 있습니다.
- `normalizeToNFC`: 유니코드 정규화(NFC) 기준으로 입력/데이터를 맞춰 검색 안정성을 높입니다.
- `emptyQueryBehavior`: 빈 입력일 때 `[]` 또는 전체 결과 반환을 선택합니다.

추천 조합 프리셋:

1. 빠른 자동완성: `mode: .autocomplete`, `sortMode: .matchPosition`, `limit: 10`
2. 정확도 우선 검색: `mode: .combined`, `sortMode: .editDistance`, `normalizeToNFC: true`
3. 목록 탐색형 검색: `emptyQueryBehavior: .returnAll`, `limit`/`offset`으로 페이지네이션

```swift
// 기본 예시
let options = HangulSearchOptions(
    mode: .combined,
    sortMode: .editDistance,
    limit: 10,
    offset: 0,
    minInputLength: 1,
    normalizeToNFC: true,
    emptyQueryBehavior: .returnEmpty
)

let optionResults = engine.searchItems(input: "철수", options: options)

// 1) 빠른 자동완성 프리셋
let quickAutocomplete = HangulSearchOptions(
    mode: .autocomplete,
    sortMode: .matchPosition,
    limit: 10,
    minInputLength: 1
)
let quickResults = engine.searchItems(input: "철", options: quickAutocomplete)

// 2) 정확도 우선 프리셋
let accuracyFirst = HangulSearchOptions(
    mode: .combined,
    sortMode: .editDistance,
    normalizeToNFC: true,
    minInputLength: 1
)
let accuracyResults = engine.searchItems(input: "이쳘수", options: accuracyFirst)

// 3) 목록 탐색형 프리셋 (빈 검색 허용 + 페이지네이션)
let browseMode = HangulSearchOptions(
    mode: .containsMatch,
    sortMode: .hangulOrder,
    limit: 20,
    offset: 0,
    emptyQueryBehavior: .returnAll
)
let browseResults = engine.searchItems(input: "", options: browseMode)
```

## 상세 결과 API (`searchHits`)

```swift
let hitOptions = HangulSearchOptions(sortMode: .matchPosition)
let hits = engine.searchHits(input: "철수", options: hitOptions)

for hit in hits {
    print(hit.item.name)
    print(hit.matchKinds)      // [.fullMatch] 등
    print(hit.matchPosition)   // Int?
    print(hit.editDistance)    // Int?
}
```

## 데이터/설정 변경

```swift
engine.changeItems(items: [
    Person(name: "홍길동", age: 20),
    Person(name: "김영희", age: 22)
])

engine.addItems(items: [
    Person(name: "장철수", age: 31)
])

engine.changeSearchMode(mode: .combined)
engine.changeSortMode(mode: .hangulOrder)
engine.changeKeySelector { $0.name }
```

## 라이선스

MIT License. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
