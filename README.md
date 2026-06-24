# gpi-prm (Swift Package)

본 저장소는 `gpi-prm` PRM(실내 측위 진출입 / 지오펜싱) 코어의 외부 연동 장착을 위한 **배포 전용 릴리즈 저장소(Release Repository)**이다.
사전 컴파일(Pre-compiled)된 정적 `XCFramework` 형태의 바이너리를 SPM(Swift Package Manager) 포맷으로 독립 제공한다.
iOS 실기기(arm64) 및 시뮬레이터(arm64, x86_64) 빌드를 모두 지원하며, `gpi-prm.xcframework` 내부의 `VERSION_X.X.X` 파일로 배포 버전을 확인할 수 있다.

> **💡 엔진 코어 역량 요약**
> 태그(스마트폰/단말)의 실시간 (x, y, z) 좌표 스트림을 입력받아, 사용자가 정의한 영역(Area)·벽(Wall)에 대한
> **진입/이탈(IN/OUT) 이벤트를 판정**하여 콜백으로 통지. 영역 in/out 기하 연산은 내부적으로 GEOSwift(GEOS) 엔진을 사용한다.

---

## 프로젝트 연동 및 사용 방법 (Usage)

코어 진입점인 `MIoc` 프로토콜은 `MIocFactory.getInstance()` 싱글턴으로 획득하며, 진출입 결과는 `MIocCallback` 으로 통지된다.

### 1. Xcode 외부 패키지(SPM) 연동
1. 타겟 앱을 연 상태로 Xcode 상단 메뉴 **[File] ➡ [Add Package Dependencies...]** 를 클릭한다.
2. 검색창(Search or Enter Package URL)에 아래 SPM 배포 전용 저장소 주소를 입력한다.
   `https://github.com/Geoplan-Mobile/gpi-prm`
   *(주의: 저장소가 Private인 경우, 사용할 깃허브 계정이 해당 저장소의 Collaborator로 사전 등록되어 있어야 인증이 통과된다.)*
3. **Dependency Rule** 을 설정한 뒤 **[Add Package]** 로 연동을 완료한다.

> 의존성 `GEOSwift`(및 transitive `geos`)는 본 패키지의 wrapper 가 함께 짊어지므로, **호스트 앱이 GEOSwift 를 별도로 추가할 필요가 없다.**

### 2. MIoc 인스턴스 획득 및 콜백 등록
`MIocFactory.getInstance()` 로 싱글턴을 얻고, `MIocCallback` 구현체를 등록한다.

```swift
import gpi_prm

final class MyPrmService: MIocCallback {
    private let mioc: MIoc = MIocFactory.getInstance()

    init() {
        mioc.setCallback(callback: self)   // 콜백은 start 이전에 등록
    }

    // MARK: - MIocCallback (백그라운드 큐에서 호출됨 → UI 갱신은 main 으로 디스패치)
    func onStart() {}
    func onStop() {}
    func onError(msg: String) {}
    func onReceivedInout(inoutStr: String, tagId: String, workspaceId: Int64, workspaceName: String) {
        // inoutStr: "IN" | "OUT"
        print("\(inoutStr) tag=\(tagId) area=\(workspaceName)(\(workspaceId))")
    }
}
```

### 3. 영역 데이터로 시작 및 좌표 주입
영역(`AreaInfo`)·벽(`WallInfo`)을 직접 구성해 `start(areaInfoList:wallInfoList:)` 로 시작한 뒤,
측위 좌표가 들어올 때마다 `pushEvent(...)` 로 주입한다. 영역 매칭을 위해 `spaceId` 는 `1` 을 사용한다.

```swift
let area = AreaInfo()
area.name = "영역 A"
area.points = [                       // 폴리곤 꼭짓점 (자동 폐합)
    CGPoint(x: 0,  y: 0),
    CGPoint(x: 0,  y: 10),
    CGPoint(x: 10, y: 10),
    CGPoint(x: 10, y: 0),
]
area.inCount = 1                      // 진입 확정에 필요한 감지 횟수
area.inDist  = 3.0                    // 진입 판단 거리(m)

service.mioc.start(areaInfoList: [area], wallInfoList: [])

// 측위 좌표 주입 → 영역 안이면 onReceivedInout("IN", ...)
service.mioc.pushEvent(spaceId: 1, tagId: "TAG-001", x: 5, y: 5, z: 0)

service.mioc.stop()
```

---

## API 레퍼런스 (API Reference)

라이브러리에서 대외 개방(Public)된 핵심 타입의 기술 명세서이다.

### 팩토리: `MIocFactory`
* **`static func getInstance() -> MIoc`**
  * PRM 엔진의 싱글턴 인스턴스(`MIoc`)를 반환한다.

### 프로토콜: `MIoc`
PRM 엔진 컨트롤러. 진출입 판정의 모든 제어 진입점이다.

* **`func setCallback(callback: MIocCallback)`** — 진출입/상태 이벤트를 받을 콜백 등록. (start 이전 호출)
* **`func isRunning() -> Bool`** — 엔진 구동 여부.
* **`func start(areaInfoList: [AreaInfo], wallInfoList: [WallInfo])`** — 영역/벽 데이터로 직접 시작.
* **`func pushEvent(spaceId: Int64, tagId: String, x: Double, y: Double, z: Double)`** — 태그 좌표 주입 (이벤트 발생 시마다 호출).
* **`func stop()`** — 엔진 정지.

### 프로토콜: `MIocCallback` (`AnyObject`)
엔진 → 호스트 이벤트 통지 인터페이스. 콜백은 백그라운드 큐에서 호출되므로 UI 갱신은 메인 스레드로 디스패치해야 한다.

* **`func onStart()`** — 시작 완료.
* **`func onStop()`** — 정지 완료.
* **`func onError(msg: String)`** — 오류 통지.
* **`func onReceivedInout(inoutStr: String, tagId: String, workspaceId: Int64, workspaceName: String)`**
  * 영역 진출입 발생. `inoutStr` 은 `"IN"` 또는 `"OUT"`.

### 입력 모델: `AreaInfo` (영역)
| 프로퍼티 | 타입 | 설명 |
|---|---|---|
| `name` | `String?` | 영역 이름 (이벤트의 workspaceName) |
| `points` | `[CGPoint]?` | 폴리곤 꼭짓점 (자동 폐합) |
| `inCount` | `Int` | 진입 확정에 필요한 감지 횟수 |
| `inCountInterval` | `Int` | 감지 카운트 간격 |
| `priority` | `Int` | 영역 우선순위 (기본 1) |
| `outPeriod` | `Int` | 이탈 판정 유예(period) |
| `inDist` | `Double` | 진입 판단 거리(m, 기본 3.0) |
| `callInout` | `Bool` | 진출입 콜백 호출 여부 (기본 true) |

* **`init()`** — 기본 생성자.

### 입력 모델: `WallInfo` (벽)
| 프로퍼티 | 타입 | 설명 |
|---|---|---|
| `name` | `String?` | 벽 이름 |
| `points` | `[CGPoint]?` | 벽 라인 점 |
| `inCount` | `Int` | 벽 통과 판단 횟수 |
| `inCountInterval` | `Int` | 카운트 간격 |
| `inDist` | `Double` | 진입 판단 거리(m, 기본 2.0) |

* **`init()`** — 기본 생성자.

### 버전: `SDKConfig`
* **`static let version: String`** — 현재 SDK 시멘틱 버전. (예: `"1.0.0"`)
