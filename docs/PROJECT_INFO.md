# 프로젝트 정보 문서

> 한곳에 (One Place) - 50~70대를 위한 초간단 정보 저장 앱

---

## 프로젝트 개요

**한곳에**는 다른 앱에서 공유받은 링크나 텍스트를 한 곳에 저장하고 관리할 수 있는 Flutter 앱입니다. 특히 50~70대 사용자를 위해 큰 글씨, 간단한 UI, 직관적인 조작을 목표로 합니다.

### 핵심 기능

| 기능 | 설명 |
|------|------|
| **공유 수신** | 다른 앱에서 링크/텍스트를 공유받아 자동 저장 |
| **자동 분류** | URL 기반 카테고리 자동 인식 (뉴스, 영상, 쇼핑 등) |
| **검색/필터** | 카테고리별 필터링 및 키워드 검색 |
| **직접 추가** | 앱 내에서 직접 텍스트/링크 입력 가능 |
| **클라우드 백업** | Firebase 연동으로 데이터 안전하게 백업 (유료) |
| **인앱 결제** | 프리미엄 기능 구매 시스템 |

### 타겟 사용자

- **주 타겟**: 50~70대 스마트폰 사용자
- **핵심 니즈**: 링크 저장/관리, 클라우드 백업
- **UI 철학**: 큰 글씨, 최소한의 버튼, 직관적 조작

---

## 기술 스택

| 영역 | 기술 | 용도 |
|------|------|------|
| **Frontend** | Flutter | 크로스플랫폼 앱 개발 |
| **상태 관리** | Riverpod | 반응형 상태 관리 |
| **로컬 저장소** | Hive | 오프라인 우선 데이터 저장 |
| **인증** | Firebase Auth | Google 로그인 |
| **데이터베이스** | Cloud Firestore | 클라우드 백업/동기화 |
| **인앱 결제** | in_app_purchase | 프리미엄 구매 |
| **URL 열기** | url_launcher | 외부 링크 실행 |
| **유틸리티** | intl, path_provider | 날짜 포맷, 경로 관리 |

### Flutter 패키지 의존성

```yaml
dependencies:
  flutter_riverpod: ^2.6.1      # 상태 관리
  hive: ^2.2.3                  # 로컬 저장소
  hive_flutter: ^1.1.0         # Hive Flutter 연동
  url_launcher: ^6.3.1          # URL 열기
  intl: ^0.20.2                 # 날짜 포맷
  path_provider: ^2.1.5         # 경로 관리
  firebase_core: ^3.8.1         # Firebase 초기화
  firebase_auth: ^5.3.4         # 인증
  cloud_firestore: ^5.6.0       # 데이터베이스
  google_sign_in: ^6.2.2        # Google 로그인
  in_app_purchase: ^3.2.0       # 인앱 결제
```

---

## 아키텍처

### 설계 원칙

- **유저 중심 구조**: `users/{uid}/items` 경로 기반 데이터 분리
- **오프라인 우선**: Hive에 먼저 저장 → 필요시 Firestore 동기화
- **read/write 최소화**: 비용 효율적인 Firestore 사용
- **단순한 쿼리**: 경로 자체로 접근 제한

### 아키텍처 한눈에 보기

```
┌─────────────────────────────────────────────────────────────────┐
│                         한곳에 앱                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Frontend: Flutter + Riverpod                                   │
│  Local DB: Hive (오프라인 우선)                                  │
│  Cloud DB: Cloud Firestore (백업/동기화)                         │
│  Auth: Firebase Authentication (Google)                         │
│  Payment: In-App Purchase (프리미엄)                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Flutter + Firebase 설계

### 1️⃣ Firebase 프로젝트 세팅 체크리스트

#### 1. Firebase 프로젝트 세팅

- Firebase Console → 새 프로젝트 생성
- Google Analytics ❌ (초기엔 꺼도 됨)

#### 2. 앱 등록

- **Android 앱 추가**
  - Package name: `com.oneplace.one_place`
  - SHA-1: `F1:6A:DD:6E:88:60:5D:61:96:12:B8:16:EC:1D:EB:F9:55:2A:AC:45`
  - `google-services.json` 다운로드 → `android/app/` 폴더에 복사
- **iOS 앱 추가** (나중에 가능)

#### 3. Flutter 패키지 (최소)

```yaml
firebase_core
firebase_auth
cloud_firestore
google_sign_in
```

#### 4. Firebase Auth 설정

Sign-in method:
- Google ✅
- Apple (iOS 출시 시)
- Email/Password (선택)

#### 5. Firestore 기본 보안 규칙 (초기)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

> ✔️ **유저는 자기 데이터만 접근 가능**

---

## 2️⃣ Firestore 데이터 구조

### 컬렉션 구조

```
firestore/
└── users/
    └── {uid}/
        │
        ├── [Document Fields]        # 유저 프로필
        │   ├── name: "사용자명"
        │   ├── email: "user@gmail.com"
        │   ├── createdAt: Timestamp
        │   └── lastLoginAt: Timestamp
        │
        ├── settings/                # 설정 (선택)
        │   └── preferences
        │
        └── items/                   # 저장된 항목들 (Subcollection)
            ├── {itemId1}
            │   ├── content: "https://youtube.com/..."
            │   ├── extractedUrl: "https://youtube.com/..."
            │   ├── isUrl: true
            │   ├── title: null
            │   ├── category: "video"
            │   ├── createdAt: Timestamp
            │   └── updatedAt: Timestamp
            │
            └── {itemId2}
                ├── content: "메모 텍스트..."
                ├── extractedUrl: null
                ├── isUrl: false
                ├── title: "제목"
                ├── category: "memo"
                ├── createdAt: Timestamp
                └── updatedAt: Timestamp
```

### 데이터 예시

```json
// 📌 users/{uid}
{
  "name": "사용자",
  "email": "user@gmail.com",
  "createdAt": "2025-01-01T00:00:00Z",
  "lastLoginAt": "2025-01-10T00:00:00Z"
}

// 📌 users/{uid}/items/{itemId}
{
  "content": "https://youtube.com/watch?v=abc123",
  "extractedUrl": "https://youtube.com/watch?v=abc123",
  "isUrl": true,
  "title": null,
  "category": "video",
  "createdAt": "2025-01-10T10:30:00Z",
  "updatedAt": "2025-01-10T10:30:00Z"
}
```

> ✔️ **모든 쿼리는 경로 자체로 제한** - `where userId == uid` 없이 `/users/{uid}/items`로 접근

---

## 3️⃣ 비용 폭탄 안 맞는 설계 패턴 🔥

### ✅ 권장 패턴

| 패턴 | 설명 |
|------|------|
| **경로 기반 접근** | `/users/{uid}/items` → security + 비용 둘 다 안전 |
| **Pagination 필수** | `limit(20)` + `startAfterDocument()` |
| **실시간 리스너 최소화** | 홈 화면 1개만 허용, 나머지는 `get()` |
| **오프라인 우선** | Hive 로컬 저장 → 필요시 Firestore 동기화 |

### ❌ 피해야 할 패턴

| 패턴 | 위험 |
|------|------|
| 전체 컬렉션 `get()` | 문서 수만큼 읽기 비용 발생 |
| 과도한 실시간 리스너 | 변경마다 읽기 발생 |
| 중첩 쿼리 | 복잡성 + 비용 증가 |

---

## 4️⃣ 동기화 전략

```
┌─────────────────────────────────────────────────────────────────┐
│                     동기화 워크플로우                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [로컬 저장]                    [클라우드 동기화]                 │
│                                                                 │
│  공유 수신 ──→ Hive 저장 ──→ (로그인+프리미엄) ──→ Firestore 업로드   │
│                                                                 │
│  [복원]                                                         │
│                                                                 │
│  새 기기 ──→ Google 로그인 ──→ Firestore 다운로드 ──→ Hive 저장 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 동기화 규칙

1. **오프라인 우선**: 항상 Hive에 먼저 저장
2. **백그라운드 동기화**: 로그인 + 프리미엄 상태면 자동 업로드
3. **충돌 해결**: `updatedAt` 기준 최신 데이터 우선
4. **삭제 동기화**: 로컬/클라우드 모두에서 삭제

---

## 5️⃣ 카테고리 분류 시스템

### 지원 카테고리

| 카테고리 | 이모지 | 예시 사이트 |
|----------|--------|-------------|
| 전체 | 📋 | 필터용 |
| 뉴스 | 📰 | NAVER 뉴스, BBC, CNN |
| 영상 | 🎬 | YouTube, Netflix, 티빙 |
| 쇼핑 | 🛒 | 쿠팡, 아마존, 11번가 |
| SNS | 📱 | 인스타그램, 페이스북, X |
| 여행 | ✈️ | Airbnb, Booking.com, 야놀자 |
| 음식 | 🍔 | 배민, 요기요, 망고플레이트 |
| 음악 | 🎵 | Spotify, Melon, YouTube Music |
| 메모 | 📝 | URL 없는 텍스트 |
| 기타 | 🔗 | 그 외 모든 것 |

### 자동 분류 규칙

```dart
// SavedItem._guessCategory() 참고
// URL 도메인 기반 자동 분류
// 예: youtube.com → video, instagram.com → sns
```

---

## 6️⃣ 파일 구조

```
lib/
├── main.dart                      # 앱 진입점, Firebase/Hive 초기화
├── app.dart                       # MaterialApp, 공유 수신 서비스 시작
│
├── core/
│   ├── services/
│   │   ├── auth_service.dart      # Firebase Auth (Google 로그인)
│   │   ├── payment_service.dart   # 인앱 결제 (In-App Purchase)
│   │   ├── premium_service.dart   # 프리미엄 상태 관리
│   │   ├── share_receiver_service.dart  # 공유 수신 (MethodChannel)
│   │   └── sync_service.dart      # Firestore 동기화
│   │
│   └── theme/
│       └── app_theme.dart         # 앱 테마 (색상, 폰트)
│
├── features/
│   ├── saved_items/               # 핵심 기능: 저장된 항목 관리
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── saved_item.dart    # 데이터 모델 + Hive 어댑터
│   │   │   └── repositories/
│   │   │       └── saved_item_repository.dart  # Hive CRUD
│   │   │
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── home_screen.dart  # 메인 화면
│   │   │   └── widgets/
│   │   │       └── saved_item_card.dart  # 항목 카드 위젯
│   │   │
│   │   └── providers/
│   │       └── saved_items_provider.dart  # Riverpod 상태 관리
│   │
│   └── settings/                  # 설정 기능
│       └── presentation/
│           └── screens/
│               └── settings_screen.dart  # 설정 화면 (로그인, 백업, 결제)
│
└── shared/                         # 공유 컴포넌트 (향후 추가)
```

---

## 7️⃣ 주요 화면

### HomeScreen (메인 화면)

```
┌────────────────────────────────────────┐
│  한곳에                    🔍  ⚙️      │  ← AppBar
├────────────────────────────────────────┤
│                                        │
│  [📋 전체 12] [🎬 영상 5] [🛒 쇼핑 3] │  ← 카테고리 필터
│  [📰 뉴스 2] [📝 메모 1] [🔗 기타 1]   │
│                                        │
├────────────────────────────────────────┤
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 📰 뉴스  오늘 15:30     🗑️      │  │  ← 카드
│  │ 링크 제목이 여기에 표시됩니다...    │  │
│  │ youtube.com          열기 →      │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 🎬 영상  1시간 전        🗑️      │  │
│  │ 또 하나의 저장된 항목입니다...      │  │
│  └──────────────────────────────────┘  │
│                                        │
│            ... 더 많은 항목 ...         │
│                                        │
├────────────────────────────────────────┤
│                                        │
│         [+ 직접 추가]                   │  ← FAB
│                                        │
└────────────────────────────────────────┘
```

### SettingsScreen (설정 화면)

```
┌────────────────────────────────────────┐
│  ← 설정                               │
├────────────────────────────────────────┤
│                                        │
│  ┌──────────────────────────────────┐  │
│  │           ⭐ 또는 🔒              │  │  ← 프리미엄 상태
│  │       프리미엄 사용 중 / 무료      │  │
│  │   클라우드 백업 기능 사용 가능      │  │
│  │        [₩3,900로 업그레이드]       │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │          👤 / 👤                 │  │  ← 로그인 상태
│  │       사용자명 / 로그인하지 않음    │  │
│  │       user@email.com             │  │
│  │    [Google로 로그인] / [로그아웃]   │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │         클라우드 백업              │  │  ← 동기화 (로그인 시)
│  │     [지금 백업하기]                │  │
│  │     [백업에서 복원하기]             │  │
│  └──────────────────────────────────┘  │
│                                        │
└────────────────────────────────────────┘
```

---

## 8️⃣ 중요 참고사항

### ⚠️ 출시 전 체크리스트

| 항목 | 위치 | 설명 |
|------|------|------|
| **테스트 모드 해제** | `settings_screen.dart:148` | `kTestMode = false`로 변경 |
| **인앱 결제 설정** | Google Play Console | 상품 ID 등록 (`oneplace_premium_unlock`) |
| **Firebase 설정** | Firebase Console | Auth, Firestore, google-services.json |
| **SHA-1 지문** | Android 서명 | 릴리스 서명 SHA-1 추가 |

### 테스트 모드 관련 코드

```dart
// lib/features/settings/presentation/screens/settings_screen.dart

// line 146-148
if (kTestMode || !paymentService.isAvailable) {
  // 테스트 모드: 결제 없이 바로 프리미엄 활성화
  // ⚠️ 출시 전에 kTestMode = false 로 변경하세요!
  const bool kTestMode = true; // TODO: 출시 시 false로 변경
}
```

### 결제 상품 ID

| 플랫폼 | 상품 ID |
|--------|---------|
| Android | `oneplace_premium_unlock` |
| iOS | `oneplace_premium_unlock` |

### Firebase 프로젝트 정보

| 항목 | 값 |
|------|-----|
| Package Name | `com.oneplace.one_place` |
| SHA-1 | `F1:6A:DD:6E:88:60:5D:61:96:12:B8:16:EC:1D:EB:F9:55:2A:AC:45` |
| Firestore 리전 | `asia-northeast3` (서울) |
| Web Client ID | `724852226968-geru9evdjcd9dbhoovngav9q1etpr75f.apps.googleusercontent.com` |

---

## 9️⃣ 예상 비용 (Firebase Spark 무료 플랜)

| 항목 | 무료 한도 | 예상 사용량 (유저 100명) |
|------|----------|------------------------|
| Firestore 저장 | 1GB | ~10MB ✅ |
| 읽기 | 50,000/일 | ~500/일 ✅ |
| 쓰기 | 20,000/일 | ~200/일 ✅ |
| Auth | 무제한 | 무제한 ✅ |

> 💚 **초기 운영: 완전 무료!**

---

## 🔟 개발 가이드

### 로컬 실행

```bash
# Flutter SDK 확인
flutter --version

# 의존성 설치
flutter pub get

# 디바이스 목록 확인
flutter devices

# 실행
flutter run
```

### 빌드

```bash
# Android Debug APK
flutter build apk --debug

# Android Release APK
flutter build apk --release

# iOS (macOS에서만)
flutter build ios --release
```

### Hive 코드 생성

```bash
# Hive 어댑터 생성
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📚 관련 문서

| 문서 | 경로 | 설명 |
|------|------|------|
| 아키텍처 | `docs/architecture.md` | Firebase 설계 상세 |
| Firebase 설정 | `docs/FIREBASE_SETUP.md` | Firebase Console 설정 가이드 |
| 이 문서 | `docs/PROJECT_INFO.md` | 프로젝트 전체 정보 |

---

~/Library/Android/sdk/emulator/emulator -avd Pixel_7
~/Library/Android/sdk/emulator/emulator -avd Pixel_7 -no-snapshot-load

cd one_place
flutter run


*문서 작성일: 2025-01-18*
*최종 업데이트: 2026-03-21*
