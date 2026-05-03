# Graph Report - e:/Windows Software/Tesarract/kalpana_latawade-ai-edu-tablet  (2026-05-03)

## Corpus Check
- 174 files · ~65,753 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 857 nodes · 961 edges · 50 communities detected
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 27 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Admin Panel BLoC State Management|Admin Panel BLoC State Management]]
- [[_COMMUNITY_Student Material Viewer UI|Student Material Viewer UI]]
- [[_COMMUNITY_Teacher Dashboard & Navigation|Teacher Dashboard & Navigation]]
- [[_COMMUNITY_Student App Shell|Student App Shell]]
- [[_COMMUNITY_AI Content Generation Pipeline|AI Content Generation Pipeline]]
- [[_COMMUNITY_Quiz & Topic Results Analytics|Quiz & Topic Results Analytics]]
- [[_COMMUNITY_Windows Desktop Platform Layer|Windows Desktop Platform Layer]]
- [[_COMMUNITY_Admin Panel Routing|Admin Panel Routing]]
- [[_COMMUNITY_Authentication & Profile|Authentication & Profile]]
- [[_COMMUNITY_Flutter Windows Codec Layer|Flutter Windows Codec Layer]]
- [[_COMMUNITY_Content Preview & Autosave|Content Preview & Autosave]]
- [[_COMMUNITY_Topics Management Screen|Topics Management Screen]]
- [[_COMMUNITY_Flutter Windows Plugin Registry|Flutter Windows Plugin Registry]]
- [[_COMMUNITY_Error Logging & Reporting|Error Logging & Reporting]]
- [[_COMMUNITY_Infographic Content Tab|Infographic Content Tab]]
- [[_COMMUNITY_Mind Map Content Tab|Mind Map Content Tab]]
- [[_COMMUNITY_Quiz Content Tab|Quiz Content Tab]]
- [[_COMMUNITY_Windows Build Configuration|Windows Build Configuration]]
- [[_COMMUNITY_Class Roster Management|Class Roster Management]]
- [[_COMMUNITY_Table Content Tab|Table Content Tab]]
- [[_COMMUNITY_AI Generation Result Models|AI Generation Result Models]]
- [[_COMMUNITY_Generation BLoC States|Generation BLoC States]]
- [[_COMMUNITY_Flutter Engine C++ Wrapper|Flutter Engine C++ Wrapper]]
- [[_COMMUNITY_App Exception Hierarchy|App Exception Hierarchy]]
- [[_COMMUNITY_App Branding & Icons|App Branding & Icons]]
- [[_COMMUNITY_Quiz Results BLoC States|Quiz Results BLoC States]]
- [[_COMMUNITY_EduForge Brand Identity|EduForge Brand Identity]]
- [[_COMMUNITY_AI Key BLoC States|AI Key BLoC States]]
- [[_COMMUNITY_Class BLoC States|Class BLoC States]]
- [[_COMMUNITY_Generation BLoC Events|Generation BLoC Events]]
- [[_COMMUNITY_Flutter Plugin Registrar C++|Flutter Plugin Registrar C++]]
- [[_COMMUNITY_Auth BLoC States|Auth BLoC States]]
- [[_COMMUNITY_Profile BLoC States|Profile BLoC States]]
- [[_COMMUNITY_Quiz Results BLoC Events|Quiz Results BLoC Events]]
- [[_COMMUNITY_Windows Runner Entry Point|Windows Runner Entry Point]]
- [[_COMMUNITY_Auth BLoC Events|Auth BLoC Events]]
- [[_COMMUNITY_Network Retry Policy|Network Retry Policy]]
- [[_COMMUNITY_Student BLoC States|Student BLoC States]]
- [[_COMMUNITY_Study Material Models|Study Material Models]]
- [[_COMMUNITY_Class BLoC Events|Class BLoC Events]]
- [[_COMMUNITY_Input Sanitisation Utility|Input Sanitisation Utility]]
- [[_COMMUNITY_Widget Test Suite|Widget Test Suite]]
- [[_COMMUNITY_Shared Lint Configuration|Shared Lint Configuration]]
- [[_COMMUNITY_AI Key BLoC Events|AI Key BLoC Events]]
- [[_COMMUNITY_Profile BLoC Events|Profile BLoC Events]]
- [[_COMMUNITY_Student BLoC Events|Student BLoC Events]]
- [[_COMMUNITY_Android Plugin Registrant|Android Plugin Registrant]]
- [[_COMMUNITY_App Configuration|App Configuration]]
- [[_COMMUNITY_Supabase Constants|Supabase Constants]]
- [[_COMMUNITY_Android Main Activity|Android Main Activity]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter_bloc/flutter_bloc.dart` - 26 edges
2. `package:flutter/material.dart` - 25 edges
3. `package:eduforge_core/eduforge_core.dart` - 25 edges
4. `package:supabase_flutter/supabase_flutter.dart` - 24 edges
5. `../models/generation_result.dart` - 14 edges
6. `package:go_router/go_router.dart` - 11 edges
7. `package:equatable/equatable.dart` - 10 edges
8. `WriteValue()` - 8 edges
9. `Admin Panel Windows Runner CMakeLists` - 7 edges
10. `EduForge Logo` - 7 edges

## Surprising Connections (you probably didn't know these)
- `Admin Panel Analysis Options` --semantically_similar_to--> `EduForge Core Analysis Options`  [INFERRED] [semantically similar]
  admin_panel/analysis_options.yaml → eduforge_core/analysis_options.yaml
- `Admin Panel Analysis Options` --semantically_similar_to--> `Student Tab Analysis Options`  [INFERRED] [semantically similar]
  admin_panel/analysis_options.yaml → student_tab/analysis_options.yaml
- `EduForge Core Analysis Options` --semantically_similar_to--> `Student Tab Analysis Options`  [INFERRED] [semantically similar]
  eduforge_core/analysis_options.yaml → student_tab/analysis_options.yaml
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  admin_panel\windows\runner\flutter_window.cpp → admin_panel\windows\flutter\generated_plugin_registrant.cc
- `Resize()` --calls--> `ResizeChannel()`  [INFERRED]
  admin_panel\windows\flutter\ephemeral\cpp_client_wrapper\include\flutter\method_channel.h → admin_panel\windows\flutter\ephemeral\cpp_client_wrapper\core_implementations.cc

## Hyperedges (group relationships)
- **Shared Flutter Lint Configuration Across Packages** — admin_panel_analysis_options, eduforge_core_analysis_options, student_tab_analysis_options, flutter_lints_flutter_yaml [EXTRACTED 1.00]
- **Admin Panel Windows CMake Build Pipeline** — admin_panel_windows_cmake, admin_panel_windows_flutter_cmake, admin_panel_windows_runner_cmake, flutter_assemble_target, flutter_library_windows, flutter_wrapper_app, flutter_wrapper_plugin, admin_panel_binary [EXTRACTED 1.00]
- **EduForge Multi-Package Flutter Project (admin_panel, eduforge_core, student_tab)** — admin_panel_binary, eduforge_core_analysis_options, student_tab_web_index, eduforge_platform [INFERRED 0.80]

## Communities

### Community 0 - "Admin Panel BLoC State Management"
Cohesion: 0.02
Nodes (94): app.dart, ../../core/error/app_exception.dart, ../../core/error/error_logger.dart, ../../core/network/retry_policy.dart, core/router/app_router.dart, dart:math, ../../data/repositories/class_repository.dart, ../../data/repositories/material_repository.dart (+86 more)

### Community 1 - "Student Material Viewer UI"
Cohesion: 0.04
Nodes (56): _answerRow, build, _buildForm, _buildResults, Card, _CardFace, Center, Column (+48 more)

### Community 2 - "Teacher Dashboard & Navigation"
Cohesion: 0.04
Nodes (47): ../../bloc/ai_key/ai_key_bloc.dart, ../../bloc/class/class_bloc.dart, ../../bloc/class_selection/class_selection_cubit.dart, ../../bloc/draft/draft_cubit.dart, ../../bloc/generation/generation_bloc.dart, dart:io, build, EduForgeApp (+39 more)

### Community 3 - "Student App Shell"
Cohesion: 0.05
Nodes (35): ../../bloc/student/student_bloc.dart, build, EduForgeApp, MultiBlocProvider, AlertDialog, build, _buildBody, Card (+27 more)

### Community 4 - "AI Content Generation Pipeline"
Cohesion: 0.06
Nodes (29): dart:convert, clearDraft, copyWith, DraftCubit, DraftState, fromJson, matchesClass, saveDraft (+21 more)

### Community 5 - "Quiz & Topic Results Analytics"
Cohesion: 0.06
Nodes (31): _avgColor, build, Card, _Cell, Center, dispose, Divider, _formatDate (+23 more)

### Community 6 - "Windows Desktop Platform Layer"
Cohesion: 0.11
Nodes (20): RegisterPlugins(), Generated Plugin Registrant (generated_plugin_registrant.cc), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea() (+12 more)

### Community 7 - "Admin Panel Routing"
Cohesion: 0.07
Nodes (26): ../../bloc/material_viewer/material_viewer_cubit.dart, ../../bloc/quiz_results/quiz_results_bloc.dart, dart:async, createRouter, dispose, GoRouter, _RouterNotifier, build (+18 more)

### Community 8 - "Authentication & Profile"
Cohesion: 0.08
Nodes (23): ../../bloc/auth/auth_bloc.dart, ../../bloc/profile/profile_bloc.dart, AuthScreen, _AuthScreenState, build, Center, dispose, initState (+15 more)

### Community 9 - "Flutter Windows Codec Layer"
Cohesion: 0.15
Nodes (18): DecodeAndProcessResponseEnvelopeInternal(), DecodeMessageInternal(), DecodeMethodCallInternal(), EncodedTypeForValue(), EncodeErrorEnvelopeInternal(), EncodeMessageInternal(), EncodeMethodCallInternal(), EncodeSuccessEnvelopeInternal() (+10 more)

### Community 10 - "Content Preview & Autosave"
Cohesion: 0.09
Nodes (22): _autoSave, build, Column, dispose, _initFromSuccess, initState, _label, Padding (+14 more)

### Community 11 - "Topics Management Screen"
Cohesion: 0.11
Nodes (18): build, _buildDraftTab, _buildPublishedTab, Card, Center, dispose, Exception, _formatDate (+10 more)

### Community 12 - "Flutter Windows Plugin Registry"
Cohesion: 0.12
Nodes (4): ResizeChannel(), SetChannelWarnsOnOverflow(), Resize(), SetWarnsOnOverflow()

### Community 13 - "Error Logging & Reporting"
Cohesion: 0.12
Nodes (15): dart:developer, addReporter, _currentUserId, ErrorLogger, _format, logError, logWarning, report (+7 more)

### Community 14 - "Infographic Content Tab"
Cohesion: 0.12
Nodes (15): AlertDialog, build, Card, Center, didUpdateWidget, dispose, _edit, _EditSectionDialog (+7 more)

### Community 15 - "Mind Map Content Tab"
Cohesion: 0.12
Nodes (15): build, Center, _collectEdges, Container, _Edge, _EdgePainter, InteractiveViewer, _layout (+7 more)

### Community 16 - "Quiz Content Tab"
Cohesion: 0.13
Nodes (14): AlertDialog, build, Card, Center, didUpdateWidget, dispose, Divider, _edit (+6 more)

### Community 17 - "Windows Build Configuration"
Cohesion: 0.23
Nodes (14): Admin Panel Windows Executable (admin_panel), Admin Panel Windows CMakeLists, Admin Panel Windows Flutter CMakeLists, Admin Panel Windows Runner CMakeLists, Windows DWM API Library (dwmapi.lib), EduForge AI-Powered Education Platform, Flutter Assemble Custom Build Target, Flutter Bootstrap Script (flutter_bootstrap.js) (+6 more)

### Community 18 - "Class Roster Management"
Cohesion: 0.17
Nodes (11): build, Center, ClassRosterScreen, _ClassRosterScreenState, _formatDate, Icon, initState, ListTile (+3 more)

### Community 19 - "Table Content Tab"
Cohesion: 0.17
Nodes (11): build, Center, Container, didUpdateWidget, dispose, _init, initState, _notifyChanged (+3 more)

### Community 20 - "AI Generation Result Models"
Cohesion: 0.18
Nodes (10): copyWith, Flashcard, GenerationResult, Infographic, InfographicSection, Mindmap, MindmapNode, Quiz (+2 more)

### Community 21 - "Generation BLoC States"
Cohesion: 0.2
Nodes (9): GenerationFailure, GenerationInitial, GenerationLoading, GenerationState, GenerationSuccess, PublishFailure, PublishLoading, PublishSuccess (+1 more)

### Community 22 - "Flutter Engine C++ Wrapper"
Cohesion: 0.22
Nodes (2): FlutterEngine(), ShutDown()

### Community 23 - "App Exception Hierarchy"
Cohesion: 0.2
Nodes (9): AppException, AuthException, DatabaseException, NetworkException, NotFoundException, PermissionException, RateLimitException, toString (+1 more)

### Community 24 - "App Branding & Icons"
Cohesion: 0.33
Nodes (10): Education App Brand Identity (Graduate + Book + Feather + Circular Arc), Flutter Default Blue Diamond Icon, Web Favicon (Education App), Flutter Default Launcher Icon (Android HDPI mipmap), Education App Launcher Foreground Icon (Android HDPI), PWA Web Icon 192x192 (Education Logo), PWA Web Icon 512x512 (Education Logo), PWA Maskable Web Icon 192x192 (Education Logo) (+2 more)

### Community 25 - "Quiz Results BLoC States"
Cohesion: 0.22
Nodes (8): copyWith, QuizResultsError, QuizResultsInitial, QuizResultsLoaded, QuizResultsLoading, QuizResultsState, StudentResult, WrongAnswer

### Community 26 - "EduForge Brand Identity"
Cohesion: 0.43
Nodes (8): Brand Color Palette (Teal, Blue, Orange), Education Platform Brand Identity, Circular Backdrop with Gradient, EduForge Logo, Graduation Cap (Mortarboard), Graduate Student Silhouette, Leaf/Feather Motif, Open Book Symbol

### Community 27 - "AI Key BLoC States"
Cohesion: 0.29
Nodes (6): AiKeyError, AiKeyExpired, AiKeyInitial, AiKeyLoaded, AiKeyLoading, AiKeyState

### Community 28 - "Class BLoC States"
Cohesion: 0.29
Nodes (6): ClassError, ClassesLoaded, ClassInitial, ClassLoading, ClassOperationSuccess, ClassState

### Community 29 - "Generation BLoC Events"
Cohesion: 0.29
Nodes (6): GenerateStudyPack, GenerationEvent, PublishTopic, RegenerateMaterial, ResetGeneration, RestoreResult

### Community 30 - "Flutter Plugin Registrar C++"
Cohesion: 0.38
Nodes (4): ClearPlugins(), GetInstance(), OnRegistrarDestroyed(), PluginRegistrar()

### Community 31 - "Auth BLoC States"
Cohesion: 0.29
Nodes (6): Authenticated, AuthError, AuthInitial, AuthLoading, AuthState, Unauthenticated

### Community 32 - "Profile BLoC States"
Cohesion: 0.29
Nodes (6): ProfileError, ProfileInitial, ProfileLoaded, ProfileLoading, ProfileState, ProfileUpdateSuccess

### Community 33 - "Quiz Results BLoC Events"
Cohesion: 0.33
Nodes (5): LoadMoreResults, LoadQuizResults, QuizResultsEvent, RealtimeAttemptReceived, RefreshQuizResults

### Community 34 - "Windows Runner Entry Point"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 35 - "Auth BLoC Events"
Cohesion: 0.33
Nodes (5): AuthCheckStatus, AuthEvent, AuthLoginRequested, AuthLogoutRequested, AuthSignUpRequested

### Community 36 - "Network Retry Policy"
Cohesion: 0.33
Nodes (5): _defaultShouldRetry, fn, Function, RetryPolicy, ../error/app_exception.dart

### Community 37 - "Student BLoC States"
Cohesion: 0.33
Nodes (5): StudentClassesLoaded, StudentError, StudentInitial, StudentLoading, StudentState

### Community 38 - "Study Material Models"
Cohesion: 0.33
Nodes (5): Flashcard, InfographicSection, MindmapNode, QuizQuestion, TableData

### Community 39 - "Class BLoC Events"
Cohesion: 0.4
Nodes (4): ClassEvent, CreateClass, DeleteClass, FetchClasses

### Community 41 - "Input Sanitisation Utility"
Cohesion: 0.4
Nodes (4): InputSanitiser, sanitise, sanitiseAndTruncate, truncate

### Community 42 - "Widget Test Suite"
Cohesion: 0.4
Nodes (3): main, main, package:flutter_test/flutter_test.dart

### Community 43 - "Shared Lint Configuration"
Cohesion: 0.9
Nodes (5): Admin Panel Analysis Options, EduForge Core Analysis Options, flutter_lints/flutter.yaml Lint Base Config, Shared Dart/Flutter Lint Ruleset, Student Tab Analysis Options

### Community 44 - "AI Key BLoC Events"
Cohesion: 0.5
Nodes (3): AiKeyEvent, FetchAiKey, RefreshAiKey

### Community 45 - "Profile BLoC Events"
Cohesion: 0.5
Nodes (3): LoadProfile, ProfileEvent, UpdateProfile

### Community 46 - "Student BLoC Events"
Cohesion: 0.5
Nodes (3): JoinClassWithCode, LoadJoinedClasses, StudentEvent

### Community 47 - "Android Plugin Registrant"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 74 - "App Configuration"
Cohesion: 1.0
Nodes (1): AppConfig

### Community 75 - "Supabase Constants"
Cohesion: 1.0
Nodes (1): SupabaseConstants

### Community 76 - "Android Main Activity"
Cohesion: 1.0
Nodes (1): MainActivity

## Knowledge Gaps
- **550 isolated node(s):** `EduForgeApp`, `build`, `MultiBlocProvider`, `main`, `AiKeyBloc` (+545 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Flutter Engine C++ Wrapper`** (10 nodes): `flutter_engine.cc`, `FlutterEngine()`, `GetRegistrarForPlugin()`, `ProcessExternalWindowMessage()`, `ProcessMessages()`, `RelinquishEngine()`, `ReloadSystemFonts()`, `Run()`, `SetNextFrameCallback()`, `ShutDown()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Plugin Registrant`** (3 nodes): `GeneratedPluginRegistrant`, `.registerWith()`, `GeneratedPluginRegistrant.java`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Configuration`** (2 nodes): `AppConfig`, `app_config.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Supabase Constants`** (2 nodes): `SupabaseConstants`, `supabase_constants.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Android Main Activity`** (2 nodes): `MainActivity`, `MainActivity.kt`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Admin Panel BLoC State Management` to `Student Material Viewer UI`, `Teacher Dashboard & Navigation`, `Student App Shell`, `AI Content Generation Pipeline`, `Quiz & Topic Results Analytics`, `Authentication & Profile`, `Content Preview & Autosave`, `Topics Management Screen`, `Infographic Content Tab`, `Mind Map Content Tab`, `Quiz Content Tab`, `Class Roster Management`, `Table Content Tab`?**
  _High betweenness centrality (0.129) - this node is a cross-community bridge._
- **Why does `package:flutter_bloc/flutter_bloc.dart` connect `Admin Panel BLoC State Management` to `Student Material Viewer UI`, `Teacher Dashboard & Navigation`, `Student App Shell`, `Quiz & Topic Results Analytics`, `Admin Panel Routing`, `Authentication & Profile`, `Content Preview & Autosave`, `Topics Management Screen`, `Error Logging & Reporting`?**
  _High betweenness centrality (0.089) - this node is a cross-community bridge._
- **Why does `package:supabase_flutter/supabase_flutter.dart` connect `Admin Panel BLoC State Management` to `Student Material Viewer UI`, `Student App Shell`, `AI Content Generation Pipeline`, `Content Preview & Autosave`, `Topics Management Screen`, `Error Logging & Reporting`, `Class Roster Management`?**
  _High betweenness centrality (0.060) - this node is a cross-community bridge._
- **What connects `EduForgeApp`, `build`, `MultiBlocProvider` to the rest of the system?**
  _550 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Admin Panel BLoC State Management` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Student Material Viewer UI` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Teacher Dashboard & Navigation` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._