# app/

Flutter app (Android first, iOS later from the same code). It will be scaffolded with `flutter create` once the Flutter SDK is installed.

Planned structure (see docs/PLAN.md §6):

```
lib/core/      theme, router, db (drift), sync, mastery engine, content_packs,
               subjects registry, question_types registry (model + renderer + input + grader per type)
lib/features/  onboarding, diagnostic, today, workout, skill_map, concept_detail, tests, paywall, parent_report, profile, auth
lib/shared/    widgets
```

The question-type ids and payload shapes must match `content/pipeline/types/`, which is the source of truth for the question schema.
