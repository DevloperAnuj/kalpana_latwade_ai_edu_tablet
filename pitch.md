# EduForge – AI-Powered Education Platform

**Company:** iMAlpha  
**Repository:** `kalpana_ai-edu-tablet`  
**Target Hardware:** Kalpana AI Education Tablet

| Specification | Detail |
|---|---|
| **Display** | 11" 2000×1200 IPS LCD, 500 nits (Incell technology) |
| **Calling** | 4G VoLTE Calling |
| **Processor** | UNISOC T618 (Tiger) 64-bit Octa-core @ 4.0 GHz |
| **GPU** | Mali-G52 MP2 @ 614 MHz |
| **RAM** | 8GB LPDDR5 |
| **Storage** | 256GB UFS + Expandable up to 1TB via microSD |
| **OS** | Android 12 |
| **Wi-Fi / Bluetooth** | Dual Band 5 GHz + 2.4 GHz a/b/g/n, BT 5.0 |
| **Audio** | Box Speakers |
| **Camera** | 5MP Front + 13MP Rear with Auto Focus |
| **Charging Port** | Type-C |
| **Build** | Metal Housing |
| **Battery** | 7500 mAh |
| **Dimensions** | 244 × 162 × 10 mm |
| **Weight** | 505 g |

---

## 📱 Application Features

EduForge is a two-app ecosystem — one for **teachers** (Windows desktop) and one for **students** (Android tablet) — working in tandem with a shared cloud database (sqlbase). The platform transforms any classroom into an AI-assisted learning environment where teachers can generate rich study material in seconds and students can consume it interactively and take handwritten digital notes.

---

### 🧑‍🏫 Teacher App (Windows Desktop)

| Feature | Description |
|---|---|
| **Class Management** | Create classes, generate 6-character unique join codes, view student rosters, soft-delete classes |
| **AI-Powered Topic Builder** | Paste lesson text or upload `.txt`/`.pdf` files; Gemini Flash 2.5 generates 5 content types simultaneously |
| **Mindmap** | Hierarchical node map generated from lesson content, zoomable and pannable |
| **Flashcards** | Flip-card deck (8–12 cards) for active recall, editable in preview |
| **Infographic** | Section-based visual summary with numbered cards, accent colors, and bullet points |
| **Comparison Table** | Structured data grid with headers and rows, editable |
| **Quiz (10 MCQs)** | 10-question multiple-choice quiz with 4 options each, explanations per answer |
| **Tabbed Preview** | Review all 5 material types in one screen with individual regeneration per tab |
| **Publish Workflow** | Preview → edit → publish; students see published topics in real time |
| **Live Quiz Results** | Real-time dashboard showing who attempted, scores, wrong-answer breakdown with explanations |
| **Draft Auto-Save** | Unsaved generation drafts are auto-saved every 10 seconds and restored on return |
| **Profile & Theme** | Edit display name, toggle dark/light theme |
| **AI Key Management** | Gemini API key stored per-teacher in sqlbase via secure RPC; refreshable from toolbar |

---

### 🧑‍🎓 Student App (Android Tablet)

| Feature | Description |
|---|---|
| **Join Class** | Enter 6-character teacher code to join a class, auto-capitalised input, instant feedback |
| **Browse Topics** | Grid of published topics per class; each topic comes with 5 study tools |
| **Mindmap Viewer** | Zoomable, pannable interactive mindmap with bezier connection lines and coloured root nodes |
| **Flashcard Viewer** | Tap to flip, swipeable, progress bar, shuffle mode, term/definition cards |
| **Infographic Viewer** | Rich card-based section summaries with numbered stripe accents, colour palette, bulleted content |
| **Comparison Table** | Horizontally scrollable data table with themed header row |
| **Quiz System** | 10 MCQ quiz with progress bar, one attempt only (enforced by DB unique constraint), instant grading |
| **Quiz Results** | Score banner with percentage, expandable wrong-answer review with explanations |
| **Digital Notebooks** | Hierarchical notebook organisation (Subjects → Chapters → Topics) |
| **Handwriting Canvas** | Full-page 2000×3000 drawing surface with pen/eraser/pan tools, ink-like bezier strokes |
| **Stroke Width & Color** | 8 pen widths (1–12px), 4 colours (black, blue, red, green) |
| **Page Patterns** | Ruled, grid, and graph paper backgrounds |
| **Undo / Redo** | Full stroke-level undo/redo with multi-level support |
| **Palm Rejection** | Stylus-aware: auto-detects stylus vs. touch, rejects palm contact heuristically |
| **OCR – Handwriting to Text** | Three engines configurable in Settings: |
| ― **ML Kit (Offline)** | Google on-device OCR, fast, free, no internet required |
| ― **MyScript iink (Offline)** | World-class handwriting recognition engine, offline-capable |
| ― **Gemini Flash (Cloud)** | Highest accuracy for messy/cursive writing, monthly quota tracked |
| **Auto-Fallback OCR** | Gemini → ML Kit fallback on network failure or quota exhaustion |
| **Cloud Sync** | Notebooks and pages sync to sqlbase when online; local-first with offline support |
| **Local Persistence** | All notebooks and strokes saved locally via Hive, survive app restarts |
| **Profile & Theme** | Edit display name and roll number, toggle dark/light theme |
| **Settings** | OCR engine selector with quota usage indicator and engine descriptions |

---

## 🏗️ File & Folder Architecture

```
kalpana_latawade-ai-edu-tablet/
│
├── melos.yaml                          # Melos monorepo configuration
├── pubspec.yaml                        # Root workspace definition
├── README.md                           # Project documentation
├── CLAUDE.md                           # AI-assistant instructions
│
├── eduforge_core/                      # 📦 SHARED CORE PACKAGE
│   └── lib/
│       ├── eduforge_core.dart          # Barrel export
│       ├── bloc/
│       │   ├── auth/
│       │   │   ├── auth_bloc.dart      # AuthBloc: sign in/up, logout, session restore
│       │   │   ├── auth_event.dart
│       │   │   └── auth_state.dart     # AuthInitial → AuthLoading → Authenticated / Unauthenticated / AuthError
│       │   └── profile/
│       │       ├── profile_bloc.dart   # ProfileBloc: load/update display name & roll number
│       │       ├── profile_event.dart
│       │       └── profile_state.dart
│       ├── cubit/
│       │   └── theme/
│       │       └── theme_cubit.dart    # ThemeCubit: light/dark toggle (HydratedBloc persisted)
│       ├── core/
│       │   ├── config/app_config.dart  # Runtime configuration
│       │   ├── constants/              # AI & sqlbase endpoint constants
│       │   ├── error/                  # AppException hierarchy, ErrorLogger
│       │   ├── network/retry_policy.dart # Exponential back-off wrapper
│       │   ├── observer/app_bloc_observer.dart # Global bloc lifecycle observer
│       │   ├── ui/responsive_layout.dart # Responsive layout helper
│       │   └── utils/input_sanitiser.dart # Lesson content sanitisation
│       ├── data/
│       │   └── repositories/
│       │       └── profile_repository.dart
│       └── features/
│           ├── auth/auth_screen.dart   # Tabbed login/sign-up, role-aware
│           └── profile/profile_screen.dart # Profile editor
│
├── admin_panel/                       # 🖥️ TEACHER APP (Windows)
│   └── lib/
│       ├── main.dart                   # App entry: HydratedBloc + sqlbase init + router
│       ├── app.dart                    # MultiBlocProvider root + MaterialApp.router
│       ├── core/
│       │   └── router/
│       │       └── app_router.dart     # GoRouter with AuthBloc-driven redirect
│       ├── bloc/
│       │   ├── ai_key/
│       │   │   ├── ai_key_bloc.dart    # Fetch/refresh teacher's Gemini API key from sqlbase
│       │   │   ├── ai_key_event.dart
│       │   │   └── ai_key_state.dart
│       │   ├── class/
│       │   │   ├── class_bloc.dart     # Create/fetch/delete classes
│       │   │   ├── class_event.dart
│       │   │   └── class_state.dart
│       │   ├── class_selection/
│       │   │   └── class_selection_cubit.dart # Currently selected class
│       │   ├── draft/
│       │   │   └── draft_cubit.dart    # Draft persistence (auto-save + restore)
│       │   ├── generation/
│       │   │   ├── generation_bloc.dart # Full lifecycle: generate → preview → publish
│       │   │   ├── generation_event.dart
│       │   │   └── generation_state.dart
│       │   └── quiz_results/
│       │       ├── quiz_results_bloc.dart  # Real-time quiz results via sqlbase subscription
│       │       ├── quiz_results_event.dart
│       │       └── quiz_results_state.dart
│       ├── models/
│       │   ├── class_model.dart
│       │   ├── generation_result.dart  # Mindmap, Flashcard, Infographic, TableData, Quiz models
│       │   └── student_model.dart
│       ├── data/
│       │   └── repositories/
│       │       ├── class_repository.dart
│       │       ├── material_repository.dart
│       │       ├── topic_repository.dart
│       │       └── quiz_repository.dart
│       ├── services/
│       │   └── ai_service.dart         # Gemini Flash 2.5 API client with retry logic
│       └── features/
│           ├── teacher/
│           │   ├── teacher_home_screen.dart  # My Classes dashboard
│           │   ├── class_roster_screen.dart  # Student roster per class
│           │   ├── topics_screen.dart        # Topic list per class
│           │   ├── new_topic_screen.dart     # Topic creation with paste/upload
│           │   ├── preview_screen.dart       # 5-tab preview + publish
│           │   ├── topic_results_screen.dart # Quiz results dashboard (Summary + Students)
│           │   └── widgets/
│           │       ├── mindmap_tab.dart
│           │       ├── flashcards_tab.dart
│           │       ├── infographic_tab.dart
│           │       ├── table_tab.dart
│           │       └── quiz_tab.dart
│           └── student/
│               └── student_home_screen.dart
│
├── student_tab/                       # 📱 STUDENT APP (Android Tablet)
│   └── lib/
│       ├── main.dart                   # App entry + NotesLocalDatabase init
│       ├── app.dart                    # MultiBlocProvider root + MaterialApp.router with custom theme
│       ├── core/
│       │   ├── router/
│       │   │   └── app_router.dart     # GoRouter: AuthBloc redirect + notes hierarchy routes
│       │   └── theme/
│       │       ├── app_colors.dart     # Canvas-specific color constants
│       │       └── app_theme.dart      # Light/dark theme definitions for tablet
│       ├── bloc/
│       │   ├── student/
│       │   │   ├── student_bloc.dart   # Join class, load joined classes
│       │   │   ├── student_event.dart
│       │   │   └── student_state.dart
│       │   ├── material_viewer/
│       │   │   └── material_viewer_cubit.dart # Fetch & cache all material types for a topic
│       │   ├── notes/
│       │   │   ├── notes_bloc.dart     # Notebook CRUD (subjects/chapters/topics)
│       │   │   ├── notes_event.dart
│       │   │   └── notes_state.dart
│       │   └── note_editor/
│       │       ├── note_editor_cubit.dart  # Stroke management, undo/redo, OCR, save
│       │       └── note_editor_state.dart
│       ├── data/
│       │   ├── local/
│       │   │   └── notes_local_database.dart  # Hive-backed local storage
│       │   ├── models/
│       │   │   ├── notebook.dart       # Notebook entity (Equatable)
│       │   │   ├── notebook_type.dart  # Subject / Chapter / Topic enum
│       │   │   ├── note_page.dart      # Page entity with strokes + pattern
│       │   │   ├── page_pattern.dart   # Ruled / Grid / Graph enum
│       │   │   └── stroke_data.dart    # StrokePoint + StrokeData (immutable, JSON serialisable)
│       │   ├── repositories/
│       │   │   ├── class_repository.dart
│       │   │   ├── material_repository.dart
│       │   │   ├── quiz_repository.dart
│       │   │   ├── notes_local_repository.dart  # Local Hive CRUD
│       │   │   └── notes_remote_repository.dart # sqlbase sync
│       │   └── services/
│       │       └── notes_sync_service.dart  # Background offline/online sync
│       ├── services/
│       │   └── ocr/
│       │       ├── ocr_engine.dart          # Abstract OCR interface
│       │       ├── ocr_service.dart         # Engine router with fallback logic
│       │       ├── ocr_preferences.dart     # User's engine choice + quota tracking
│       │       ├── ml_kit_engine.dart       # Google ML Kit text recognition
│       │       ├── gemini_engine.dart        # Gemini Flash cloud OCR
│       │       └── myscript_engine.dart      # MyScript iink integration
│       ├── widgets/
│       │   └── handwriting_canvas.dart # Full-featured canvas: layers, palm rejection, pan/zoom
│       └── features/
│           ├── student/
│           │   ├── join_class_screen.dart
│           │   ├── student_topic_list_screen.dart
│           │   ├── student_home_screen.dart
│           │   └── material_viewer_screen.dart  # 5-tab material viewer (Mindmap/Flashcards/Infographic/Table/Quiz)
│           ├── notes/
│           │   ├── hierarchy_list_screen.dart   # Navigable notebook tree
│           │   ├── notebook_detail_screen.dart  # Page grid with miniature preview
│           │   └── note_page_editor_screen.dart # Full editor with toolbar + canvas
│           ├── teacher/
│           │   └── teacher_home_screen.dart
│           └── settings/
│               └── settings_screen.dart     # OCR engine selector + quota display
│
├── sqlbase/
│   └── migrations/                    # 15 incremental SQL migrations
│       001_initial_schema.sql
│       002_security_hardening.sql
│       ...
│       015_quiz_attempts_unique.sql
│
├── interactive-ink-examples-android/  # Reference: MyScript Android SDK examples
│
└── graphify-out/                      # Project knowledge graph
    ├── GRAPH_REPORT.md
    └── wiki/
```

---

## 📦 Libraries & Dependencies

### Core Stack

| Library | Version | Purpose |
|---|---|---|
| **Flutter** | ≥3.10 | Cross-platform UI framework |
| **Dart** | ≥3.10 | Language with sound null safety, records, patterns |
| **flutter_bloc** | ^9.0.0 | State management — BLoC pattern (unidirectional data flow, testable, predictable) |
| **hydrated_bloc** | ^10.0.0 | Persists BLoC state to disk (theme preference survives restarts) |
| **go_router** | ^15.0.0 | Declarative, type-safe routing with auth redirect |
| **sqlbase_db** | ^2.9.0 | Backend-as-a-Service (PostgreSQL, Auth, Realtime, Row-Level Security) |
| **equatable** | ^2.0.7 | Value equality for Dart objects (avoids boilerplate `==` and `hashCode`) |
| **path_provider** | ^2.1.5 | Platform-appropriate storage paths (for HydratedBloc + Hive) |

### Teacher App (admin_panel)

| Library | Purpose |
|---|---|
| **http** | Gemini Flash 2.5 API calls |
| **file_picker** | `.txt` / `.pdf` file upload from teacher's computer |
| **syncfusion_flutter_pdf** | PDF text extraction for lesson content |
| **flutter_launcher_icons** | Windows launcher icon generation |

### Student App (student_tab)

| Library | Purpose |
|---|---|
| **hive** / **hive_flutter** | Local-first storage for notebooks and strokes (lightweight, fast, no SQL) |
| **google_mlkit_text_recognition** | On-device OCR (offline handwriting recognition) |
| **connectivity_plus** | Network availability detection for OCR fallback |
| **http** | Gemini Flash cloud OCR API calls |
| **flutter_launcher_icons** | Android adaptive icon generation |

### Shared (eduforge_core)

| Library | Purpose |
|---|---|
| **sqlbase_flutter** | Auth, database, RPCs, realtime subscriptions |
| **flutter_bloc** | Core BLoC setup for auth + profile |
| **hydrated_bloc** | Theme persistence across sessions |
| **go_router** | Shared auth-guard redirect logic |
| **equatable** | Model equality comparisons |
| **flutter_launcher_icons** | App icon assets |

---

## 🧠 Why This Architecture Is Used

### 1. Clean Separation of Concerns — Monorepo with Shared Core

```
eduforge_core  →  Shared Auth, Profile, Theme, Error Handling
      ↕                   ↕
admin_panel ────────── student_tab
(Teacher)              (Student)
```

**Why it wins:** Authentication, profile management, and theme logic are written **once** in `eduforge_core` and consumed by both apps. This eliminates code duplication, ensures consistent behaviour (e.g., both apps use the same session timeout, the same error hierarchy), and makes security audits tractable — you inspect one `auth_bloc.dart`, not two. New features that span both apps (e.g., push notifications, deep linking) are added in one place.

### 2. BLoC Pattern — Predictable, Testable, Traceable State

Unlike Riverpod's provider mesh or Redux's monolithic store, BLoC separates **events** (user actions) from **states** (UI data) with clear typing:

```dart
// One file = one state machine
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  on<AuthCheckStatus>((event, emit) => ...)
  on<AuthLoginRequested>((event, emit) => ...)
  on<AuthLogoutRequested>((event, emit) => ...)
}
```

**Why it wins:**
- **Unidirectional data flow** — UI dispatches `event`, BLoC computes `state`, UI rebuilds. No circular writes, no `setState` spaghetti.
- **Every transition is typed** — `Authenticated` and `AuthError` are distinct classes; the compiler catches you if you try to read `displayName` from an error state.
- **BlocObserver** — every event and state transition is logged globally; debugging production issues means replaying a log, not guessing.
- **Selective rebuilds** — `BlocBuilder` and `BlocListener` let widgets subscribe to only the states they need; no wasteful `build()` calls.

### 3. GoRouter — Auth-Guard at the Router Level, Not in Every Screen

```dart
redirect: (context, state) {
  if (authState is Unauthenticated) return '/auth';
  if (authState is Authenticated && authState.role == 'teacher') {
    if (location.startsWith('/student')) return '/teacher/classes';
  }
  return null;
}
```

**Why it wins:**
- **Single source of truth** for navigation rules — not scattered across `Navigator.push` checks in 20 screens.
- **Role-based routing** — a teacher who authenticates on the student tablet is redirected to the join screen, and vice versa.
- **Deep links work safely** — the redirect runs before any screen builds, so an unauthenticated user deep-linking to `/teacher/classes` ends up at `/auth`, not a blank screen.

### 4. sqlbase Backend — Firebase Alternative with Real PostgreSQL + RLS

| Concern | How sqlbase Handles It |
|---|---|
| **Auth** | Built-in (magic link, email/password, OAuth) |
| **Database** | Full PostgreSQL with migrations, views, functions |
| **Security** | Row-Level Security (RLS) — every query respects `auth.uid()` |
| **Realtime** | WebSocket subscriptions (live quiz results) |
| **Edge Functions** | Not needed here — Gemini key is served via `SECURITY DEFINER` RPC |

**Why it wins:** Unlike Firebase's NoSQL, which forces denormalised data that's hard to migrate, sqlbase gives you **real SQL** with 15 versioned migrations. The join code is a `UNIQUE` column, not a Firebase query that scales poorly. The quiz-attempt-once constraint is a database `UNIQUE(student_id, material_id)` — not application logic that can be bypassed. Row-Level Security means even a compromised client key cannot read another teacher's data.

### 5. Local-First Notes with Offline OCR

```
Hive (local) ← → NotesLocalRepository ← → NotesSyncService → sqlbase (cloud)
                              ↕
                    NoteEditorCubit (strokes, undo/redo)
                              ↕
                    HandwritingCanvas (CustomPaint layers)
```

**Why it wins:**
- **Zero-latency writes** — strokes go to Hive locally, then sync to sqlbase in the background. Students never wait for a network round-trip.
- **Works offline** — Hive is an embedded key-value store; no network, no problem. Sync catches up when connectivity returns.
- **Multiple OCR engines** — MyScript (best offline stroke recognition) → ML Kit (reliable fallback) → Gemini Cloud (highest accuracy). The `OcrService` routes to the best available engine transparently. Each engine is a separate class implementing `OcrEngine`, so adding a fourth engine means writing one file, touching nothing else.
- **Palm rejection** — the canvas is stylus-aware: once a stylus appears, all touch pointers are rejected as palm. No accidental strokes when the student rests their hand on the screen.

### 6. AI-Powered Content Generation in One Click

```
Teacher types/pastes text
         ↓
GenerationBloc dispatches GenerateContent
         ↓
AiService calls Gemini Flash 2.5 5× in parallel
  (mindmap, flashcards, infographic, table, quiz)
         ↓
All 5 results stored in sqlbase `materials` table
         ↓
Teacher previews in 5-tab UI → edits → publishes
```

**Why it wins:**
- **One click = five study tools** — the teacher doesn't design each format manually. The AI generates a complete study pack from raw lesson text.
- **Per-topic regeneration** — if the mindmap looks off, the teacher regenerates only the mindmap tab, keeping the other four intact.
- **Retry with exponential back-off** — `AiService` retries on 429 (rate limit) and 503 (overload) with 10s/5s/15s delays. A raw HTTP call would fail silently.
- **API key isolation** — the Gemini key never enters the client bundle; it's stored per-teacher in sqlbase and fetched via `SECURITY DEFINER` RPC. Even if the APK is decompiled, the key is safe.

### 7. Draft Resilience — Auto-Save, Never Lose Work

The `DraftCubit` saves the full `GenerationResult` (all 5 content types) to HydratedBloc storage every 10 seconds and on navigation. When the teacher returns to "New Topic," a prompt asks:

> "You have a saved draft. Resume or start fresh?"

**Why it wins:** Content generation takes 15–30 seconds for all 5 types. Losing that to an accidental back-navigation or app restart would be infuriating. The draft system turns a crash into a minor inconvenience.

### 8. Quiz System with Integrity Enforcement

| Mechanism | What it prevents |
|---|---|
| `UNIQUE(student_id, material_id)` | Student taking the same quiz twice |
| DB-level constraint (not app-level) | Cannot bypass by calling API directly |
| Submit confirmation dialog | Accidental submissions |
| `_QuizPhase` state machine | UI cannot show results before submission completes |
| Real-time results (teacher) | Teacher sees submissions as they happen via sqlbase subscription |

### 9. Responsive Layout Without Duplicate Code

```dart
ResponsiveLayout(
  compact: ListView.builder(...),
  medium: SingleChildScrollView(Wrap(...)),
)
```

The `ResponsiveLayout` utility from `eduforge_core` adapts to window size automatically — compact mode for small screens, medium layout for wide desktops. One widget, two layouts, no `MediaQuery` duplication across screens.

### 10. Testability by Design

Every BLoC, repository, and service is a class with a narrow interface:
- **AiService** takes API key + topic + content as constructor params — test with a mock HTTP client.
- **GenerationBloc** emits intermediate states (`StepProgress` with `step` + `progress` labels) — test the exact sequence of states without a widget tree.
- **NoteEditorCubit** accepts strokes and emits `strokes + canUndo + canRedo` — test undo/redo logic in pure Dart, no Flutter required.
- **OcrService** switches engines based on preferences — test each branch (preferred engine works, fails, falls back) with engine mocks.

---

## 🔐 Security Highlights

- **Row-Level Security** on every database table; all policies reference `auth.uid()`
- **Gemini API key** never in client bundle — served via `SECURITY DEFINER` RPC
- **Role changes blocked** at DB level by a trigger (`prevent_role_change`)
- **Input sanitisation** — `InputSanitiser.sanitiseAndTruncate()` prevents prompt injection in AI calls
- **Quiz one-attempt** enforced by DB `UNIQUE` constraint, not application logic
- **Soft delete** on classes — no data loss on accidental deletion

---

## 🚀 Getting Started

```bash
# Prerequisites
flutter SDK ≥ 3.10
dart pub global activate melos

# Install dependencies
melos bootstrap

```

---

*EduForge is built for the Kalpana AI Education Tablet — empowering teachers with AI-assisted content creation and students with interactive learning tools, digital handwriting, and offline-first note-taking.*