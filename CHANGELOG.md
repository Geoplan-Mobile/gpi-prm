# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

## [2.0.0] - 2026-08-11 (beta)

> ⚠️ 아직 **베타** 배포입니다. (정식 릴리스 전)

### 변경됨 (Breaking) — 사용 측 코드 수정 필요
- **인스턴스 생성 방식 변경** — 싱글턴 `PrmFactory.getInstance()` → **`Prm.create(name:callback:)`**. 호출마다 **독립 인스턴스**가 만들어져 공간별로 따로 start/stop 할 수 있다. 콜백은 **생성 시 필수**(인스턴스에 고정)이고, 별도 `setCallback` 은 제거됐다. `name` 은 로그·콜백 식별용 이름이다.
- **콜백 시그니처 변경** — `PrmCallback` 의 모든 콜백 첫 파라미터에 **`prmName`** 이 추가된다(어느 인스턴스의 이벤트인지 구분). 진출입 콜백은 **`onReceivedInout(prmName:inoutStr:areaName:)`** 로 바뀌며, 기존 `tagId`·`workspaceId` 는 사라지고 `workspaceName` 은 **`areaName`** 으로 이름이 바뀐다.
- **`AreaInfo` 생성 방식 변경** — 직접 생성 후 프로퍼티 대입 → **Builder 전용**(`AreaInfo.Builder(name:points:)…build()`). `name`·`points` 는 필수 인자이고 나머지는 생략 시 기본값(`inCount=1`·`inCountInterval=0`·`outPeriod=0`·`priority=1`·`inDist=3.0`·`callInout=true`)이 적용된다. 생성 후에는 값이 바뀌지 않는다(불변).
- **`start` / `pushEvent` 시그니처 변경** — `start(areaInfoList:wallInfoList:)` → **`start(areaInfoList:)`**, `pushEvent(spaceId:tagId:x:y:z:)` → **`pushEvent(x:y:z:)`**. 외부에서 넘기던 `spaceId`·`tagId` 가 사라졌다.
- **서버 연동 제거** — 서버에서 영역을 받아오던 `start(baseUrl:…)` 계열이 제거됐다. 영역은 이제 **직접 주입만** 지원한다.
- **벽(Wall) 기능 제거** — 공개 타입 `WallInfo` 와 벽 통과 판정이 사라졌다. 이전에 벽으로 막던 이동 좌표도 이제 그대로 진출입 판정에 반영된다.

### 추가됨
- **멀티 인스턴스** — 서로 다른 공간을 독립 인스턴스로 동시에 운용할 수 있다(영역·상태·타이머가 인스턴스마다 독립). 하나의 콜백을 여러 인스턴스에 공유해도 `prmName` 으로 구분된다.
- **영역 검증(비중단)** — `start` 시 유효하지 않은 영역은 `onError` 로 사유를 알리고 **건너뛴다**(예외 없이 유효한 영역만 진행). 이름이 중복되면 첫 번째만 사용한다.
- **상태 가드** — 실행 중 `start`, 정지 중 `stop`, 정지 중 `pushEvent` 호출은 무시하고 `onError` 로 통지한다.
- **로깅** — 진출입·생명주기·콜백 지점의 로그를 `os.Logger` + 파일 로그(`Documents/gpi-prm/yyyyMMdd.txt`)로 남긴다. 의존성 `gpi-logger` 는 패키지가 함께 포함하므로 **소비측이 별도로 선언할 필요가 없다**.

### 수정됨 (동작 개선)
- **겹침 영역 판정 정확도** — 겹친 영역들이 각자 자기 `inCount` 기준으로 **독립적으로** IN 된다(이전엔 우선순위 배치에 따라 겹친 영역이 예상보다 빨리 IN되던 문제).
- **진입 누적 강화** — 아직 IN 아닌 누적 중 영역은 그 영역 **밖 좌표가 오면 진입 누적을 1 감소**시킨다(0이면 리셋). 안·밖이 번갈아 와도(포함·미포함·포함…) 시간·거리 조건만으로 진입이 성립하던 것을 보완.
- **이탈 타이머 영역별 처리** — 한 영역의 `outPeriod` 만료로 OUT 될 때 **그 영역만** OUT 되고, 겹쳐 IN 중인 다른 영역은 각자의 `outPeriod` 로 판단된다(이전엔 함께 OUT되던 문제).
- **콜백 재진입 안정성** — 콜백 안에서 다시 `pushEvent` 를 주입해도 안전하게 처리된다.

### 요구사항
- deployment target iOS 15.0+. (의존성은 패키지가 함께 포함하므로 소비측 별도 선언 불필요)

## [1.1.0] - 2026-07-13

### 변경됨 (Breaking)
- **공개 API 이름 변경** — 라이브러리 명칭을 MIOC → PRM 으로 통일. **사용 측 코드 수정 필요.**
  - `MIoc` → `Prm`, `MIocFactory` → `PrmFactory`, `MIocCallback` → `PrmCallback`
  - 진입점: `MIocFactory.getInstance()` → `PrmFactory.getInstance()`
  - `AreaInfo` · `WallInfo` · `SDKConfig` 는 **이름·속성·시그니처 모두 동일** (변경 없음)

### 수정됨
- **진출입 판정 동시성 크래시 수정** — 좌표 진출입 판정(`processInArea`)과 이탈 정리 타이머(`outPeriodCheck`)가 서로 다른 스레드에서 같은 내부 컬렉션(진입 태그 목록/마지막 감지 시각)을 동시에 수정해 발생하던 data race(`EXC_BAD_ACCESS`)를 수정. 재진입 락으로 두 경로를 상호배제.

### 참고
- 판정 로직·동작, 요구사항(iOS 15.0+), 의존성(GEOSwift 11.2.0)은 1.0.0 과 동일.
- 버전 식별 파일: `gpi-prm.xcframework/VERSION_1.1.0`.

## [1.0.0] - 2026-06-24

### 추가됨
- **최초 배포**: PRM(실내 측위 진출입 / 지오펜싱) 엔진.
  - 공개 API: `MIoc`, `MIocFactory`, `MIocCallback`, `AreaInfo`, `WallInfo`, `SDKConfig`.
  - 태그 좌표 스트림(`pushEvent`)을 받아 영역/벽 진출입(IN/OUT)을 판정해 `MIocCallback.onReceivedInout` 으로 통지.
  - 시작: `start(areaInfoList:wallInfoList:)` 로 영역/벽 데이터를 직접 주입.
- **iOS Simulator 지원**: `xcframework` 에 `ios-arm64`(device) + `ios-arm64_x86_64-simulator` 슬라이스 포함.
- **버전 식별 파일**: `gpi-prm.xcframework/VERSION_1.0.0` 동봉 — 연동 없이도 배포 버전 확인 가능.

### 의존성
- `GEOSwift` 11.2.0 (및 transitive `geos` 9.0.0) — 영역 in/out 기하 연산. wrapper 패키지의 carrier 가 짊어져 호스트 앱에 자동 전파되므로, 사용 측은 GEOSwift 를 별도 선언하지 않는다.

### 요구사항
- deployment target **iOS 15.0+**.
