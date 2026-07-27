# InvoiceBill — Flutter Conversion

Flutter port of the React "Invoice Frontend" (KnowledgeVista/InvoiceBill) app: an
invoicing + LMS-style admin system with Admin/Trainer(Supplier)/Student(Customer)/
Cashier/Sysadmin roles, item & course management, sales & estimate invoicing,
certificates, payments (Stripe/PayPal/Razorpay), and Google Drive backup.

> **Status: Sales module (list + create/edit for both Sale invoices and
> Estimates) is now functional, several real navigation/UX bugs are
> fixed (blank-screen-after-save, missing Add Supplier button,
> disorienting auto-navigation in the Items section), and
> AddCustomer/AddSupplier were rebuilt fully mobile-first.**
> 
> Several routes in the original React app turned out to be entirely
> commented-out dead code (no active export) — those are reproduced as
> honest "currently non-functional" stubs rather than invented UI. Two
> real, substantial files (`AdminRegister.js`, `Approvals.js`) are
> deliberately deferred. See `CONVERSION_STATUS.md` for the full,
> file-by-file breakdown of what's converted, what's a dead-code stub,
> and what's still a genuine placeholder.

## Overview

This project preserves, screen-by-screen, the original React app's:
- UI layout, colors (`#0f2027` / `#1a3a4a` / `#0d3b52` / `#4fc3f7`), and typography
  (Playfair Display headings + Open Sans body, matching `invoicestyle.css`)
- API endpoints, HTTP methods, request/response shapes, and auth header pattern
  (raw `Authorization: <token>` header, not `Bearer <token>` — matches the backend)
- Route structure and role-based route guards (Admin / Trainer / User(Student) /
  Cashier / Sysadmin), ported 1:1 from `PrivateRoute.js`
- Session/local state equivalents of `sessionStorage` and the React
  `GlobalStateProvider` context

No functionality has been redesigned, simplified, or replaced with mock data.
Where a screen hasn't been converted yet, it's a clearly-labeled placeholder
that names the exact original React file to convert next — nothing is silently
faked.

## Tech stack

| Concern              | React (original)                 | Flutter (this project) |
|-----------------------|-----------------------------------|--------------------------|
| HTTP client           | axios                             | `dio` |
| Routing               | react-router-dom v6               | `go_router` |
| Global/shared state    | React Context (`GlobalStateProvider`) | `provider` (`ChangeNotifier`) |
| Session storage        | `window.sessionStorage`           | `shared_preferences` |
| Charts                 | apexcharts / react-apexcharts     | `fl_chart` |
| PDF export              | jspdf / html2pdf.js               | `pdf` + `printing` |
| Fonts/icons             | Open Sans, FontAwesome            | `google_fonts`, `font_awesome_flutter` |
| Alerts/dialogs           | SweetAlert2                       | native `showDialog` |

## Project structure

```
lib/
  core/
    api/api_client.dart          # Dio client; mirrors src/api/utils.js baseUrl + axios auth header
    session/session_manager.dart # sessionStorage equivalent (token/role/userid/email/...)
    state/global_state_provider.dart # Context/GlobalStateProvider.js equivalent
    routing/app_router.dart      # App.js route table + PrivateRoute.js guards
  theme/app_theme.dart           # Colors/fonts pulled from assets/css/invoicestyle.css
  features/
    auth/login_screen.dart       # Full conversion of AuthenticationPages/login.js
    dashboard/dashboard_shell_screen.dart # Landing screen after login (/dashboard/viewitem)
    placeholder/placeholder_screen.dart   # Stand-in for not-yet-converted screens
  main.dart                      # App bootstrap; mirrors src/index.js
```

## Prerequisites

- Flutter SDK 3.22+ (Dart 3.3+) — https://docs.flutter.dev/get-started/install
- A running instance of the backend API this frontend talks to (the same
  Spring/Java-style backend the React app used at `http://localhost:8081`,
  based on `.env` in the original project)
- Xcode (for iOS) and/or Android Studio (for Android) if targeting mobile;
  Chrome for web

## Setup

```bash
cd invoicebill_flutter
flutter pub get
```

## Running

The React app read its API base URL from `.env`
(`REACT_APP_API_URL=http://localhost:8081`). Flutter has no `.env`/webpack
substitution step, so pass the same value via `--dart-define` at run time:

```bash
# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8081

# Android emulator (use 10.0.2.2 instead of localhost to reach your host machine)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8081

# iOS simulator
flutter run -d "iPhone 15" --dart-define=API_BASE_URL=http://localhost:8081
```

If `--dart-define` is omitted, it defaults to `http://localhost:8081` (see
`lib/core/api/api_client.dart`), matching the original `.env` default.

### Building

```bash
flutter build apk --dart-define=API_BASE_URL=https://your-api.example.com
flutter build ios --dart-define=API_BASE_URL=https://your-api.example.com
flutter build web --dart-define=API_BASE_URL=https://your-api.example.com
```

## Authentication flow (converted from `login.js`)

- `GET /Active/Environment` on load — caches active profile + currency
- `GET /count/admin` on load — controls whether "New user?" registration
  link is shown
- `POST /login` with `{ username, password }`
  - `200` → stores `token`, `role`, `userid`, `email`; if `role == CASHIER`
    also fetches `GET /cashier/permissions/{userid}` and caches per-module
    permissions; then routes to `/viewAll/Admins` (SYSADMIN) or
    `/dashboard/viewitem` (everyone else)
  - `404` → "User not found" under the email field
  - `401` with `message: "Incorrect password"` → shows remaining attempts
  - `401` with `message: "In Active"` / `"Not Approved"` → alert dialog

Client-side validation matches the original exactly: email must match
`^[^\s@]+@[^\s@]+\.com$`, password must be ≥ 6 characters.

## Route guards (converted from `PrivateRoute.js`)

Every route carries the same guard flags as the original
(`authenticationRequired`, `authorizationRequired`, `onlyadmin`, `onlyuser`,
`onlytrainer`, `sysadmin`, `sysandadmin`), evaluated with identical logic in
`lib/core/routing/app_router.dart`.

## Continuing the conversion

See `CONVERSION_STATUS.md` for the full route/file checklist. To convert the
next screen:

1. Open the referenced React file under the original project's `src/`.
2. Create the matching Dart file under `lib/features/<module>/`.
3. Replace its `PlaceholderScreen` builder in `app_router.dart` with the new
   screen widget.
4. Reuse `ApiClient.instance.dio` for all requests (it already attaches the
   `Authorization` header) and `SessionManager` / `GlobalStateProvider` for
   any state the original read from `sessionStorage` / React Context.

## Notes / known gaps

- The original app's global `window.onerror` / unhandled-rejection handler
  (SweetAlert2 "Some Error Occurred" + "Send Mail" button hitting
  `GET /log/time/10`) is not yet re-implemented; see the TODO note in
  `lib/main.dart`.
- Rich UI modules (video/slide players, Quill editor, ApexCharts dashboards,
  Stripe/PayPal card elements, Google Drive OAuth backup flow) require
  Flutter-specific packages beyond the base set installed here and will be
  added when those screens are converted.
