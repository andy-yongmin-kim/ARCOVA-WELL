
# Flutter + Firebase 설계 문서

> 목적: **Cursor에서 바이브 코딩하면서 바로 구현 가능한 최소·안전·확장 가능한 설계 기준**

---

## 0. 전체 아키텍처 한눈에 보기

* **Frontend**: Flutter
* **Auth**: Firebase Authentication (Google / Apple / Email)
* **DB**: Cloud Firestore
* **File**: Firebase Storage (선택)
* **Analytics**: Firebase Analytics (선택)

> 핵심 원칙: *유저 단위 데이터 분리 + read/write 최소화 + 단순한 쿼리*

---

## 1️⃣ Flutter + Firebase 최소 세팅 체크리스트

### 1. Firebase 프로젝트 세팅

* Firebase Console → 새 프로젝트 생성
* Google Analytics ❌ (초기엔 꺼도 됨)

### 2. 앱 등록

* Android 앱 추가

  * package name 설정
  * `google-services.json` 다운로드
* iOS 앱 추가 (나중에 가능)

### 3. Flutter 패키지 (최소)

* firebase_core
* firebase_auth
* cloud_firestore
* firebase_storage (파일 있으면)

### 4. Firebase Auth 설정

* Sign-in method:

  * Google ✅
  * Apple (iOS 출시 시)
  * Email/Password (선택)

### 5. Firestore 기본 보안 규칙 (초기)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

> ✔️ **유저는 자기 데이터만 접근 가능**

---

## 2️⃣ Firestore 데이터 구조 예시 (실전용)

### 🔹 기본 철학

* **유저 중심 구조
컬렉션 구조
users/{uid}
├── profile
│ ├── name
│ ├── email
│ ├── createdAt
│ └── lastLoginAt
├── settings
│ ├── theme
│ └── notifications
└── items (subcollection)
├── {itemId}
│ ├── title
│ ├── content
│ ├── createdAt
│ └── updatedAt

📌 users/{uid}
{
"name": "Andy",
"email": "andy@gmail.com",
"createdAt": "2025-01-01",
"lastLoginAt": "2025-01-10"
}

📌 users/{uid}/items/{itemId}
{
"title": "메모 제목",
"content": "내용",
"createdAt": "timestamp",
"updatedAt": "timestamp"
}
✔️ 모든 쿼리는 where userId == uid 없이 경로 자체로 제한

3️⃣ 비용 폭탄 안 맞는 설계 패턴 🔥

✅ 권장 패턴
1. 경로 기반 접근
/users/{uid}/items
→ security + 비용 둘 다 안전


2. pagination 필수
limit(20)
startAfterDocument

3. 실시간 리스너 최소화
홈 화면 1개만 허용
나머지는 get()

