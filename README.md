# EduForge – AI-Powered Education Platform

EduForge is a Flutter monorepo that delivers an AI-assisted classroom in two apps:

- **Admin Panel** — Windows desktop app for teachers
- **Student Tab** — Android tablet app for students

A shared Dart package (`eduforge_core`) carries authentication, profile management, and theme logic used by both apps. The backend is Supabase (PostgreSQL + Auth + Realtime).

---

## Repository Layout

```
kalpana_latawade-ai-edu-tablet/
├── admin_panel/          # Teacher app (Windows)
├── student_tab/          # Student app (Android)
├── eduforge_core/        # Shared BLoCs, screens, repositories
├── supabase/
│   └── migrations/       # 15 incremental SQL migrations
├── melos.yaml            # Monorepo task runner
└── pubspec.yaml          # Workspace root
```

The workspace is managed with [Melos](https://melos.invertase.dev/). All three packages share a single `pub` resolution, so dependency versions are consistent.

---

## Apps

### Admin Panel (Teacher – Windows)

Teachers use this desktop app to:

1. **Manage classes** — create a class, share its 6-character join code with students
2. **Build topics** — give a topic a title and paste source text
3. **Generate study material with AI** — one click calls the Gemini API and produces five content types simultaneously:
   - Mind map
   - Flashcard deck
   - Infographic (section-based visual summary)
   - Comparison table
   - Multiple-choice quiz (with explanations for each answer)
4. **Preview and publish** — review generated content in tabbed preview before making it visible to students
5. **Monitor results** — real-time quiz results screen shows each student's score, roll number, and which answers were wrong
6. **Profile** — edit display name; role is read-only

The Gemini API key is stored per-teacher in Supabase and fetched via an RPC; it never travels through the client bundle.

### Student Tab (Student – Android)

Students use this tablet app to:

1. **Join a class** — tap the FAB, enter the teacher's 6-character code; the FAB hides once a class is joined
2. **Browse topics** — see all published topics in their class
3. **Study materials** — each topic opens a tabbed viewer:
   - **Mindmap** — zoomable/scrollable node graph
   - **Flashcards** — flip cards for active recall
   - **Infographic** — visual section-by-section summary
   - **Table** — structured comparison grid
   - **Quiz** — multiple-choice with progress bar; one attempt only (no retakes)
4. **Quiz results** — after submitting, see score, percentage, and expandable wrong-answer cards with correct answer and explanation
5. **Profile** — edit display name and roll number

---

## Shared Core (`eduforge_core`)

| Area | What it provides |
|---|---|
| `AuthBloc` | Sign-in, sign-up (with display name + optional roll number), logout, session restore |
| `ProfileBloc` | Load and update display name / roll number |
| `ThemeCubit` | Persisted light/dark toggle (HydratedBloc) |
| `AuthScreen` | Tabbed login/sign-up widget, role-aware (shows roll-number field for students) |
| `ProfileScreen` | Editable name + roll number; role badge (read-only) |
| `RetryPolicy` | Wraps every Supabase call with exponential back-off |
| `AppException` hierarchy | `DatabaseException`, `NetworkException`, `AuthException` |
| `ErrorLogger` | Centralised logging (BlocObserver + repository layer) |

---

## Database (Supabase)

### Core Tables

| Table | Purpose |
|---|---|
| `profiles` | One row per user — `display_name`, `role` (`teacher`/`student`), `roll_number`, `email` |
| `classes` | Teacher-owned classes with `join_code` (6-char unique) and soft-delete |
| `class_memberships` | Many-to-many: which student is in which class |
| `topics` | Teacher-authored topics, `published` flag gates student visibility |
| `materials` | One row per content type per topic (`type`: mindmap/flashcards/infographic/table/quiz), JSON payload in `json_data` |
| `quiz_attempts` | One row per student per material — `UNIQUE(student_id, material_id)` enforces no retakes |

### Security

- **Row-Level Security** on every table; all policies reference `auth.uid()`
- `INSERT` on `profiles` restricted to the owning user
- Teachers can read profiles of their class members (needed for embedded joins in quiz results)
- Role changes blocked at the DB level by a trigger (`prevent_role_change`)
- `get_gemini_key` RPC executes as `SECURITY DEFINER` — the key column is never readable via normal select

### RPCs

| RPC | Purpose |
|---|---|
| `join_class(p_code)` | Validates join code, inserts membership, returns class name |
| `publish_topic(p_topic_id)` | Sets `published = true`; verifies caller owns the topic |
| `get_gemini_key()` | Returns the caller's stored Gemini API key |

### Migrations

```
001  initial schema + RLS
002  security hardening
003  fix role trigger
004  fix RLS recursion
005  topics and materials tables
006  get_gemini_key RPC
007  recreate quiz_attempts
008  student join RPC
009  quiz attempts tracking
010  RLS audit assertions
011  rate limiting
012  soft delete + indexes
013  publish_topic RPC
014  profiles.roll_number + teacher-read policy + backfill
015  UNIQUE(student_id, material_id) on quiz_attempts
```

---

## State Management

All state is managed with the BLoC pattern (`flutter_bloc`). Theme state is persisted across launches via `hydrated_bloc` + `path_provider`.

```
AuthBloc          — auth events → Authenticated / Unauthenticated / AuthError
ProfileBloc       — LoadProfile / UpdateProfile → ProfileLoaded / ProfileUpdateSuccess
ThemeCubit        — toggleTheme → ThemeState (hydrated)
ClassBloc         — teacher class CRUD
GenerationBloc    — AI generation pipeline (per content type)
QuizResultsBloc   — realtime subscription to quiz_attempts
StudentBloc       — join class, load joined classes
MaterialViewerCubit — fetch and parse all material types for a topic
```

---

## Navigation

Both apps use `GoRouter` with an `AuthBloc`-driven redirect:

- Unauthenticated → `/auth`
- Authenticated teacher → `/teacher/classes`
- Authenticated student → `/student/join`

Student app additional routes: `/student/classes/:classId/topics`, `/student/material/:topicId`, `/profile`.

---

## AI Content Generation Flow

```
Teacher types topic title + source text
        │
        ▼
GenerationBloc dispatches GenerateContent
        │
        ▼
AiService calls Gemini API  ──►  returns structured JSON
        │                        (mindmap / flashcards / infographic / table / quiz)
        ▼
admin_panel stores JSON in `materials` table (one row per type)
        │
        ▼
Teacher previews in tabbed UI → clicks Publish
        │
        ▼
publish_topic RPC sets topics.published = true
        │
        ▼
Students see topic in their class → open tabs to study
```

---

## Branding & Packaging

| Property | Value |
|---|---|
| App name | EduForge |
| Company | iMAlpha |
| Android package | `inc.imalpha.eduforge` |
| Windows display name | EduForge (set in `main.cpp` + `Runner.rc`) |
| Launcher icon | `eduforge_core/assets/logo.jpg` — generated via `flutter_launcher_icons` |

Icons are generated by running:

```bash
cd admin_panel  && dart run flutter_launcher_icons   # Windows .ico
cd student_tab  && dart run flutter_launcher_icons   # Android adaptive icons
```

---

## Development Setup

### Prerequisites

- Flutter SDK ≥ 3.10 / Dart ≥ 3.10
- Melos: `dart pub global activate melos`
- A Supabase project with all 15 migrations applied

### Install dependencies

```bash
melos bootstrap
```

### Run

```bash
# Teacher app (Windows)
melos run admin

# Student app (Android device/emulator)
melos run student
```

### Analyze & format

```bash
melos run analyze
melos run format
```

### Apply DB migrations

Run each file in `supabase/migrations/` in order in the Supabase SQL editor, or via the Supabase CLI:

```bash
supabase db push
```

### Environment

Create a `.env` (or configure via Supabase dashboard) with:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

These are passed into `AppConfig` at startup in each app's `main.dart`.
