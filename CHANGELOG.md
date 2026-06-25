# Changelog

모든 주요 변경 사항은 이 파일에 기록됩니다.

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
