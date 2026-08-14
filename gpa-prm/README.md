# gpa-prm (Android Library)

본 폴더는 `gpa-prm` PRM(실내 측위 진출입)의 **Android 배포 문서**다.  
라이브러리는 사내 Nexus 에 `.aar` 아티팩트로 배포되며, iOS 판(`gpi-prm`)과 **동일한 판정 엔진·API 흐름**을 가진다.  
판정 원리(좌표 시퀀스별 IN/OUT 동작)는 플랫폼 공통이므로 [INOUT_case.md](../INOUT_case.md) 를 함께 참고한다.

> **배포 아티팩트**
> - groupId : `kr.geoplan.android.lib`
> - artifactId : `gpa-prm`

---

## 프로젝트 연동 및 사용 방법 (Usage)

`Prm` 은 `Prm.create(name, callback)` 로 인스턴스를 만들고,  
`pushEvent(x, y, z)` 로 좌표를 주입하며,  
판단된 진출입 결과는 생성 시 넘긴 `PrmCallback` 으로 통지된다.

### 1. Gradle 의존성
Nexus 저장소를 추가하고 아티팩트를 의존성으로 선언한다. **접속 계정·비밀번호는 Geoplan 에 문의**한다.

```gradle
repositories {
    maven {
        url "http://geoplan.iptime.org:30005/nexus/content/repositories/geoplan_release"
        credentials {
            username "<발급 계정>"       // Geoplan 문의
            password "<발급 비밀번호>"    // Geoplan 문의
        }
        allowInsecureProtocol true       // http 연결 허용
    }
}
dependencies {
    implementation 'kr.geoplan.android.lib:gpa-prm:2.0.0'
}
```

### 2. Prm 인스턴스 생성 (콜백 필수)
`PrmCallback` 구현체를 만들어 `Prm.create(name, callback)` 에 넘긴다.  
콜백은 생성 시 필수이며(`null` 이면 `IllegalArgumentException`) 인스턴스에 고정된다. `name` 은 로그·콜백 식별용이라 인스턴스마다 다른 이름을 준다.

```java
import kr.co.geoplan.android.lib.prm.Prm;
import kr.co.geoplan.android.lib.prm.PrmCallback;

Prm prm = Prm.create("site1", new PrmCallback() {
    // 콜백은 백그라운드 스레드에서 호출됨 → UI 갱신은 메인으로 디스패치.
    // 첫 파라미터 prmName 으로 어느 인스턴스의 이벤트인지 구분한다.
    @Override public void onStart(String prmName) {}
    @Override public void onStop(String prmName) {}
    @Override public void onError(String prmName, String msg) {}
    @Override public void onReceivedInout(String prmName, String inout, String areaName) {
        // inout : "IN" | "OUT"
        Log.d("PRM", "[" + prmName + "] " + inout + " area=" + areaName);
    }
});
```

### 3. 영역 데이터로 시작 및 좌표 주입
`AreaInfo` 를 **Builder** 로 구성해 `start(List<AreaInfo>)` 로 시작, 측위 좌표를 `pushEvent(x, y, z)` 로 주입한다. 좌표는 `PointF`(미터 평면).

```java
import android.graphics.PointF;
import java.util.Arrays;
import kr.co.geoplan.android.lib.prm.AreaInfo;

AreaInfo area = AreaInfo.builder("영역 A", Arrays.asList(   // name·points 필수, 폴리곤 자동 폐합
        new PointF(0,  0),
        new PointF(0,  10),
        new PointF(10, 10),
        new PointF(10, 0)
    ))
    // --- 아래는 모두 선택(생략 시 기본값) ---
    .inCount(1)             // 진입 확정에 필요한 감지 횟수 (기본 1)
    .inCountInterval(0)     // 연속 인정 최대 간격(초) (기본 0; inCount≥2면 1 이상 필수)
    .inDist(3.0)            // 연속 감지 간 이동 허용 거리(m) (기본 3.0)
    .outPeriod(0)           // 신호 두절 시 OUT 유예(초) (기본 0=비활성)
    .priority(1)            // 영역 겹칠 때 콜백 순서, 작을수록 먼저 (기본 1)
    .callInout(true)        // 이 영역의 진출입 콜백 호출 여부 (기본 true)
    .build();

prm.start(Arrays.asList(area));   // 유효하지 않은 영역은 onError 로 통지 후 건너뜀

// 측위 좌표 주입 → 영역 안이면 onReceivedInout(…, "IN", …)
prm.pushEvent(5.0, 5.0, 0.0);

prm.stop();
```

> 상태 가드: 실행 중의 `start`, 정지 중의 `stop`·`pushEvent` 는 무시되며 `onError` 로 통지한다.

---

## API 레퍼런스 (API Reference)

라이브러리에서 대외 개방(Public)된 핵심 타입의 명세다.

### 클래스: `Prm` (abstract)
PRM 엔진 컨트롤러. 진출입 판정의 모든 제어 진입점이다.

* **`static Prm create(String name, PrmCallback callback)`**  
  인스턴스 생성. 호출마다 **독립 인스턴스**가 만들어지며, 콜백은 **필수**(`null` 이면 `IllegalArgumentException`, 인스턴스에 고정)다.  
  `name` 은 로그·식별용이며 `PrmCallback` 의 `prmName` 으로 전달된다.

* **`boolean isRunning()`**  
  엔진 구동 여부. `start` 이후 `stop` 전까지 `true`.
* **`void start(List<AreaInfo> areas)`**  
  입력된 영역 데이터로 엔진 구동을 시작하고, 구동이 시작되면 `onStart` 호출.  
  이미 `isRunning()==true` 면 무시하고 `onError` 호출.  
  유효하지 않은 영역이 입력된 경우 `onError` 로 해당 영역 오류 통지 후 유효한 영역만으로 시작.
* **`void pushEvent(Double x, Double y, Double z)`**  
  측위 좌표 주입 (이벤트 발생 시마다 호출). `isRunning()==false` 면 무시하고 `onError` 호출.
* **`void stop()`**  
  엔진 정지 → 완료 시 `onStop` 호출. `isRunning()==false` 면 무시하고 `onError` 호출.

### 인터페이스: `PrmCallback`
엔진 → 호스트 이벤트 통지 인터페이스. 콜백은 백그라운드 스레드에서 호출되므로 UI 갱신은 메인 스레드로 디스패치 필수.  
모든 콜백의 첫 파라미터 `prmName` 은 이벤트를 보낸 인스턴스 이름.

* **`void onStart(String prmName)`**  
  시작 완료.
* **`void onStop(String prmName)`**  
  정지 완료.
* **`void onError(String prmName, String msg)`**  
  오류 통지.
* **`void onReceivedInout(String prmName, String inout, String areaName)`**  
  영역 진출입 발생. `inout` 은 `"IN"` 또는 `"OUT"`, `areaName` 은 설정한 `AreaInfo.name`.

### 입력 모델: `AreaInfo` (영역)
**Builder 전용**(`AreaInfo.builder(name, points)…build()`). `name`·`points` 는 필수, 나머지는 기본값. 좌표는 `List<PointF>`.

| 프로퍼티 | 타입 | 기본 | 설명 |
|---|---|---|---|
| `name` | `String` | 필수 | 영역 이름 (콜백 `areaName`) |
| `points` | `List<PointF>` | 필수 | 폴리곤 꼭짓점 (자동 폐합, 3점 이상) |
| `inCount` | `int` | 1 | 진입 확정에 필요한 감지 횟수 (1=즉시) |
| `inCountInterval` | `int` | 0 | 연속 인정 최대 간격(초, inCount≥2면 1 이상) |
| `inDist` | `double` | 3.0 | 연속 감지 간 이동 허용 거리(m) |
| `outPeriod` | `int` | 0 | 신호 두절 시 OUT 유예(초, 0=비활성) |
| `priority` | `int` | 1 | 겹칠 때 콜백 순서(작을수록 먼저) |
| `callInout` | `boolean` | true | 진출입 콜백 호출 여부 |

> **진출입 판정**  
진출입 판단 규칙에 사용되는 AreaInfo 프로퍼티의 상세 내용은 [INOUT_case.md](../INOUT_case.md) 참고

### 버전: `SDKConfig`
* **`static String getVersion()`**  
  현재 SDK 버전. (예: `"2.0.0"`)

---

## 요구사항
- minSdk 27 / compileSdk 32.
