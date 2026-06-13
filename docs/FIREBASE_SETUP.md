# OnePlace Firebase 설계 및 구현 가이드

> 50~70대를 위한 초간단 정보 저장 앱 - Firebase 백업 시스템

---

## 📐 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        OnePlace 앱                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Frontend: Flutter + Riverpod                                   │
│  Local DB: Hive (오프라인 우선)                                  │
│  Cloud DB: Cloud Firestore (백업/동기화)                         │
│  Auth: Firebase Authentication (Google)                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

핵심 원칙: 유저 단위 데이터 분리 + read/write 최소화 + 단순한 쿼리
```

---

## 1️⃣ Firestore 데이터 구조

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
        │       ├── theme: "light"
        │       └── autoSync: true
        │
        └── items/                   # 저장된 항목들 (Subcollection)
            ├── {itemId1}
            │   ├── content: "https://youtube.com/..."
            │   ├── extractedUrl: "https://youtube.com/..."
            │   ├── isUrl: true
            │   ├── title: null
            │   ├── createdAt: Timestamp
            │   └── updatedAt: Timestamp
            │
            └── {itemId2}
                ├── content: "메모 텍스트..."
                ├── extractedUrl: null
                ├── isUrl: false
                ├── createdAt: Timestamp
                └── updatedAt: Timestamp
```

### 데이터 예시

```json
// 📌 users/{uid}
{
  "name": "어머니",
  "email": "mom@gmail.com",
  "createdAt": "2025-01-01T00:00:00Z",
  "lastLoginAt": "2025-01-10T00:00:00Z"
}

// 📌 users/{uid}/items/{itemId}
{
  "content": "https://youtube.com/watch?v=abc123",
  "extractedUrl": "https://youtube.com/watch?v=abc123",
  "isUrl": true,
  "title": null,
  "createdAt": "2025-01-10T10:30:00Z",
  "updatedAt": "2025-01-10T10:30:00Z"
}
```

> ✔️ **모든 쿼리는 경로 자체로 제한** - `where userId == uid` 없이 `/users/{uid}/items`로 접근

---

## 2️⃣ Firestore 보안 규칙

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 유저 문서 및 모든 하위 컬렉션
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null 
                         && request.auth.uid == userId;
    }
  }
}
```

> ✔️ **유저는 자기 데이터만 접근 가능**

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

## 4️⃣ Flutter 패키지 (필수)

```yaml
dependencies:
  # Firebase
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  cloud_firestore: ^5.6.0
  google_sign_in: ^6.2.2
```

---

## 5️⃣ Firebase Console 설정 체크리스트

### Step 1: 프로젝트 생성
- [ ] https://console.firebase.google.com 접속
- [ ] 새 프로젝트 생성 (이름: `oneplace`)
- [ ] Google Analytics: 비활성화 (초기)

### Step 2: Android 앱 등록
- [ ] 패키지 이름: `com.oneplace.one_place`
- [ ] SHA-1: `F1:6A:DD:6E:88:60:5D:61:96:12:B8:16:EC:1D:EB:F9:55:2A:AC:45`
- [ ] `google-services.json` 다운로드
- [ ] 파일을 `android/app/` 폴더에 복사

### Step 3: Authentication 활성화
- [ ] Authentication → 시작하기
- [ ] Sign-in method → Google 활성화

### Step 4: Firestore 활성화
- [ ] Firestore Database → 데이터베이스 만들기
- [ ] 프로덕션 모드 선택
- [ ] 위치: `asia-northeast3` (서울)
- [ ] 보안 규칙 설정 (위 규칙 복사)

---

## 6️⃣ 동기화 전략

```
┌─────────────────────────────────────────────────────────────────┐
│                     동기화 워크플로우                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [로컬 저장]                    [클라우드 동기화]                 │
│                                                                 │
│  공유 수신 ──→ Hive 저장 ──→ (로그인 시) ──→ Firestore 업로드   │
│                                                                 │
│  [복원]                                                         │
│                                                                 │
│  새 기기 ──→ Google 로그인 ──→ Firestore 다운로드 ──→ Hive 저장 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 동기화 규칙

1. **오프라인 우선**: 항상 Hive에 먼저 저장
2. **백그라운드 동기화**: 로그인 상태면 자동 업로드
3. **충돌 해결**: `updatedAt` 기준 최신 데이터 우선
4. **삭제 동기화**: soft delete (`isDeleted: true`) 사용

---

## 7️⃣ 예상 비용 (Firebase Spark 무료 플랜)

| 항목 | 무료 한도 | 예상 사용량 (유저 100명) |
|------|----------|------------------------|
| Firestore 저장 | 1GB | ~10MB ✅ |
| 읽기 | 50,000/일 | ~500/일 ✅ |
| 쓰기 | 20,000/일 | ~200/일 ✅ |
| Auth | 무제한 | 무제한 ✅ |

> 💚 **초기 운영: 완전 무료!**

---

## 8️⃣ 구현 파일 구조

```
lib/
├── core/
│   ├── services/
│   │   ├── share_receiver_service.dart  # 기존
│   │   ├── auth_service.dart            # NEW: Firebase Auth
│   │   └── sync_service.dart            # NEW: Firestore 동기화
│   └── ...
│
├── features/
│   ├── auth/                            # NEW
│   │   ├── presentation/
│   │   │   └── screens/
│   │   │       └── login_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── settings/                        # NEW
│   │   └── presentation/
│   │       └── screens/
│   │           └── settings_screen.dart
│   │
│   └── saved_items/                     # 기존
│       └── ...
│
└── main.dart                            # Firebase 초기화 추가
```

---

## ✅ 다음 단계

1. Firebase Console 프로젝트 생성
2. `google-services.json` 다운로드 및 추가
3. Flutter Firebase 패키지 설치
4. Auth 서비스 구현
5. Sync 서비스 구현
6. 설정 화면 UI 추가

---

*문서 작성일: 2025-12-25*

