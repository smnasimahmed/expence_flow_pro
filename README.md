# ExpenseFlow Pro

A personal finance tracker built with Flutter — offline-first, Firebase-synced, and designed to stay out of your way.

---

## What it does

Track expenses, manage multiple wallets, set monthly budgets, and automate recurring transactions. Everything works offline; changes sync to Firestore silently in the background when connectivity returns.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Material 3, dark theme) |
| State Management | GetX |
| Local Database | Drift (SQLite via `drift/native`) |
| Cloud Backend | Firebase Firestore |
| Auth | Firebase Authentication (Email/Password) |
| Local Persistence | GetStorage |
| Routing | GetX named routes |
| Code Generation | `build_runner` + Drift codegen |

---

## Features

- **Multi-wallet support** — Cash, bank, savings, or custom wallet types with color coding
- **Expense tracking** — Full CRUD with category tagging, wallet association, and optional notes
- **Budget management** — Monthly budgets per category with spend tracking
- **Recurring transactions** — Schedule repeating expenses with configurable frequency and auto-execution
- **Wallet transfers** — Move funds between wallets with a full transfer history
- **Analytics** — Spending breakdowns and trends across categories and time
- **Offline-first** — All writes hit SQLite immediately; Firestore sync happens asynchronously
- **Remember Me** — Persisted sessions via GetStorage; cleared only on explicit logout
- **Conflict resolution** — Last-write-wins using `lastModified` timestamps on every record

---

## Architecture

The project follows a feature-first structure. Each feature owns its binding, controller, model, repository, and view. There's no shared state leaking across features — everything gets injected through GetX bindings at route load time.

```
lib/
├── core/
│   ├── constants/        # Theme, strings
│   ├── services/         # Connectivity, storage, logging
│   ├── utils/            # Navbar, shared utilities
│   └── widgets/          # Reusable UI components
│
├── database/             # Drift database + generated code
│
├── features/
│   ├── auth/             # Sign in, sign up, forgot password
│   ├── expense/          # Add, list, delete expenses
│   ├── wallet/           # Wallet management
│   ├── budget/           # Monthly budget tracking
│   ├── recurring/        # Recurring transaction scheduling
│   ├── transfer/         # Wallet-to-wallet transfers
│   ├── analytics/        # Charts and spending insights
│   ├── settings/         # Currency, preferences
│   └── sync/             # Background Firestore sync controller
│
└── routes/               # Named routes and initial route logic
```

---

## Offline Sync Design

Every mutation (create, update, delete) writes to Drift first with `isSynced = false`. The `SyncController` watches network state via `ConnectivityService` and flushes unsynced records to Firestore when online. Deletes use a tombstone pattern — deleted records sit in `DeletedExpenses` / `DeletedWallets` tables until the deletion is confirmed synced upstream.

Pull sync fetches only records updated after `lastSyncTime`, keeping bandwidth usage minimal.

---

## Firestore Data Model

```
users/{userId}
  ├── expenses/{expenseId}
  ├── wallets/{walletId}
  ├── budgets/{budgetId}
  └── recurring/{recurringId}
```

Security rules enforce that users can only read and write their own subcollections. See [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) for the full rule set.

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- Dart SDK ≥ 3.x
- A Firebase project (see [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md))

### 1. Clone and install dependencies

```bash
git clone https://github.com/your-username/expense-flow-pro.git
cd expense-flow-pro
flutter pub get
```

### 2. Configure Firebase

Follow [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md) to set up your Firebase project and generate `lib/firebase_options.dart`.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 3. Generate Drift database code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run

```bash
flutter run
```

---

## Firestore Security Rules

Paste these into **Firestore → Rules** and publish:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit with a clear message: `git commit -m "feat: add export to CSV"`
4. Push and open a PR against `main`

Keep controllers thin — business logic belongs in repositories. If you're adding a new feature, follow the existing `binding / controller / model / repository / view` structure.

---

## License

MIT
