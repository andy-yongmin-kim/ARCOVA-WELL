---
name: one-place
description: 한곳에 (One Place) Flutter 앱 개발용 스킬. 50~70대向け情報保存アプリ. 공유 수신, 카테고리 분류, Firebase 백업, 인앱 결제 기능 포함.
---

# 한곳에 (One Place) 개발 스킬

## 프로젝트 개요

**한곳에**는 Flutter 기반 정보 저장 앱입니다. 다른 앱에서 공유받은 링크/텍스트를 저장하고, 카테고리별로 자동 분류하며, Firebase로 클라우드 백업하는 기능을 제공합니다.

### 핵심 기능

- 공유 수신 (Share Intent)
- URL 자동 감지 및 카테고리 분류
- 로컬 저장 (Hive) + 클라우드 동기화 (Firestore)
- Google 로그인
- 인앱 결제 (프리미엄)

---

## 아키텍처 요약

```
┌─────────────────────────────────────────┐
│  Flutter + Riverpod (상태 관리)         │
├─────────────────────────────────────────┤
│  Hive (로컬)  ←→  Cloud Firestore (백업) │
├─────────────────────────────────────────┤
│  Firebase Auth (Google 로그인)          │
│  In-App Purchase (프리미엄 결제)         │
└─────────────────────────────────────────┘
```

### 설계 원칙

- **오프라인 우선**: Hive에 먼저 저장
- **유저 중심 구조**: `users/{uid}/items` 경로 기반
- **비용 효율**: read/write 최소화, pagination 필수

---

## 주요 파일 위치

| 파일 | 경로 | 설명 |
|------|------|------|
| 메인 | `lib/main.dart` | Firebase/Hive 초기화 |
| 앱 | `lib/app.dart` | MaterialApp, 공유 수신 시작 |
| 홈 화면 | `lib/features/saved_items/presentation/screens/home_screen.dart` | 메인 화면 |
| 설정 화면 | `lib/features/settings/presentation/screens/settings_screen.dart` | 로그인, 백업, 결제 |
| 데이터 모델 | `lib/features/saved_items/data/models/saved_item.dart` | SavedItem, ItemCategory |
| 저장소 | `lib/features/saved_items/data/repositories/saved_item_repository.dart` | Hive CRUD |
| 상태 관리 | `lib/features/saved_items/providers/saved_items_provider.dart` | Riverpod |
| Auth | `lib/core/services/auth_service.dart` | Firebase Auth |
| 결제 | `lib/core/services/payment_service.dart` | 인앱 결제 |
| 동기화 | `lib/core/services/sync_service.dart` | Firestore 동기화 |

---

## 데이터 모델

### SavedItem

```dart
class SavedItem extends HiveObject {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isUrl;
  String? title;
  final String? extractedUrl;
  String category; // ItemCategory.name 저장
}
```

### ItemCategory

```dart
enum ItemCategory {
  all, news, video, shopping, sns, travel, food, music, memo, other
}
```

### Firestore 경로

```
users/{uid}/items/{itemId}
```

---

## 주요 Provider

```dart
// 저장된 항목 목록
final savedItemsProvider = StateNotifierProvider<SavedItemsNotifier, List<SavedItem>>

// 카테고리 필터
final selectedCategoryProvider = StateProvider<ItemCategory>

// 검색어
final searchQueryProvider = StateProvider<String>

// 프리미엄 상태
final premiumStatusProvider = StateNotifierProvider<PremiumNotifier, bool>

// 로그인 상태
final isLoggedInProvider = Provider<bool>
```

---

## 일반적인 개발 작업

### 새 기능 추가

1. `lib/features/saved_items/` 또는 새 feature 디렉토리 생성
2. `data/models/` - 데이터 모델 정의
3. `data/repositories/` - 저장소 구현
4. `providers/` - Riverpod 상태 관리
5. `presentation/screens/` - 화면 구현
6. `presentation/widgets/` - 재사용 위젯

### 새 카테고리 추가

1. `ItemCategory` enum에 추가
2. `ItemCategoryExtension`에 `displayName`, `emoji` 추가
3. `_guessCategory()`에 분류 규칙 추가
4. `SavedItemCard._getCategoryColor()`에 색상 추가

### Firestore 동기화 수정

1. `lib/core/services/sync_service.dart` 확인
2. `lib/features/saved_items/providers/saved_items_provider.dart`의 `addItem`, `deleteItem` 수정
3. 보안 규칙: `docs/PROJECT_INFO.md` 참고

### 결제 시스템 수정

1. 상품 ID: `lib/core/services/payment_service.dart`
   - Android: `kPremiumProductIdAndroid`
   - iOS: `kPremiumProductIdIOS`
2. Google Play Console/App Store Connect에서 상품 등록

---

## ⚠️ 출시 전 체크리스트

| 항목 | 위치 | 작업 |
|------|------|------|
| **테스트 모드 해제** | `settings_screen.dart:148` | `kTestMode = false` 변경 |
| **인앱 결제** | Google Play Console | `oneplace_premium_unlock` 상품 등록 |
| **Firebase** | Firebase Console | Auth, Firestore 활성화 확인 |
| **SHA-1** | Android 서명 | 릴리스 서명 SHA-1 추가 |

---

## 빌드 및 실행

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (Hive)
flutter pub run build_runner build --delete-conflicting-outputs

# 실행
flutter run

# APK 빌드
flutter build apk --debug
flutter build apk --release
```

---

## 참고 자료

- 전체 문서: `docs/PROJECT_INFO.md`
- Firebase 설정: `docs/FIREBASE_SETUP.md`
- 아키텍처 상세: `docs/architecture.md`
