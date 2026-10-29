---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests sind Pflicht für alles Messbare, auch wenn die Spec sie nicht ausdrücklich verlangt
und der Skill `speckit-tasks` sie optional nennt (Verfassung, Grundsatz VI).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [Besitzer] [P?] [Story] Description`

- **[Besitzer]**: `[K]` Klaus, `[A]` Godot-Agent, `[C]` Claude; steht direkt nach der Nummer, auch
  wenn der Skill `speckit-tasks` ein Format ohne Besitzer nennt (Verfassung, Grundsatz III)
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /speckit-tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/

  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment

  DO NOT keep these sample tasks in the generated tasks.md file.

  Ausnahme: Die deutschen Aufgaben mit `[C]` oder `[A]` in dieser Vorlage (Godot-Doku,
  Phasenprüfung, Bestandsprüfung, Selbsttest, Spielbeschreibung) sind keine Beispiele. Sie kommen
  in jede tasks.md, mit echter Nummer.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] TXXX [C] Godot-Doku im Arbeitsordner bereitlegen, immer die erste Aufgabe: Fehlt
  `godot_referenz/`, `tools/godot_referenz/erzeuge.sh --texte --handbuch` laufen lassen
  (`docs/ki_workflow/ki_dev.md`, „Werkzeuge und Pfade“)
- [ ] T001 [A] Create project structure per implementation plan
- [ ] T002 [A] Initialize [language] project with [framework] dependencies
- [ ] T003 [A] [P] Configure linting and formatting tools

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on your project):

- [ ] T004 [A] Setup database schema and migrations framework
- [ ] T005 [A] [P] Implement authentication/authorization framework
- [ ] T006 [A] [P] Setup API routing and middleware structure
- [ ] T007 [A] Create base models/entities that all stories depend on
- [ ] T008 [A] Configure error handling and logging infrastructure
- [ ] T009 [A] Setup environment configuration management

- [ ] TXXX [C] Phasenprüfung Phase 2 mit `/dcl-phasenpruefung`, nur wenn die Phase Sichtbares,
  Texte oder Code ändert, mit den Prüfern aus `plan.md`, „Prüfer je Phase“; vor Klaus' Abnahme
  (`docs/ki_workflow/ki_pruefung.md`)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T010 [A] [P] [US1] Contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T011 [A] [P] [US1] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 1

- [ ] T012 [A] [P] [US1] Create [Entity1] model in src/models/[entity1].py
- [ ] T013 [A] [P] [US1] Create [Entity2] model in src/models/[entity2].py
- [ ] T014 [A] [US1] Implement [Service] in src/services/[service].py (depends on T012, T013)
- [ ] T015 [A] [US1] Implement [endpoint/feature] in src/[location]/[file].py
- [ ] T016 [A] [US1] Add validation and error handling
- [ ] T017 [A] [US1] Add logging for user story 1 operations

- [ ] TXXX [C] Phasenprüfung Phase 3 mit `/dcl-phasenpruefung`, nur wenn die Phase Sichtbares,
  Texte oder Code ändert, mit den Prüfern aus `plan.md`, „Prüfer je Phase“; vor Klaus' Abnahme
  (`docs/ki_workflow/ki_pruefung.md`)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 ⚠️

- [ ] T018 [A] [P] [US2] Contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T019 [A] [P] [US2] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 2

- [ ] T020 [A] [P] [US2] Create [Entity] model in src/models/[entity].py
- [ ] T021 [A] [US2] Implement [Service] in src/services/[service].py
- [ ] T022 [A] [US2] Implement [endpoint/feature] in src/[location]/[file].py
- [ ] T023 [A] [US2] Integrate with User Story 1 components (if needed)

- [ ] TXXX [C] Phasenprüfung Phase 4 mit `/dcl-phasenpruefung`, nur wenn die Phase Sichtbares,
  Texte oder Code ändert, mit den Prüfern aus `plan.md`, „Prüfer je Phase“; vor Klaus' Abnahme
  (`docs/ki_workflow/ki_pruefung.md`)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3 ⚠️

- [ ] T024 [A] [P] [US3] Contract test for [endpoint] in tests/contract/test_[name].py
- [ ] T025 [A] [P] [US3] Integration test for [user journey] in tests/integration/test_[name].py

### Implementation for User Story 3

- [ ] T026 [A] [P] [US3] Create [Entity] model in src/models/[entity].py
- [ ] T027 [A] [US3] Implement [Service] in src/services/[service].py
- [ ] T028 [A] [US3] Implement [endpoint/feature] in src/[location]/[file].py

- [ ] TXXX [C] Phasenprüfung Phase 5 mit `/dcl-phasenpruefung`, nur wenn die Phase Sichtbares,
  Texte oder Code ändert, mit den Prüfern aus `plan.md`, „Prüfer je Phase“; vor Klaus' Abnahme
  (`docs/ki_workflow/ki_pruefung.md`)

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [A] [P] Documentation updates in docs/
- [ ] TXXX [A] Code cleanup and refactoring
- [ ] TXXX [A] Performance optimization across all stories
- [ ] TXXX [A] [P] Additional unit tests in tests/unit/
- [ ] TXXX [A] Security hardening
- [ ] TXXX [A] Run quickstart.md validation
- [ ] TXXX [C] Bestandsprüfung mit dem Architektur-Prüfer über ganz `src/`, nur wenn mit diesem
  Feature eine neue Schicht beginnt, etwa Wirtschaft oder Adventure, oder seine Nummer auf 3 oder 8
  endet (jedes fünfte Feature nach 008: 013, 018, …); vor der Lückensuche
  (`docs/ki_workflow/ki_pruefung.md`)
- [ ] TXXX [C] Phasenprüfung dieser Phase mit `/dcl-phasenpruefung`, nur wenn sie Sichtbares, Texte
  oder Code ändert, mit den Prüfern aus `plan.md`, „Prüfer je Phase“; vor der Gesamtabnahme
  (`docs/ki_workflow/ki_pruefung.md`)
- [ ] TXXX [A] Selbsttest-Abläufe anpassen (vor der Gesamtabnahme; `docs/ki_workflow/ki_dev.md`,
  Punkt 11): neue oder geänderte Seiten, Wege, Texte und Eingaben bekommen Schritte in
  `src/tools/selbsttest/ablaeufe/`; entfällt, wenn das Feature nichts davon ändert.
- [ ] TXXX [C] Selbsttest zur Gesamtabnahme: `tools/build/baue_alles.sh`, Lauf auf dem Mac,
  `tools/selbsttest/vergleich.py`; Ergebnis in der Bitte um Gesamtabnahme; neue Referenzbilder nur
  nach Klaus' Abnahme.
- [ ] TXXX [C] Spielbeschreibung prüfen (immer die letzte Aufgabe des Features, nach der
  Gesamtabnahme und vor dem Merge; `docs/ki_workflow/ki_dev.md`, „Ablauf je Feature“): Claude
  gleicht `docs/spielbeschreibung/` mit dem Code ab und legt Klaus eine Liste vor, welche Dateien
  veralten und welche neu angelegt werden sollten, mit Grund. Abweichungen zwischen Spec und Code
  gehören dazu. Geändert wird erst nach Klaus' OK.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - Nacheinander in Prioritätsreihenfolge (P1 → P2 → P3), jede Phase einzeln von Klaus freigegeben
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Contract test for [endpoint] in tests/contract/test_[name].py"
Task: "Integration test for [user journey] in tests/integration/test_[name].py"

# Launch all models for User Story 1 together:
Task: "Create [Entity1] model in src/models/[entity1].py"
Task: "Create [Entity2] model in src/models/[entity2].py"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Abnahme durch Klaus, dann Commit der Phase

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Abnahme, Commit (MVP!)
3. Add User Story 2 → Test independently → Abnahme, Commit
4. Add User Story 3 → Test independently → Abnahme, Commit
5. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Claude committet einmal je von Klaus abgenommener Phase, nie je Aufgabe
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
