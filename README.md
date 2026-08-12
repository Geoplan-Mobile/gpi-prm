# gpi-prm (Swift Package)

본 저장소는 `gpi-prm` PRM(실내 측위 진출입 / 지오펜싱) 코어의 외부 연동 장착을 위한 **배포 전용 릴리즈 저장소(Release Repository)**이다.
사전 컴파일(Pre-compiled)된 정적 `XCFramework` 형태의 바이너리를 SPM(Swift Package Manager) 포맷으로 독립 제공한다.
iOS 실기기(arm64) 및 시뮬레이터(arm64, x86_64) 빌드를 모두 지원하며, `gpi-prm.xcframework` 내부의 `VERSION_X.X.X` 파일로 배포 버전을 확인할 수 있다.

> **💡 엔진 코어 역량 요약**
> 태그(스마트폰/단말)의 실시간 (x, y, z) 좌표 스트림을 입력받아, 사용자가 정의한 영역(Area)에 대한
> **진입/이탈(IN/OUT) 이벤트를 판정**하여 콜백으로 통지. 영역 in/out 기하 연산은 내부적으로 GEOSwift(GEOS) 엔진을 사용한다.

---

## 프로젝트 연동 및 사용 방법 (Usage)

코어 진입점 `Prm` 은 `Prm.create(name:callback:)` 로 인스턴스를 만들고(호출마다 독립 인스턴스), 진출입 결과는 생성 시 넘긴 `PrmCallback` 으로 통지된다.

### 1. Xcode 외부 패키지(SPM) 연동
1. 타겟 앱을 연 상태로 Xcode 상단 메뉴 **[File] ➡ [Add Package Dependencies...]** 를 클릭한다.
2. 검색창(Search or Enter Package URL)에 아래 SPM 배포 전용 저장소 주소를 입력한다.
   `https://github.com/Geoplan-Mobile/gpi-prm`
   *(주의: 저장소가 Private인 경우, 사용할 깃허브 계정이 해당 저장소의 Collaborator로 사전 등록되어 있어야 인증이 통과된다.)*
3. **Dependency Rule** 을 설정한 뒤 **[Add Package]** 로 연동을 완료한다.

> 의존성 `GEOSwift`(및 transitive `geos`)는 본 패키지의 wrapper 가 함께 짊어지므로, **호스트 앱이 GEOSwift 를 별도로 추가할 필요가 없다.**

### 2. Prm 인스턴스 생성 (콜백 필수)
`PrmCallback` 구현체를 만들어 `Prm.create(name:callback:)` 에 넘긴다. 콜백은 생성 시 필수이며 인스턴스에 고정된다(바꾸려면 새 인스턴스). `name` 은 로그·콜백 식별용이라 인스턴스마다 다른 이름을 준다.

```swift
import gpi_prm

final class MyPrmService: PrmCallback {
    lazy var prm: Prm = Prm.create(name: "site1", callback: self)

    // MARK: - PrmCallback (백그라운드 큐에서 호출됨 → UI 갱신은 main 으로 디스패치)
    // 첫 파라미터 prmName 으로 어느 인스턴스(공간)의 이벤트인지 구분한다.
    func onStart(prmName: String) {}
    func onStop(prmName: String) {}
    func onError(prmName: String, msg: String) {}
    func onReceivedInout(prmName: String, inoutStr: String, areaName: String) {
        // inoutStr: "IN" | "OUT"
        print("[\(prmName)] \(inoutStr) area=\(areaName)")
    }
}
```

### 3. 영역 데이터로 시작 및 좌표 주입
영역(`AreaInfo`)을 **Builder** 로 구성해 `start(areaInfoList:)` 로 시작한 뒤,
측위 좌표가 들어올 때마다 `pushEvent(x:y:z:)` 로 주입한다. `name`·`points` 는 필수이고 나머지는 생략 시 기본값이 적용된다(생성 후 불변).

```swift
let area = AreaInfo.Builder(name: "영역 A", points: [   // name·points 필수, 폴리곤 자동 폐합
        CGPoint(x: 0,  y: 0),
        CGPoint(x: 0,  y: 10),
        CGPoint(x: 10, y: 10),
        CGPoint(x: 10, y: 0),
    ])
    // --- 아래는 모두 선택(생략 시 기본값) ---
    .inCount(1)             // 진입 확정에 필요한 감지 횟수 (기본 1)
    .inCountInterval(0)     // 연속 인정 최대 간격(초) (기본 0; inCount≥2면 1 이상 필수)
    .inDist(3.0)            // 연속 감지 간 이동 허용 거리(m) (기본 3.0)
    .outPeriod(0)           // 신호 두절 시 OUT 유예(초) (기본 0=비활성)
    .priority(1)            // 영역 겹칠 때 콜백 순서, 작을수록 먼저 (기본 1)
    .callInout(true)        // 이 영역의 진출입 콜백 호출 여부 (기본 true)
    .build()

prm.start(areaInfoList: [area])   // 유효하지 않은 영역은 onError 로 통지 후 건너뜀

// 측위 좌표 주입 → 영역 안이면 onReceivedInout(inoutStr: "IN", ...)
prm.pushEvent(x: 5, y: 5, z: 0)

prm.stop()
```

> 상태 가드: 실행 중 `start`·정지 중 `stop`·정지 중 `pushEvent` 는 무시하고 `onError` 로 통지한다.

---

## API 레퍼런스 (API Reference)

라이브러리에서 대외 개방(Public)된 핵심 타입의 기술 명세서이다.

### 클래스: `Prm`
PRM 엔진 컨트롤러. 진출입 판정의 모든 제어 진입점이다.

* **`static func create(name: String, callback: PrmCallback) -> Prm`** — 인스턴스 생성. 호출마다 **독립 인스턴스**가 만들어지며, 콜백은 **필수**(인스턴스에 고정)다. `name` 은 로그·콜백 식별용.
* **`func isRunning() -> Bool`** — 엔진 구동 여부.
* **`func start(areaInfoList: [AreaInfo])`** — 영역 데이터로 시작. 유효하지 않은 영역은 `onError` 로 통지 후 건너뛴다.
* **`func pushEvent(x: Double, y: Double, z: Double)`** — 태그 좌표 주입 (이벤트 발생 시마다 호출).
* **`func stop()`** — 엔진 정지.

> 상태에 맞지 않는 호출(실행 중 `start`·정지 중 `stop`·정지 중 `pushEvent`)은 무시하고 `onError` 로 통지한다.

### 프로토콜: `PrmCallback` (`AnyObject`)
엔진 → 호스트 이벤트 통지 인터페이스. 콜백은 백그라운드 큐에서 호출되므로 UI 갱신은 메인 스레드로 디스패치해야 한다. 모든 콜백의 첫 파라미터 `prmName` 은 이벤트를 보낸 인스턴스 이름이라, 하나의 콜백을 여러 인스턴스에 공유해도 구분할 수 있다.

* **`func onStart(prmName: String)`** — 시작 완료.
* **`func onStop(prmName: String)`** — 정지 완료.
* **`func onError(prmName: String, msg: String)`** — 오류 통지.
* **`func onReceivedInout(prmName: String, inoutStr: String, areaName: String)`**
  * 영역 진출입 발생. `inoutStr` 은 `"IN"` 또는 `"OUT"`, `areaName` 은 설정한 `AreaInfo.name`.

### 입력 모델: `AreaInfo` (영역)
**Builder 전용**(`AreaInfo.Builder(name:points:)…build()`), 생성 후 불변. `name`·`points` 는 필수, 나머지는 기본값.

| 프로퍼티 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `name` | `String` | 필수 | 영역 이름 (콜백 `areaName`) |
| `points` | `[CGPoint]` | 필수 | 폴리곤 꼭짓점 (자동 폐합, 3점 이상) |
| `inCount` | `Int` | 1 | 진입 확정에 필요한 감지 횟수 (1=즉시) |
| `inCountInterval` | `Int` | 0 | 연속 인정 최대 간격(초, inCount≥2면 1 이상) |
| `inDist` | `Double` | 3.0 | 연속 감지 간 이동 허용 거리(m) |
| `outPeriod` | `Int` | 0 | 신호 두절 시 OUT 유예(초, 0=비활성) |
| `priority` | `Int` | 1 | 겹칠 때 콜백 순서(작을수록 먼저) |
| `callInout` | `Bool` | true | 진출입 콜백 호출 여부 |

> **진입 누적:** 영역 안 좌표가 `inCountInterval`초 이내 + `inDist`m 이내로 이어질 때만 카운트가 오르고, `inCount`에 도달하면 IN. **영역 밖 좌표는 그 영역 누적을 1 감소**시킨다(0이면 리셋). 안·밖이 번갈아 오면 진입이 쉽게 성립하지 않는다. (좌표 시퀀스별 상세 케이스: [INOUT_case.md](INOUT_case.md))

### 버전: `SDKConfig`
* **`static var version: String`** — 현재 SDK 버전. framework Info.plist 의 `CFBundleShortVersionString`(빌드 시 Xcode `MARKETING_VERSION`)을 읽어 반환한다. (예: `"2.0.0"`)
