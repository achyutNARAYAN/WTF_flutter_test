# AI Ledger

| # | Tool | Intent | Output / Use | Commit |
|---|------|--------|--------------|--------|
| 1 | Codex | Diagnose initial Flutter/Dart errors | Found shorthand syntax and loose `shared` analyzer issues. | pending |
| 2 | Codex | Fix package resolution | Added `shared/pubspec.yaml` and `wtf_shared` local dependency. | pending |
| 3 | Codex | Debug Guru imports | Converted broken feature-folder imports to package imports. | pending |
| 4 | Codex | Debug Riverpod 3 API | Replaced `valueOrNull` with `value`. | pending |
| 5 | Codex | Debug 100ms listener | Renamed callback fields to avoid `HMSUpdateListener` method conflicts. | pending |
| 6 | Codex | Refactor shared services | Added local server sync with in-memory fallback. | pending |
| 7 | Codex | Generate assessment docs | Created README, ARCHITECTURE, DECISIONS, and server README. | pending |
| 8 | Codex | Implement Trainer app | Replaced template counter app with trainer CRM/chat/request/session UI. | pending |
| 9 | Codex | Add token server | Created dependency-free Node HTTP server for tokens and local sync. | pending |
| 10 | Codex | Verification | Ran `dart analyze` across app/package contexts and documented Flutter wrapper timeout. | pending |

## Debugging Notes

### Broken imports

Analyzer output showed `Target of URI doesn't exist: '../../../../shared/...'`. I used Codex to normalize the app to a local package dependency (`wtf_shared`) so both apps resolve the same shared API.

### 100ms listener conflicts

Analyzer output showed fields named `onJoin`, `onReconnecting`, and `onReconnected` conflicting with `HMSUpdateListener` methods. I used Codex to rename callback fields to private names and keep the public constructor API readable.

### Flutter wrapper timeout

`flutter test` timed out in this shell while direct `dart analyze` succeeded. I kept verification through the Dart SDK analyzer and documented the wrapper issue.
