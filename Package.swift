// swift-tools-version: 5.9
//
// gpi-prm 배포(Release) 매니페스트 — wrapper 패턴 (binaryTarget + deps carrier).
//
// 소비 앱은 이 저장소를 SPM 으로 의존한다:
//   https://github.com/Geoplan-Mobile/gpi-prm  (from: "1.0.0")
//   import gpi_prm
//
// carrier(gpi-prm-deps) 가 GEOSwift 를 짊어져, 소비측이 GEOSwift 를 직접 선언하지
// 않아도 자동 전파된다. (binaryTarget 은 SPM 제약상 dependencies 를 못 받음)
//
// 새 버전 배포: gpi-prm 소스 repo 에서 build_xcframework.sh 로 xcframework 갱신 →
// 이 저장소의 gpi-prm.xcframework 교체(폴더 완전 삭제 후 주입) → commit + tag x.y.z + push.
//
import PackageDescription

let package = Package(
    name: "gpi-prm",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // binaryTarget 과 deps carrier 를 한 library 로 묶음 — 소비측이 한 번 의존하면
        // 바이너리 + GEOSwift 가 함께 build graph 에 들어온다.
        .library(name: "gpi-prm", targets: ["gpi-prm", "gpi-prm-deps"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GEOSwift/GEOSwift.git", from: "11.2.0"),
    ],
    targets: [
        // 실제 라이브러리 — 사용자가 import 하는 대상.
        .binaryTarget(
            name: "gpi-prm",
            path: "gpi-prm.xcframework"
        ),
        // deps carrier — binaryTarget 이 dependencies 를 직접 못 받는 SPM 제약 우회.
        .target(
            name: "gpi-prm-deps",
            dependencies: [
                .product(name: "GEOSwift", package: "GEOSwift"),
            ],
            path: "Sources/gpi-prm-deps"
        ),
    ]
)
