# CreditSea Loan App

A loan application app built with **Flutter + GetX** and a **Node.js + Express + MongoDB** backend, implementing the CreditSea Flutter developer assignment and its Figma design.

Users sign up with their mobile number (OTP), complete a short profile (personal details, email, PAN, income), check their eligibility in a loan calculator, accept an offer, and track the application from **Submitted → Under Review → Approved/Rejected → Disbursed**, then repay it with a mock UPI flow that raises their credit score.

| Deliverable | Link |
| --- | --- |
| Android APK | _add Google Drive link_ |
| Demo video | _add YouTube/Drive link_ |
| Backend API (Render) | `https://creditsea-loan-api.onrender.com/api/v1` · [health check](https://creditsea-loan-api.onrender.com/api/v1/health) |

---

## Features

| Assignment requirement | Implementation |
| --- | --- |
| Mobile number auth with OTP | 4-digit OTP (as in Figma) with 30 s resend timer, attempt limits and hashed storage. New users then **create a password**; returning users sign in with mobile + password, or use **Forgot password** (OTP → new password). |
| Store profile (Name, DOB, Gender, PAN, Email, …) | Personal details, email verified by a 6-digit code, PAN format + uniqueness check, employment type and monthly income. Each step can be edited later from **Profile**. |
| Stay logged in until manual logout | Token stored on device (GetStorage); the session is refreshed (sliding 30-day expiry) on every launch and revoked server-side on logout. |
| Loan calculator (amount + tenure) | Sliders for ₹5,000–₹1,00,000 and 20–45 days. Pricing updates instantly; a GetX `debounce` worker re-checks eligibility with the API when the user stops dragging. |
| Basic eligibility logic | Age 21–60, salaried/self-employed, income ≥ ₹15,000/month, credit score ≥ 600, one active loan at a time. Limit = income × employment factor × credit-score factor (capped at ₹1,00,000). Failed rules are explained to the user. |
| Submit application to backend | "Our Offerings" shows the offer (reduced to the limit if needed); **Accept Offer** creates the application. |
| Status tracking | Timeline from the Figma "Application Status" screen merged with the required flow: Submitted → Under Review → Approved/Rejected → E-KYC → E-NACH → E-Sign → Disbursement → Repayment. The screen polls while the backend is processing and announces changes in-app. |
| Approval logic | Underwriting re-runs the eligibility rules plus a sandbox credit-bureau check when the review finishes. An admin API can also approve/reject/disburse manually. |
| Responsive Material UI | Matches the Figma screens (Montserrat, colours, cards, step indicator). Phones get a single column; tablets/iPad get a two-panel auth layout and a two-column dashboard. |
| **Bonus**: credit scoring | Internal score (starts at 650): +30 for repaying on time, +10 if late, +5 per part payment. Score bands change the loan limit. |
| **Bonus**: notifications for loan updates | In-app notifications when the application status changes (see _Trade-offs_ about push). |
| **Bonus**: mock UPI repayment | Full or part payment with a UPI ID; a sandbox gateway approves it (or declines `fail@upi`). |

## Tech stack

- **App:** Flutter 3.50 (Dart 3.14), GetX 4.7 (state, routing, DI, GetConnect HTTP), GetStorage, intl
- **Backend:** Node.js (ESM), Express 5, Mongoose 9 / MongoDB, Zod validation, JWT sessions, bcrypt, Helmet, rate limiting
- **Tests:** `node:test` + Supertest + in-memory MongoDB (28 API/unit tests); Flutter unit, controller and widget tests
- **CI:** GitHub Actions runs both test suites and builds the release APK; a scheduled job keeps the free Render server awake

## Project structure

```
creditsea-loan-app/
├── app/                         Flutter app
│   └── lib/
│       ├── main.dart
│       └── app/
│           ├── app.dart         GetMaterialApp (theme, routes, initial binding)
│           ├── core/            theme, widgets, utils, ApiGuard mixin, InitialBinding
│           ├── data/            models, ApiClient (GetConnect), repositories, services
│           ├── modules/         one folder per feature: binding + controller + view
│           │   ├── splash/  auth/  onboarding/  home/
│           │   ├── loan_calculator/  loan_offer/  loan_status/
│           │   └── repayment/  profile/
│           └── routes/          route names, GetPage table, AuthGuard middleware
├── backend/
│   ├── src/
│   │   ├── config/              env validation, loan product & credit policy
│   │   ├── models/              User, Otp, Session, Loan, Counter
│   │   ├── services/            otp, token, eligibility, underwriting, loan lifecycle, pricing, credit score
│   │   ├── controllers/  routes/  middleware/  validators/
│   │   ├── app.js               Express app (no side effects; used by tests)
│   │   └── server.js            DB connection, HTTP server, lifecycle scheduler
│   └── tests/
├── render.yaml                  one-click Render deployment
└── .github/workflows/
    ├── ci.yml                   tests + release APK (pushes to main, pull requests)
    └── keep-alive.yml           pings the API so Render's free plan doesn't sleep
```

## How GetX is used

| GetX feature | Where |
| --- | --- |
| Reactive state: `.obs`, `Rx<T>`, `Obx` | Every controller exposes observables; views rebuild only the `Obx` parts that read them. |
| Controllers & lifecycle (`onInit`, `onReady`, `onClose`) | `modules/*/..._controller.dart`: load data in `onInit`, dispose text controllers/timers/workers in `onClose`. |
| Dependency injection: `Bindings`, `Get.put`, `Get.lazyPut`, `Get.find` | `InitialBinding` registers app-wide services (storage, API client, repositories, session) once; each route's binding creates its controller lazily. Tests swap in fake repositories the same way. |
| Services: `GetxService` | `StorageService` and `SessionService` (signed-in user, token restore/refresh, logout) live for the whole app. |
| Routing: `GetPage`, `Get.toNamed`, `Get.offAllNamed`, `GetMiddleware` | `routes/app_pages.dart`; `AuthGuard` redirects signed-out users to Sign in. |
| Workers: `debounce`, `ever` | Loan calculator: eligibility check 600 ms after the slider stops. |
| Networking: `GetConnect` | `ApiClient` adds the bearer token, unwraps API errors and signs the user out on 401. |
| UI helpers: `Get.snackbar`, `Get.dialog`, `Get.bottomSheet` | Notifications, payment dialogs, E-KYC/E-NACH/E-Sign sheets. |

> **Note on Material imports:** Flutter 3.47+ deprecates `package:flutter/material.dart` in favour of the separate `material_ui` package, which defines its own copies of the Material classes. GetX 4.x is built on the framework's Material types, so the app imports Material through one file, `lib/app/core/material.dart`. Moving to `material_ui` when GetX supports it is then a one-line change.

## Running locally

### 1. Backend

```bash
cd backend
npm install
npm run dev        # http://localhost:4000/api/v1
npm test           # 28 tests against an in-memory MongoDB
```

No database setup is needed for development: without `MONGODB_URI` the server starts a temporary in-memory MongoDB. Copy `.env.example` to `.env` to use a real database or change the settings.

### 2. Flutter app

```bash
cd app
flutter pub get
flutter run                                    # Android emulator uses http://10.0.2.2:4000
flutter run -d chrome                          # web, uses http://localhost:4000
flutter run --dart-define=API_BASE_URL=https://<your-api>/api/v1   # any backend
flutter test
```

### 3. Release APK

```bash
cd app
flutter build apk --release --dart-define=API_BASE_URL=https://<your-api>/api/v1
# -> app/build/app/outputs/flutter-apk/app-release.apk
```

Release builds only allow HTTPS, so point them at the deployed backend. Debug builds also allow plain HTTP for a local backend. The APK linked above is built with `API_BASE_URL=https://creditsea-loan-api.onrender.com/api/v1`.

## Deployment (MongoDB Atlas + Render)

1. Create a free MongoDB Atlas cluster and copy its connection string.
2. On Render: **New → Blueprint**, select this repository. `render.yaml` creates the web service (root `backend/`, health check `/api/v1/health`) and generates `JWT_SECRET` and `ADMIN_API_KEY`.
3. Paste the Atlas connection string into `MONGODB_URI` and deploy.
4. Build the APK with `API_BASE_URL=https://<service>.onrender.com/api/v1` (or set it as the `API_BASE_URL` repository variable so CI builds it).

The free Render plan sleeps after 15 minutes without traffic, and the next request can then take ~50 s (the app's request timeout allows for this). To avoid that, the **Keep API awake** workflow (`.github/workflows/keep-alive.yml`) pings the health check every 5 minutes; one always-on service fits in Render's 750 free hours a month. Disable it from the Actions tab when it is no longer needed.

## Demo guide

| To show | Do this |
| --- | --- |
| OTP without an SMS provider | The backend runs in demo mode (`OTP_DEV_MODE=true`): the code is returned by the API and shown in the app with an **Autofill** button. Set it to `false` and configure Twilio (SMS) / Resend (email) for real delivery. |
| Approval | Any personal PAN, e.g. `ABCPE1234F`, income ≥ ₹15,000. The application moves to Under Review after ~20 s and gets a decision ~40 s later (configurable). |
| Rejection | Sandbox bureau: a PAN whose number part starts with **9** (e.g. `ABCPE9123F`) returns a poor credit record and the application is rejected. |
| Amount above limit | Ask for more than your limit; the offer is reduced and the screen explains why. |
| Not eligible | Choose Student, or an income below ₹15,000: the offer screen lists which rules failed. |
| Repayment + credit score | After disbursal, **Repay** → full amount → any UPI ID (`name@okaxis`). The score goes 650 → 680. `fail@upi` shows a declined payment. |
| Manual control | `curl -X PATCH -H "x-admin-key: $ADMIN_API_KEY" -H "Content-Type: application/json" -d '{"status":"APPROVED"}' $API/admin/loans/<id>/status` |

## API

Base path: `/api/v1`. Errors always look like `{ "error": { "code": "OTP_INVALID", "message": "Incorrect code. 4 attempts left." } }`.

| Method | Path | Description |
| --- | --- | --- |
| POST | `/auth/otp/send` | Send a 4-digit OTP to `{ phone }` |
| POST | `/auth/otp/verify` | `{ phone, otp }` → `{ token, user, isNewUser }` (creates the account) |
| POST | `/auth/login` | `{ phone, password }` → `{ token, user }` |
| POST | `/auth/password` | Set password (replacing one requires a session verified by OTP in the last 15 min) |
| POST | `/auth/refresh` | Slide the session expiry, returns a new token |
| POST | `/auth/logout` | Revoke the current session |
| GET | `/users/me` | Current user, including `onboardingStep` and credit score |
| PUT | `/users/me/personal` | First/last name, gender, DOB, marital status |
| POST | `/users/me/email/send-otp` · `/users/me/email/verify` | Verify an email with a 6-digit code |
| POST | `/users/me/pan/verify` | Verify a personal PAN |
| PUT | `/users/me/employment` | Employment type and monthly income |
| GET | `/loans/config` | Amount/tenure ranges, rates, purposes (public) |
| POST | `/loans/quote` | Eligibility checks + offer for `{ principal, tenureDays }` |
| POST | `/loans` | Apply `{ principal, tenureDays, purpose }` |
| GET | `/loans` · `/loans/:id` | Applications with status history (due transitions are applied on read) |
| POST | `/loans/:id/ekyc` · `/enach` · `/esign` | Post-approval steps |
| POST | `/loans/:id/repayments` | Mock UPI repayment `{ amount, upiId }` |
| GET / PATCH | `/admin/loans` · `/admin/loans/:id/status` | Admin (requires `x-admin-key`) |

## Design decisions and trade-offs

- **Loan pipeline:** status changes are time-based and applied both by a background sweep and lazily when a loan is read, using atomic `findOneAndUpdate` transitions. That keeps it race-safe and makes it work on serverless hosts (e.g. Vercel) where timers don't run.
- **Same rules everywhere:** the quote shown to the user and the final underwriting decision use the same eligibility function, so the app never promises something the backend then refuses for a different reason (only the sandbox bureau check is extra).
- **Pricing from the design:** 1% interest per day and a 10% processing fee (deducted at disbursal), as shown in Figma. All product values live in `backend/src/config/loanProduct.js` and reach the app through `/loans/config`.
- **Security:** OTPs are HMAC-hashed with expiry, resend cool-down and attempt limits; passwords use bcrypt; sessions are revocable; OTP/login routes are rate-limited; PAN, Aadhaar and bank account numbers are stored or shown only masked.
- **Sandboxed integrations:** SMS/email OTP, PAN verification, E-KYC, E-NACH, E-Sign, the credit bureau and the UPI gateway are simulated, with clear extension points (`notification.service.js`, `underwriting.service.js`, `loan.service.js`).
- **Notifications:** status updates are pushed to the user in-app while the status screen is open. True push notifications would need a Firebase project (FCM). The backend already has a single place where status transitions happen to trigger them from.
- **Figma additions:** the design has no dashboard, profile or income screen, so these were added in the same visual language. The income screen is needed for eligibility; the others for "manage profile" and "track status".
