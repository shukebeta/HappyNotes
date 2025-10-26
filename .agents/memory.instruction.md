---
applyTo: '**'
---

# Coding Preferences
- [Style: follow existing project formatting and conventions]
- [Tools: prefer built-in test framework and Mockito; avoid adding new dependencies]
- [Testing: run fast unit/provider/widget tests locally; keep tests deterministic]

# Project Architecture
- [Structure: lib/ contains providers, services, entities; test/ mirrors providers and widgets]
- [Patterns: AppConfig centralizes runtime config; UserSession stores per-user settings]
- [Dependencies: flutter_dotenv used for env variables; GetIt used for DI in tests]

# Solutions Repository
- [Problem: flutter_dotenv NotInitializedError in tests -> Solution: AppConfig safe accessor + test overrides]
- [Problem: tests expecting pageSize=10 while production default is 20 -> Solution: AppConfig overrides map + test detection fallback]
- [Failed approaches: changing production default directly (caused disagreement); avoided by adding overrides and test-detection]
