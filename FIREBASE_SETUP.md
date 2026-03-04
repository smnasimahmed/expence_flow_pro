# 🔥 Firebase Setup – ExpenseFlow Pro

Follow these steps **exactly once** per project.

---

## Step 1 – Create Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project**
3. Name it `expense-flow` (or anything you like)
4. Disable Google Analytics (optional for now)
5. Click **Create project**

---

## Step 2 – Enable Authentication

1. In Firebase Console → **Authentication** → **Get started**
2. Click **Email/Password** → Enable → Save

---

## Step 3 – Enable Firestore

1. Firebase Console → **Firestore Database** → **Create database**
2. Choose **Start in production mode**
3. Select your region (pick closest to you)

---

## Step 4 – Set Firestore Security Rules

Go to **Firestore → Rules** and paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /expenses/{expenseId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /wallets/{walletId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /budgets/{budgetId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }

      match /recurring/{recurringId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Click **Publish**.

---

## Step 5 – Add Flutter App to Firebase

### Android

1. Firebase Console → Project settings → **Add app** → Android
2. Enter your app package name (from `android/app/build.gradle` → `applicationId`)
   - Example: `com.yourname.expenseflow`
3. Download `google-services.json`
4. Place it at: `android/app/google-services.json`

### iOS

1. Firebase Console → Project settings → **Add app** → iOS
2. Enter your iOS Bundle ID (from Xcode → Runner → Bundle Identifier)
   - Example: `com.yourname.expenseFlow`
3. Download `GoogleService-Info.plist`
4. Place it at: `ios/Runner/GoogleService-Info.plist`
5. Open Xcode → right-click Runner folder → **Add Files to Runner** → select the plist

---

## Step 6 – Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

---

## Step 7 – Auto-generate firebase_options.dart

In your project root, run:

```bash
flutterfire configure
```

This will:
- Detect your Firebase project
- Generate `lib/firebase_options.dart` automatically
- Replace the placeholder file already in the project

---

## Step 8 – Android gradle setup

In `android/build.gradle`, add to dependencies:
```groovy
classpath 'com.google.gms:google-services:4.4.0'
```

In `android/app/build.gradle`, add at the bottom:
```groovy
apply plugin: 'com.google.gms.google-services'
```

---

## Step 9 – Run the app

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

---

## Firestore Data Structure

```
users/{userId}
  ├── expenses/{expenseId}
  │     id, userId, title, amount, categoryId, walletId,
  │     date, notes, isDeleted, lastModified
  │
  ├── wallets/{walletId}
  │     id, userId, name, type, initialBalance, color,
  │     isDeleted, lastModified
  │
  ├── budgets/{budgetId}
  │     id, userId, categoryId, amount, month, year, lastModified
  │
  └── recurring/{recurringId}
        id, userId, title, amount, walletId, categoryId,
        frequency, nextExecutionDate, isActive, lastModified
```

---

## Remember Me – How it works

- On sign in: if **Remember Me** checkbox is checked → `StorageService.rememberMe = true`
- On app start: `AppRoutes.initialRoute` checks `rememberMe && userId.isNotEmpty`
- If both true → goes directly to dashboard without sign in
- On logout: `StorageService.clearAll()` wipes everything → next start goes to sign in
- Uses `GetStorage` (persists on device, survives app restarts, cleared only on logout or reinstall)

---

## Offline-First – How it works

1. Every write goes to **Drift (SQLite)** first with `isSynced = false`
2. `SyncController` watches connectivity via `ConnectivityService`
3. When internet returns → pushes all `isSynced = false` records to Firestore
4. Pulls records updated after `lastSyncTime` from Firestore
5. **Conflict resolution**: latest `lastModified` wins

The user never waits for network. Everything is instant.
