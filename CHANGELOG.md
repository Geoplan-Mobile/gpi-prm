# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

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
